/* Geni phone demo — plays an app exercise once when the phone scrolls into view,
   then offers a liquid-glass replay button. Shared by the landing, math and reading heroes.

   GeniPhoneDemo(screen, {
     steps:  [[ms, fn], ...]  timeline of one run,
     end:    ms               when the run is finished,
     reset:  fn               back to the start state,
     finish: fn               jump to the end state (reduced motion)
   }) */
(function () {
  'use strict';

  var LABELS = { en: 'Play again', nb: 'Spill igjen', es: 'Reproducir de nuevo', pt: 'Reproduzir novamente' };
  var TRIANGLE = 'M22 12.6c0-3.1 3.4-5 6-3.4l33 21.4c2.4 1.6 2.4 5.2 0 6.8l-33 21.4c-2.6 1.6-6-.3-6-3.4z';
  var uid = 0;

  function label() {
    var l = (document.documentElement.lang || 'en').slice(0, 2);
    return LABELS[l] || LABELS.en;
  }

  function glassButton() {
    var n = ++uid;
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'hero-replay';
    btn.hidden = true;
    btn.setAttribute('aria-label', label());
    btn.innerHTML =
      '<span class="glass-play" aria-hidden="true">' +
        '<svg class="gp-shadow" viewBox="0 0 72 72"><path d="' + TRIANGLE + '"/></svg>' +
        '<svg class="gp-glass" viewBox="0 0 72 72"><defs>' +
          '<linearGradient id="gpFill' + n + '" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".82"/><stop offset=".55" stop-color="#fff" stop-opacity=".38"/><stop offset="1" stop-color="#fff" stop-opacity=".6"/></linearGradient>' +
          '<linearGradient id="gpRim' + n + '" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#fff" stop-opacity=".45"/><stop offset="1" stop-color="#fff" stop-opacity=".9"/></linearGradient>' +
          '<linearGradient id="gpShine' + n + '" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>' +
          '<clipPath id="gpClip' + n + '"><path d="' + TRIANGLE + '"/></clipPath></defs>' +
          '<path d="' + TRIANGLE + '" fill="url(#gpFill' + n + ')"/>' +
          '<ellipse cx="30" cy="20" rx="14" ry="7" fill="url(#gpShine' + n + ')" opacity=".7" clip-path="url(#gpClip' + n + ')" transform="rotate(30 30 20)"/>' +
          '<path d="' + TRIANGLE + '" fill="none" stroke="url(#gpRim' + n + ')" stroke-width="1.6"/>' +
          '<path d="' + TRIANGLE + '" fill="none" stroke="rgba(60,50,20,.12)" stroke-width=".8" transform="translate(0 .6)"/>' +
        '</svg>' +
      '</span>';
    return btn;
  }

  window.GeniPhoneDemo = function (screen, opts) {
    var btn = glassButton();
    var timers = [];
    screen.appendChild(btn);

    new MutationObserver(function () { btn.setAttribute('aria-label', label()); })
      .observe(document.documentElement, { attributes: true, attributeFilter: ['lang'] });

    function showButton() {
      btn.hidden = false;
      requestAnimationFrame(function () { btn.classList.add('is-shown'); });
    }
    function clear() { timers.forEach(clearTimeout); timers = []; }
    function play() {
      clear();
      btn.classList.remove('is-shown');
      btn.hidden = true;
      opts.reset();
      opts.steps.forEach(function (s) { timers.push(setTimeout(s[1], s[0])); });
      timers.push(setTimeout(showButton, opts.end + 1200));
    }
    function finish() { clear(); opts.finish(); showButton(); }

    btn.addEventListener('click', play);
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches || !('IntersectionObserver' in window)) {
      finish();
    } else {
      var io = new IntersectionObserver(function (e) {
        if (e[0].isIntersecting) { io.disconnect(); play(); }
      }, { threshold: 0.3 });
      io.observe(screen);
    }
    return { play: play, finish: finish };
  };
}());
