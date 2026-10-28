import Foundation

/// Recorded Google voices, made by `scripts/voice/record.mjs` into ios/Geni/Voice/. Reading texts are whole
/// clips with word timings. Questions are recorded in pieces split at their numbers and joined when spoken,
/// so every sum needs only its phrases and numbers. Anything not recorded returns nil and the device voice reads it.
nonisolated enum VoiceLibrary {
    struct Clip: Sendable {
        let url: URL
        /// Start of each space-separated word in milliseconds; empty for question pieces.
        let wordStartsMs: [Int]
    }

    struct Piece: Hashable, Sendable {
        /// Lowercased letters and digits only, so capitalisation and punctuation don't matter.
        let key: String
        /// What gets recorded: the piece as written, without leading punctuation.
        let text: String
    }

    private struct Entry: Decodable {
        let file: String
        let words: [Int]?
    }

    private static let manifest: [String: [String: Entry]] = {
        guard let url = Bundle.main.url(forResource: "voice", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: [String: Entry]].self, from: data)) ?? [:]
    }()

    /// The clips to play in order for `text`, or nil if any part of it isn't recorded in `language`.
    static func clips(for text: String, language: String) -> [Clip]? {
        guard let entries = manifest[language] else { return nil }
        if let whole = entries[key(text)] {
            return clip(whole).map { [$0] }
        }
        let parts = pieces(of: text)
        guard !parts.isEmpty else { return nil }
        var clips: [Clip] = []
        for part in parts {
            guard let entry = entries[part.key], let clip = clip(entry) else { return nil }
            clips.append(clip)
        }
        return clips
    }

    static func key(_ text: String) -> String {
        String(text.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " })
            .split(separator: " ")
            .joined(separator: " ")
    }

    /// "9 plus 5 is 13. True or false?" → 9 · plus · 5 · is · 13 · True or false?
    static func pieces(of text: String) -> [Piece] {
        var runs: [String] = []
        var current = ""
        var currentIsNumber = false
        for character in text {
            let isNumber = character.isNumber
            if !current.isEmpty && isNumber != currentIsNumber {
                runs.append(current)
                current = ""
            }
            current.append(character)
            currentIsNumber = isNumber
        }
        runs.append(current)

        let leading = CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".,;:!?"))
        return runs.compactMap { run in
            var spoken = Substring(run)
            while let first = spoken.unicodeScalars.first, leading.contains(first) { spoken = spoken.dropFirst() }
            let trimmed = spoken.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ",;:")))
            let key = key(trimmed)
            return key.isEmpty ? nil : Piece(key: key, text: trimmed)
        }
    }

    private static func clip(_ entry: Entry) -> Clip? {
        let name = (entry.file as NSString).deletingPathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a")
                ?? Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "Voice") else { return nil }
        return Clip(url: url, wordStartsMs: entry.words ?? [])
    }
}
