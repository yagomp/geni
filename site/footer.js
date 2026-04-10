/* Geni shared footer — single source of truth for all pages */
(function () {
  'use strict';

  // ── Context detection ──────────────────────────────────────────────────────
  var pathname = window.location.pathname;
  var isBlog   = pathname.indexOf('/blog/') !== -1;
  var base     = isBlog ? '../' : '';

  // ── CSS ────────────────────────────────────────────────────────────────────
  var css =
    'footer{background:var(--bg);color:var(--on-bg);padding:20px 0;font-size:0.85rem;border-top:4px solid #000}' +
    'footer .container{max-width:800px;margin:0 auto;padding:0 20px;display:flex;flex-wrap:wrap;justify-content:center;align-items:flex-start;gap:16px;text-align:center}' +
    'footer a{color:#000;font-weight:700;text-decoration:none}' +
    'footer a:hover{color:#000;text-decoration:underline}' +
    '.footer-brand{display:flex;align-items:center;gap:10px;color:#000;font-weight:800;text-decoration:none;width:100%;justify-content:center}' +
    '.footer-brand:hover{text-decoration:none}' +
    '.footer-copy{max-width:620px;font-size:0.92rem;line-height:1.5;color:var(--on-bg);width:100%;text-align:center}' +
    '.footer-links{display:flex;gap:20px;font-weight:700;text-transform:uppercase;font-size:0.8rem;letter-spacing:0.5px;justify-content:center;text-align:center;width:100%}' +
    '@media(max-width:600px){footer .container{flex-direction:column;text-align:center}.footer-brand,.footer-copy,.footer-links{width:100%;justify-content:center;text-align:center}.footer-links{flex-wrap:wrap;gap:12px 20px}}';

  var styleEl = document.createElement('style');
  styleEl.id = 'geni-footer-styles';
  styleEl.textContent = css;
  document.head.appendChild(styleEl);

  // ── Translations ───────────────────────────────────────────────────────────
  var i18n = {
    en: { copy: 'Geni is a kids learning app for ages 5-10 with math practice, optional reading, offline play, parent controls, and no ads or tracking.', home: 'Home', parents: 'For Parents', privacy: 'Privacy', contact: 'Contact' },
    nb: { copy: 'Geni er en l\u00E6ringsapp for barn 5-10 \u00E5r med matte\u00F8ving, valgfri lesing, offline bruk, foreldrekontroll og ingen reklame eller sporing.', home: 'Hjem', parents: 'For foreldre', privacy: 'Personvern', contact: 'Kontakt' },
    es: { copy: 'Geni es una app educativa para ni\u00F1os de 5 a 10 a\u00F1os con matem\u00E1ticas, lectura opcional, juego sin conexi\u00F3n, controles parentales y sin anuncios ni rastreo.', home: 'Inicio', parents: 'Para padres', privacy: 'Privacidad', contact: 'Contacto' },
    pt: { copy: 'Geni \u00E9 um app educativo para crian\u00E7as de 5 a 10 anos com matem\u00E1tica, leitura opcional, uso offline, controles parentais e sem an\u00FAncios nem rastreamento.', home: 'In\u00EDcio', parents: 'Para pais', privacy: 'Privacidade', contact: 'Contato' }
  };

  // ── Language helpers ───────────────────────────────────────────────────────
  function normalizeLang(v) {
    if (!v) return 'en';
    if (v.indexOf('nb') === 0 || v.indexOf('nn') === 0 || v.indexOf('no') === 0) return 'nb';
    if (v.indexOf('es') === 0) return 'es';
    if (v.indexOf('pt') === 0) return 'pt';
    return 'en';
  }

  function getLang() {
    var l = 'en';
    try { var s = localStorage.getItem('geni_lang'); if (s) l = normalizeLang(s); } catch (e) {}
    return l;
  }

  // ── HTML builder ───────────────────────────────────────────────────────────
  function buildFooter(lang) {
    var t   = i18n[lang] || i18n.en;
    var yr  = new Date().getFullYear();
    return (
      '<footer>' +
        '<div class="container">' +
          '<a href="' + base + '" class="footer-brand" aria-label="Geni home">' +
            '<span>\u00A9 ' + yr + ' Geni</span>' +
          '</a>' +
          '<p class="footer-copy" id="footer-copy">' + t.copy + '</p>' +
          '<div class="footer-links">' +
            '<a href="' + base + '" id="footer-home">' + t.home + '</a>' +
            '<a href="' + base + 'parents.html" id="footer-parents">' + t.parents + '</a>' +
            '<a href="' + base + 'privacy.html" id="footer-privacy">' + t.privacy + '</a>' +
            '<a href="' + base + 'blog/">Blog</a>' +
            '<a href="' + base + 'contact.html" id="footer-contact">' + t.contact + '</a>' +
          '</div>' +
        '</div>' +
      '</footer>'
    );
  }

  // ── Inject footer HTML ─────────────────────────────────────────────────────
  document.currentScript.insertAdjacentHTML('afterend', buildFooter(getLang()));

  // ── Patch applyLang to keep footer in sync ─────────────────────────────────
  function applyFooterLang(lang) {
    var l = normalizeLang(lang);
    var t = i18n[l] || i18n.en;
    var el;
    el = document.getElementById('footer-copy');    if (el) el.textContent = t.copy;
    el = document.getElementById('footer-home');    if (el) el.textContent = t.home;
    el = document.getElementById('footer-parents'); if (el) el.textContent = t.parents;
    el = document.getElementById('footer-privacy'); if (el) el.textContent = t.privacy;
    el = document.getElementById('footer-contact'); if (el) el.textContent = t.contact;
  }

  function onReady(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  onReady(function () {
    // Wrap applyLang (defined by the page) so footer stays in sync on lang switch
    var orig = window.applyLang;
    if (typeof orig === 'function') {
      window.applyLang = function (lang) {
        orig(lang);
        applyFooterLang(lang);
      };
    }
  });

}());
