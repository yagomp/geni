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
  var cta = hero.querySelector('.cta-row');
  var button = box.querySelector('button');
  var vids = box.querySelectorAll('video');
  var A = vids[0], B = vids[1];
  var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // walk.* is two 1 s step cycles in place; at 1.4x, three loops take 4.3 s.
  var WALK_RATE = 1.4, WALK_LOOPS = 3, WALK_LEN = 2;
  // Stance foot travel per second of clip, as a share of the clip width (measured from the frames).
  var STRIDE = 46.5 / 720;

  var mode, size = 0, left = 0, cur = null, state = '', visible = false, loaded = false;
  var loops = 0, lastTime = 0;

  function modeNow() { return window.innerWidth > 1024 ? 'walk' : window.innerWidth > 600 ? 'hello' : 'peek'; }

  // Geometry in clip pixels (720 per side): body x 180–545, head top ~130, feet at 712.
  function place() {
    var h = hero.getBoundingClientRect(), p = phone.getBoundingClientRect(), u, top;
    mode = modeNow();
    box.classList.toggle('geni--peek', mode === 'peek');
    if (mode === 'peek') {
      // Cropped phone: in front of its lower-left corner, below the game; the hero's faded bottom edge
      // hides the lower 35 % of the clip (peek starts fully below it).
      var v = visual.getBoundingClientRect();
      size = Math.round(v.width * 0.66); u = size / 720;
      left = v.left - h.left + v.width * 0.07 - 541 * u;
      top = v.bottom - h.top - 470 * u;
      box.style.height = Math.round(470 * u) + 'px';
    } else {
      // Feet on the hero's baseline, body just overlapping the phone's left bezel.
      var base = Math.min(h.bottom - 4, p.bottom + p.height * 0.1);
      size = Math.min(p.height * 0.36, 260);
      // The walk passes under the call-to-action row: keep his head below it.
      if (mode === 'walk') size = Math.min(size, (base - cta.getBoundingClientRect().bottom - 12) / 0.83);
      size = Math.round(Math.max(size, 130)); u = size / 720;
      left = p.left - h.left + p.width * 0.04 - 545 * u;
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

  // Put v on top and start it; the old video is hidden once v shows frames, then after() may restage it.
  function show(v, rate, loop, after) {
    var old = cur;
    cur = v;
    v.playbackRate = rate || 1;
    v.loop = !!loop;
    v.style.zIndex = 2;
    if (old) old.style.zIndex = 1;
    v.classList.add('on');
    play(v);
    function hide() {
      if (!old || old === cur) return;
      old.classList.remove('on');
      old.pause();
      if (after) after(old);
    }
    if (v.requestVideoFrameCallback) v.requestVideoFrameCallback(function () { hide(); });
    else v.addEventListener('playing', function () { requestAnimationFrame(hide); }, { once: true });
  }

  function other(v) { return v === A ? B : A; }

  function idle(v) {
    state = 'idle';
    show(v, 1, true, function (old) { stage(old, 'cheer'); });
  }

  // Desktop walk: ease from full speed to the stride speed, timed by the clip so the two never drift.
  function walkStep() {
    if (state !== 'walk') return;
    var t = A.currentTime;
    if (t + 0.5 < lastTime) loops++;
    lastTime = t;
    if (loops >= WALK_LOOPS - 1) A.loop = false;
    var p = Math.min((loops * WALK_LEN + t) / (WALK_LOOPS * WALK_LEN), 1);
    var d = left + size + 16;
    var v1 = STRIDE * size * WALK_LOOPS * WALK_LEN; // px per unit of p at the stride speed
    var k = Math.min(v1 / (2 * d - v1), 1);
    var x = mode === 'walk' ? -d + d * (2 * p + (k - 1) * p * p) / (1 + k) : 0;
    box.style.transform = 'translateX(' + x.toFixed(1) + 'px)';
    requestAnimationFrame(walkStep);
  }

  function start() {
    state = 'loading';
    place();
    var first = mode === 'walk' ? 'walk' : mode;
    Promise.all([stage(A, first), stage(B, mode === 'walk' ? 'arrive' : 'idle')]).then(function () {
      box.hidden = false;
      if (first === 'walk') {
        state = 'walk';
        box.style.transform = 'translateX(' + -(left + size + 16) + 'px)';
        show(A, WALK_RATE, true);
        requestAnimationFrame(walkStep);
        A.onended = function () {
          A.onended = null;
          state = 'arrive';
          box.style.transform = '';
          show(B, 1, false, function () { stage(A, 'idle'); });
          B.onended = function () { B.onended = null; idle(A); };
        };
      } else {
        state = 'intro';
        show(A);
        A.onended = function () { A.onended = null; idle(B); };
      }
    });
  }

  function toStill() {
    state = 'still';
    box.style.transform = '';
    box.classList.add('is-still');
    button.hidden = true;
    [A, B].forEach(function (v) { v.pause(); v.classList.remove('on'); });
    place();
    box.hidden = false;
  }

  button.addEventListener('click', function () {
    if (state !== 'idle') return;
    state = 'cheer';
    var idleV = cur, cheerV = other(cur), t0 = idleV.currentTime;
    // Idle passes the neutral pose (cheer's first frame) at 0 s and 2.2 s. Fast-forward to the next one
    // (at most 0.6 s) and cut there, so the cheer never jumps.
    var now = Math.abs(t0 - 2.2) < 0.15 || t0 < 0.15 || t0 > 3.85;
    var idleReady = new Promise(function (resolve) {
      (function wait() {
        var t = idleV.currentTime;
        if (now || (t0 < 2.2 ? t >= 2.18 : t < t0)) {
          idleV.playbackRate = 1;
          show(cheerV, 1, false, function () { stage(idleV, 'idle').then(resolve); });
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

  if ('ResizeObserver' in window) new ResizeObserver(function () { if (state) place(); }).observe(hero);

  function ready() {
    loaded = true;
    if (still) toStill();
    else if (visible) start();
  }
  if (document.readyState === 'complete') ready();
  else window.addEventListener('load', ready);
}());
