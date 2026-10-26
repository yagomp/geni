(function () {
  'use strict';

  var dialog = document.getElementById('demoDialog');
  var openButton = document.getElementById('demoOpen');
  var closeButton = document.getElementById('demoClose');
  var video = document.getElementById('demoVideo');
  var sources = video.querySelectorAll('source');
  var returnFocus;
  var backdropPress = false;
  var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  function play() {
    if (!reducedMotion.matches) {
      var playback = video.play();
      if (playback) playback.catch(function () { /* Poster and controls remain available. */ });
    }
  }

  openButton.addEventListener('click', function () {
    returnFocus = document.activeElement;
    var lang = document.documentElement.lang === 'nb' ? 'no' : 'en';
    // AV1 first for browsers that decode it; H.264 plays everywhere else.
    sources[0].src = 'media/geni-demo-' + lang + '-av1.mp4';
    sources[1].src = 'media/geni-demo-' + lang + '.mp4';
    video.poster = 'media/geni-demo-' + lang + '.webp';
    video.muted = true;
    video.autoplay = !reducedMotion.matches;
    video.preload = 'auto';
    dialog.showModal(); // Native modal behavior traps focus and makes the page inert.
    document.body.classList.add('demo-open');
    video.load();
    play();
  });

  closeButton.addEventListener('click', function () { dialog.close(); });
  dialog.addEventListener('pointerdown', function (event) {
    backdropPress = outsideDialog(event);
  });
  dialog.addEventListener('click', function (event) {
    if (backdropPress && outsideDialog(event)) dialog.close();
    backdropPress = false;
  });
  function outsideDialog(event) {
    var rect = dialog.getBoundingClientRect();
    return event.clientX < rect.left || event.clientX > rect.right ||
      event.clientY < rect.top || event.clientY > rect.bottom;
  }

  dialog.addEventListener('close', function () {
    video.pause();
    video.autoplay = false;
    video.preload = 'none';
    sources.forEach(function (source) { source.removeAttribute('src'); });
    video.load();
    document.body.classList.remove('demo-open');
    if (returnFocus && returnFocus.isConnected) returnFocus.focus({ preventScroll: true });
  });
}());
