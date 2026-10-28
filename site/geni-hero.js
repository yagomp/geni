/* Geni in the landing hero: walks in beside the phone (desktop), waves hello (tablet) or pops up in front
   of the phone's corner (phone), then idles; a tap makes him cheer.
   Clips live in media/geni/<clip>.{mov,webm} (HEVC + alpha for Safari, VP9 + alpha elsewhere), 720 px,
   and every clip starts on the pose the previous one ends on. Two stacked videos take turns: the next
   clip waits paused on its first frame, so a hand-off never shows an empty frame. */
(function () {
  'use strict';

  var hero = document.getElementById('hero');
  var box = document.getElementById('geni');
  if (!hero || !box || !('IntersectionObserver' in window)) return;

  var phone = hero.querySelector('.iphone-mockup');
  var visual = hero.querySelector('.hero-visual');
  var copy = hero.querySelectorAll('h1, .lead, .cta-row');
  var button = box.querySelector('button');
  var vids = box.querySelectorAll('video');
  var A = vids[0], B = vids[1];
  var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Foot-locked travel, in clip pixels (720 per side) at 30 fps: walk.* is a 1.6 s loop whose planted
  // foot slides 7.74 px a frame; arrive.* keeps sliding for 16 frames while it slows to a stop.
  var WALK_LOOP = 1.6, STEP = 7.74, BRAKE = 16;

  var mode, size = 0, left = 0, cur = null, state = '', visible = false, loaded = false;
  // Only idle Geni takes taps; while he walks past the CTA, clicks go through to the buttons.
  function setState(s) { state = s; box.classList.toggle('can-tap', s === 'idle'); }
  var loops = 0, lastTime = 0, walkLoops = 0;

  function modeNow() { return window.innerWidth > 1024 ? 'walk' : window.innerWidth > 600 ? 'hello' : 'peek'; }

  // Does Geni's widest pose (clip x 105–576, head top 122, feet 712) touch the headline, lead or CTA?
  // `right` is where clip x 545 (his body's right side) lands.
  function hitsCopy(s, right, base) {
    var u = s / 720, l = right - 440 * u, t = base - 590 * u, r = right + 31 * u;
    for (var i = 0; i < copy.length; i++) {
      var range = document.createRange();
      range.selectNodeContents(copy[i]);
      var rects = copy[i].classList.contains('cta-row') ? [copy[i].getBoundingClientRect()] : range.getClientRects();
      for (var j = 0; j < rects.length; j++) {
        var q = rects[j];
        if (q.right > l - 8 && q.left < r && q.bottom > t - 8 && q.top < base) return true;
      }
    }
    return false;
  }

  function place() {
    var h = hero.getBoundingClientRect(), p = phone.getBoundingClientRect(), u, top;
    mode = modeNow();
    box.classList.toggle('geni--peek', mode === 'peek');
    if (mode === 'peek') {
      // Cropped phone: in front of its lower-left corner, below the game and left of its banner; the
      // hero's faded bottom edge hides the lower 35 % of the clip (peek starts fully below it).
      var v = visual.getBoundingClientRect();
      size = Math.round(v.width * 0.75); u = size / 720;
      left = v.left - h.left + v.width * 0.085 - 541 * u;
      top = v.bottom - h.top - 470 * u;
      box.style.height = Math.round(470 * u) + 'px';
    } else {
      // Feet on the hero's baseline, body in front of the phone's left bezel (a head tilt reaches into
      // the empty strip of screen between the game and its banner); as big as the copy allows.
      // (Where the hero runs past the first screen, he stands on the screen's bottom edge instead.)
      var base = Math.min(h.bottom - 4, p.bottom + p.height * 0.1, window.innerHeight - 4 - window.scrollY);
      var right = p.left + p.width * 0.05;
      size = Math.min(p.height * 0.58, 460);
      while (size > 160 && hitsCopy(size, right, base)) size -= 8;
      size = Math.round(size); u = size / 720;
      left = right - h.left - 545 * u;
      top = base - h.top - 712 * u;
      box.style.height = size + 'px';
    }
    box.style.setProperty('--s', size + 'px');
    box.style.left = Math.round(left) + 'px';
    box.style.top = Math.round(top) + 'px';
  }

  function stage(v, clip) {
    if (v.getAttribute('data-clip') !== clip) {
      var s = v.querySelectorAll('source');
      s[0].src = 'media/geni/' + clip + '.mov';
      s[1].src = 'media/geni/' + clip + '.webm';
      v.setAttribute('data-clip', clip);
      v.preload = 'auto';
      v.load();
    } else {
      v.pause();
      v.currentTime = 0;
    }
    return new Promise(function (resolve) {
      (function check() {
        if (v.readyState >= 2 && !v.seeking) resolve(v);
        else if (!v.error) setTimeout(check, 30);
      }());
    });
  }

  function play(v) {
    if (!visible || document.hidden) return;
    var p = v.play();
    if (p) p.catch(function (e) { if (e.name === 'NotAllowedError') toStill(); });
  }

  // Runs cb with the media time of each frame v presents (per animation frame where unsupported).
  function onFrame(v, cb) {
    if (v.requestVideoFrameCallback) v.requestVideoFrameCallback(function (now, m) { cb(m.mediaTime); });
    else requestAnimationFrame(function () { cb(v.currentTime); });
  }

  // Put v on top and start it; the old video is hidden once v shows frames, then after() may restage it.
  function show(v, loop, after) {
    var old = cur;
    cur = v;
    v.loop = !!loop;
    v.style.zIndex = 2;
    if (old) old.style.zIndex = 1;
    v.classList.add('on');
    play(v);
    onFrame(v, function () {
      if (!old || old === cur) return;
      old.classList.remove('on');
      old.pause();
      if (after) after(old);
    });
  }

  function other(v) { return v === A ? B : A; }

  function idle(v) {
    setState('idle');
    show(v, true, function (old) { stage(old, 'cheer'); });
  }

  // Desktop walk: the page moves him exactly as far as his planted foot slides back, frame by frame.
  // He starts off-screen a whole number of loops before the stop, so the walk ends on frame 0, where
  // arrive.* begins; arrive then brakes over 16 frames: x = v·f − v·f²/32.
  function stepPx() { return STEP * size / 720; }
  function walkStart() {
    var loopPx = stepPx() * 30 * WALK_LOOP, brake = stepPx() * BRAKE / 2;
    walkLoops = Math.max(1, Math.ceil((left - brake + 540 * size / 720) / loopPx));
    return left - brake - walkLoops * loopPx;
  }
  function setX(x) { box.style.transform = mode === 'walk' ? 'translateX(' + (x - left).toFixed(2) + 'px)' : ''; }
  function walkStep(t) {
    if (state !== 'walk') return;
    if (t + 0.4 < lastTime) loops++;
    lastTime = t;
    if (loops >= walkLoops - 1) A.loop = false;
    setX(walkStart() + stepPx() * 30 * (loops * WALK_LOOP + t));
    onFrame(A, walkStep);
  }
  function brakeStep(t) {
    if (state !== 'arrive') return;
    var f = Math.min(t * 30, BRAKE), v = stepPx();
    setX(left - v * BRAKE / 2 + v * f - v * f * f / (2 * BRAKE));
    if (f < BRAKE) onFrame(B, brakeStep);
  }

  function start() {
    setState('loading');
    place();
    var first = mode === 'walk' ? 'walk' : mode;
    Promise.all([stage(A, first), stage(B, mode === 'walk' ? 'arrive' : 'idle')]).then(function () {
      if (first === 'walk') {
        setState('walk');
        setX(walkStart());
        box.hidden = false;
        show(A, true);
        onFrame(A, walkStep);
        A.onended = function () {
          A.onended = null;
          setState('arrive');
          brakeStep(0);
          show(B, false, function () { stage(A, 'idle'); });
          onFrame(B, brakeStep);
          B.onended = function () { B.onended = null; setX(left); idle(A); };
        };
      } else {
        box.hidden = false;
        setState('intro');
        show(A);
        A.onended = function () { A.onended = null; idle(B); };
      }
    });
  }

  function toStill() {
    setState('still');
    box.style.transform = '';
    box.classList.add('is-still');
    button.hidden = true;
    [A, B].forEach(function (v) { v.pause(); v.classList.remove('on'); });
    place();
    box.hidden = false;
  }

  button.addEventListener('click', function () {
    if (state !== 'idle') return;
    setState('cheer');
    var idleV = cur, cheerV = other(cur), t0 = idleV.currentTime;
    // Idle passes the neutral pose (cheer's first frame) at 0 s and 2.2 s. Fast-forward to the next one
    // (at most 0.6 s) and cut there, so the cheer never jumps.
    var now = Math.abs(t0 - 2.2) < 0.15 || t0 < 0.15 || t0 > 3.85;
    var idleReady = new Promise(function (resolve) {
      (function wait() {
        var t = idleV.currentTime;
        if (now || (t0 < 2.2 ? t >= 2.18 : t < t0)) {
          idleV.playbackRate = 1;
          show(cheerV, false, function () { stage(idleV, 'idle').then(resolve); });
        } else requestAnimationFrame(wait);
      }());
    });
    if (!now) idleV.playbackRate = 3;
    cheerV.onended = function () {
      cheerV.onended = null;
      idleReady.then(function () { idle(idleV); });
    };
  });

  new IntersectionObserver(function (entries) {
    visible = entries[0].isIntersecting;
    if (!loaded) return;
    if (!visible) { if (cur) cur.pause(); } else if (!state) start(); else if (cur && state !== 'still') play(cur);
  }, { threshold: 0.25 }).observe(visual);

  document.addEventListener('visibilitychange', function () {
    if (!cur || state === 'still') return;
    if (document.hidden) cur.pause(); else play(cur);
  });

  if ('ResizeObserver' in window) {
    new ResizeObserver(function () { if (state && state !== 'walk' && state !== 'arrive') place(); }).observe(hero);
  }

  function ready() {
    loaded = true;
    if (still) toStill();
    else if (visible) start();
  }
  if (document.readyState === 'complete') ready();
  else window.addEventListener('load', ready);
}());
