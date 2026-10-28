#!/usr/bin/env node
// Records everything Geni says out loud with Google Cloud Text-to-Speech, into ios/Geni/Voice/.
//
//   1. Export what the app speaks (reading texts + question pieces, split by VoiceLibrary.pieces):
//      TEST_RUNNER_GENI_VOICE_CATALOG=/tmp/geni-voice-catalog.json scripts/geni-build.sh test GeniTests/VoiceCatalogTests
//   2. node scripts/voice/record.mjs [/tmp/geni-voice-catalog.json] [--dry]
//
// Records only what is missing or changed (file names hash text, voice, rate and FORMAT), removes clips nothing
// uses any more, and writes ios/Geni/Voice/voice.json, which VoiceLibrary.swift reads.
//
// Reading texts are recorded one sentence at a time (Chirp 3 HD gives no word timings), trimmed, levelled and
// joined with fixed pauses, so sentence times are exact; word times inside a sentence are spread by word length.
// Question pieces ("What is", "plus", "7", "True or false?") are recorded alone and joined by the app.
//
// Sign-in: the Google service account shared with Statsprøven, ~/.config/statsproven/gsc-service-account.json
// (or GOOGLE_TTS_SERVICE_ACCOUNT). The key is never printed. Needs macOS (afconvert does the AAC encoding).
import { execFileSync } from "node:child_process"
import crypto from "node:crypto"
import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { fileURLToPath } from "node:url"

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..")
const OUT = path.join(REPO, "ios/Geni/Voice")
const MANIFEST = path.join(OUT, "voice.json")
const SA_FILE = process.env.GOOGLE_TTS_SERVICE_ACCOUNT ?? path.join(os.homedir(), ".config/statsproven/gsc-service-account.json")

/** Bump when the audio processing changes, so every clip is recorded again. */
const FORMAT = 1
const SAMPLE_RATE = 24000
const BITRATE = 32000
const CONCURRENCY = 3
/** Chirp 3 HD has a low per-minute request quota; stay under it and wait longer when Google still says 429. */
const REQUESTS_PER_MINUTE = 60

/** One voice per language. Portugal has no Chirp 3 HD voice, so it uses WaveNet. */
const VOICES = {
  "en-US": "en-US-Chirp3-HD-Sulafat",
  "nb-NO": "nb-NO-Chirp3-HD-Sulafat",
  "es-ES": "es-ES-Chirp3-HD-Sulafat",
  "pt-PT": "pt-PT-Wavenet-E",
}
/** Younger readers hear slower reading with longer pauses between sentences. */
const READING = {
  young: { rate: 0.9, gap: 0.6 },
  middle: { rate: 0.95, gap: 0.5 },
  older: { rate: 1.0, gap: 0.45 },
}
const PIECE = { rate: 0.95, pad: 0.06 }
/** Pieces Chirp won't say on their own, spelled so it pronounces them the same. */
const SAY_AS = { "nb-NO": { er: "ær" } }
const SENTENCE_PAD = 0.04

const args = process.argv.slice(2)
const dry = args.includes("--dry")
const catalogPath = args.find((arg) => !arg.startsWith("--")) ?? "/tmp/geni-voice-catalog.json"
const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"))

let token
async function accessToken() {
  const sa = JSON.parse(fs.readFileSync(SA_FILE, "utf8"))
  const now = Math.floor(Date.now() / 1000)
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url")
  const claims = { iss: sa.client_email, scope: "https://www.googleapis.com/auth/cloud-platform", aud: sa.token_uri, iat: now, exp: now + 3600 }
  const unsigned = `${b64({ alg: "RS256", typ: "JWT" })}.${b64(claims)}`
  const signature = crypto.sign("RSA-SHA256", Buffer.from(unsigned), sa.private_key).toString("base64url")
  const response = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: `${unsigned}.${signature}` }),
  })
  const json = await response.json()
  if (!json.access_token) throw new Error(`Google sign-in failed (${response.status})`)
  return json.access_token
}

let nextRequestAt = 0
async function throttle() {
  const wait = nextRequestAt - Date.now()
  nextRequestAt = Math.max(Date.now(), nextRequestAt) + 60000 / REQUESTS_PER_MINUTE
  if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait))
}

/** 16-bit mono PCM at SAMPLE_RATE. */
async function synthesize(lang, text, rate) {
  for (let attempt = 1; ; attempt++) {
    await throttle()
    let response
    try {
      response = await fetch("https://texttospeech.googleapis.com/v1/text:synthesize", {
        method: "POST",
        headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
        body: JSON.stringify({
          input: { text },
          voice: { languageCode: lang, name: VOICES[lang] },
          audioConfig: { audioEncoding: "LINEAR16", sampleRateHertz: SAMPLE_RATE, speakingRate: rate },
        }),
      })
    } catch (error) {
      if (attempt >= 6) throw error
      await new Promise((resolve) => setTimeout(resolve, 5000 * attempt))
      continue
    }
    const json = await response.json()
    if (response.ok && json.audioContent) return pcmFromWav(Buffer.from(json.audioContent, "base64"))
    if (attempt < 6 && (response.status === 429 || response.status >= 500)) {
      await new Promise((resolve) => setTimeout(resolve, 20000 * attempt))
      continue
    }
    throw new Error(`Google TTS ${response.status}: ${json.error?.message ?? "unknown error"} (${lang}: ${text.slice(0, 40)})`)
  }
}

function pcmFromWav(buffer) {
  let offset = 12
  while (offset + 8 <= buffer.length) {
    const id = buffer.toString("ascii", offset, offset + 4)
    const size = buffer.readUInt32LE(offset + 4)
    if (id === "data") return new Int16Array(buffer.buffer.slice(buffer.byteOffset + offset + 8, buffer.byteOffset + offset + 8 + size))
    offset += 8 + size + (size % 2)
  }
  throw new Error("No audio data in Google's response")
}

/** Cuts the silence Google adds around speech. */
function trim(pcm) {
  const threshold = 500
  const window = Math.round(SAMPLE_RATE * 0.01)
  const loud = (i) => {
    for (let j = i; j < Math.min(i + window, pcm.length); j++) if (Math.abs(pcm[j]) > threshold) return true
    return false
  }
  let start = 0
  while (start < pcm.length && !loud(start)) start += window
  let end = pcm.length
  while (end > start && !loud(Math.max(start, end - window))) end -= window
  return pcm.subarray(Math.max(0, start - window), Math.min(pcm.length, end + window))
}

/**
 * Chirp sometimes answers a very short text with silence or a clipped word. Retry until the trimmed speech is
 * loud enough and long enough for its letters, keeping the longest attempt.
 */
async function speech(lang, text, rate) {
  const letters = text.match(/[\p{L}\p{N}]/gu)?.length ?? 1
  const minimum = Math.max(0.15, 0.035 * letters)
  let best = new Int16Array(0)
  for (let attempt = 1; attempt <= 5; attempt++) {
    const pcm = trim(await synthesize(lang, text, rate))
    let peak = 0
    for (const sample of pcm) peak = Math.max(peak, Math.abs(sample))
    if (peak > 4000 && pcm.length > best.length) best = pcm
    if (best.length / SAMPLE_RATE >= minimum) return best
  }
  throw new Error(`No usable speech for ${lang}: ${text}`)
}

const silence = (seconds) => new Int16Array(Math.round(seconds * SAMPLE_RATE))

function concat(parts) {
  const out = new Int16Array(parts.reduce((sum, part) => sum + part.length, 0))
  let offset = 0
  for (const part of parts) {
    out.set(part, offset)
    offset += part.length
  }
  return out
}

/** Same loudness for every clip, so joined pieces and different voices match: speech RMS −20 dBFS, peaks below −1 dBFS. */
function level(pcm) {
  let sum = 0
  let count = 0
  let peak = 1
  for (const sample of pcm) {
    const value = Math.abs(sample)
    peak = Math.max(peak, value)
    if (value > 500) {
      sum += sample * sample
      count++
    }
  }
  if (!count) return pcm
  const gain = Math.min((0.1 * 32767) / Math.sqrt(sum / count), (0.89 * 32767) / peak)
  return pcm.map((sample) => Math.max(-32768, Math.min(32767, Math.round(sample * gain))))
}

function wav(pcm) {
  const data = Buffer.from(pcm.buffer, pcm.byteOffset, pcm.byteLength)
  const header = Buffer.alloc(44)
  header.write("RIFF", 0)
  header.writeUInt32LE(36 + data.length, 4)
  header.write("WAVE", 8)
  header.write("fmt ", 12)
  header.writeUInt32LE(16, 16)
  header.writeUInt16LE(1, 20)
  header.writeUInt16LE(1, 22)
  header.writeUInt32LE(SAMPLE_RATE, 24)
  header.writeUInt32LE(SAMPLE_RATE * 2, 28)
  header.writeUInt16LE(2, 32)
  header.writeUInt16LE(16, 34)
  header.write("data", 36)
  header.writeUInt32LE(data.length, 40)
  return Buffer.concat([header, data])
}

function encode(pcm, file) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "geni-voice-"))
  try {
    fs.writeFileSync(path.join(temp, "clip.wav"), wav(pcm))
    execFileSync("afconvert", ["-f", "m4af", "-d", "aac", "-b", String(BITRATE), "-c", "1", path.join(temp, "clip.wav"), file])
  } finally {
    fs.rmSync(temp, { recursive: true, force: true })
  }
}

/** Words exactly as the app splits them (ReadingContentService.parseWords: single spaces). */
const words = (text) => text.split(" ").filter(Boolean)

/** Sentences as runs of words; a sentence ends at . ! ? or …, also inside closing quotes. */
function sentences(text) {
  const out = []
  let current = []
  for (const word of words(text)) {
    current.push(word)
    if (/[.!?…][»”"’)]*$/.test(word)) {
      out.push(current)
      current = []
    }
  }
  if (current.length) out.push(current)
  return out
}

/** Within a sentence, longer words take longer, and commas add a short pause after their word. */
function wordStarts(sentenceWords, startSeconds, seconds) {
  const weights = sentenceWords.map((word) => (word.match(/[\p{L}\p{N}]/gu)?.length ?? 0) + 2)
  const pauses = sentenceWords.map((word) => (/[,;:—–][»”"’]*$/.test(word) ? 3 : 0))
  const total = weights.reduce((a, b) => a + b, 0) + pauses.reduce((a, b) => a + b, 0) - pauses.at(-1)
  let elapsed = 0
  return sentenceWords.map((_, i) => {
    const start = startSeconds + (seconds * elapsed) / total
    elapsed += weights[i] + pauses[i]
    return Math.round(start * 1000)
  })
}

async function recordReading(item) {
  const { rate, gap } = READING[item.age]
  const parts = []
  const starts = []
  let at = 0
  for (const [index, sentence] of sentences(item.text).entries()) {
    if (index > 0) {
      parts.push(silence(gap))
      at += gap
    }
    const spoken = await speech(item.lang, sentence.join(" "), rate)
    const seconds = spoken.length / SAMPLE_RATE
    parts.push(silence(SENTENCE_PAD), spoken, silence(SENTENCE_PAD))
    starts.push(...wordStarts(sentence, at + SENTENCE_PAD + 0.02, seconds - 0.04))
    at += seconds + 2 * SENTENCE_PAD
  }
  encode(level(concat(parts)), path.join(OUT, item.file))
  return starts
}

async function recordPiece(item) {
  const spoken = await speech(item.lang, SAY_AS[item.lang]?.[item.text] ?? item.text, PIECE.rate)
  encode(level(concat([silence(PIECE.pad), spoken, silence(PIECE.pad)])), path.join(OUT, item.file))
}

function fileName(lang, text, rate) {
  const hash = crypto.createHash("sha256").update(JSON.stringify([FORMAT, VOICES[lang], rate, text])).digest("hex")
  return `voice-${lang.toLowerCase()}-${hash.slice(0, 12)}.m4a`
}

async function pool(items, worker) {
  let next = 0
  let done = 0
  await Promise.all(Array.from({ length: CONCURRENCY }, async () => {
    while (next < items.length) {
      const item = items[next++]
      await worker(item)
      done++
      if (done % 25 === 0 || done === items.length) process.stdout.write(`  ${done}/${items.length}\n`)
    }
  }))
}

const reading = catalog.reading.map((item) => ({ ...item, kind: "reading", file: fileName(item.lang, item.text, READING[item.age].rate) }))
const pieces = catalog.pieces.map((item) => ({ ...item, kind: "piece", file: fileName(item.lang, SAY_AS[item.lang]?.[item.text] ?? item.text, PIECE.rate) }))
const all = [...reading, ...pieces]
for (const item of all) if (!VOICES[item.lang]) throw new Error(`No voice for ${item.lang}`)

const previous = fs.existsSync(MANIFEST) ? JSON.parse(fs.readFileSync(MANIFEST, "utf8")) : {}
const previousWords = new Map(Object.values(previous).flatMap((entries) => Object.values(entries)).filter((e) => e.words).map((e) => [e.file, e.words]))
const exists = (item) => fs.existsSync(path.join(OUT, item.file)) && (item.kind === "piece" || previousWords.has(item.file))
const missing = all.filter((item) => !exists(item))
const characters = missing.reduce((sum, item) => sum + item.text.length, 0)
console.log(`${all.length} clips (${reading.length} reading, ${pieces.length} pieces); ${missing.length} to record, ${characters} characters.`)
if (dry) process.exit(0)

fs.mkdirSync(OUT, { recursive: true })
token = await accessToken()
const recordedWords = new Map()

/** Lists every clip that is on disk, so a run that stops halfway keeps what it recorded. */
function writeManifest() {
  const manifest = {}
  for (const item of all) {
    const words = recordedWords.get(item.file) ?? previousWords.get(item.file)
    if (!fs.existsSync(path.join(OUT, item.file)) || (item.kind === "reading" && !words)) continue
    ;(manifest[item.lang] ??= {})[item.key] = item.kind === "reading" ? { file: item.file, words } : { file: item.file }
  }
  const sorted = Object.fromEntries(Object.keys(manifest).sort().map((lang) => [lang, Object.fromEntries(Object.keys(manifest[lang]).sort().map((key) => [key, manifest[lang][key]]))]))
  fs.writeFileSync(MANIFEST, `${JSON.stringify(sorted, null, 1)}\n`)
}

try {
  await pool(missing, async (item) => {
    if (item.kind === "reading") recordedWords.set(item.file, await recordReading(item))
    else await recordPiece(item)
  })
} finally {
  writeManifest()
}

const used = new Set(all.map((item) => item.file))
const orphans = fs.readdirSync(OUT).filter((file) => file.endsWith(".m4a") && !used.has(file))
for (const file of orphans) fs.rmSync(path.join(OUT, file))
const bytes = [...used].reduce((sum, file) => sum + fs.statSync(path.join(OUT, file)).size, 0)
console.log(`Done: ${used.size} clips, ${(bytes / 1024 / 1024).toFixed(1)} MB, removed ${orphans.length} unused.`)
