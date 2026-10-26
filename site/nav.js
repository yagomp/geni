/* Geni shared navbar — single source of truth for all pages */
(function () {
  'use strict';

  // ── Context detection ──────────────────────────────────────────────────────
  var pathname = window.location.pathname;
  var isBlog   = pathname.indexOf('/blog/') !== -1;
  var base     = isBlog ? '../' : '';
  // Landing page = root "/" or "/index.html"
  var isLanding = !isBlog && (pathname === '/' || pathname === '' ||
                  pathname.endsWith('/index.html'));

  // ── CSS ────────────────────────────────────────────────────────────────────
  var css = `nav[aria-label="Main navigation"]{background:var(--bg);height:var(--nav-height);position:sticky;top:0;z-index:10;display:flex;align-items:center}
nav[aria-label="Main navigation"].is-scrolled{box-shadow:var(--shadow)}
nav[aria-label="Main navigation"]>.container{display:flex;align-items:center;justify-content:space-between;gap:var(--s-3);height:100%}
.nav-logo{display:inline-flex;align-items:center;gap:var(--s-2);min-height:44px;flex:none;font-size:1.25rem;font-weight:900;color:var(--ink);border-radius:var(--r-sm)}
.nav-logo img{width:40px;height:40px;border-radius:var(--r-sm)}
.nav-links{display:flex;align-items:center;gap:0;margin-left:auto}
.nav-links>a,.lang-btn{display:inline-flex;align-items:center;justify-content:center;min-height:44px;padding:10px 10px;border:0;border-radius:var(--r-md);background:none;color:var(--ink);font:700 1rem/1.4 var(--font);white-space:nowrap;cursor:pointer}
.lang-btn{gap:8px}
.nav-links>a:hover,.lang-btn:hover{color:var(--accent-ink)}.nav-links>a[aria-current="page"]{background:var(--card);box-shadow:var(--shadow)}
.nav-store-desktop,.nav-store-mobile-wrap{display:inline-flex;opacity:0;visibility:hidden;pointer-events:none;transform:scale(.92);transition:opacity .2s ease-out,transform .2s ease-out,visibility .2s ease-out}
nav.is-store-visible .nav-store-desktop,nav.is-store-visible .nav-store-mobile-wrap{opacity:1;visibility:visible;pointer-events:auto;transform:scale(1)}
.nav-store-mobile{white-space:nowrap}.nav-store-mobile-wrap{display:none}
.nav-menu-btn{display:none;align-items:center;justify-content:center;width:48px;height:48px;border:0;border-radius:var(--r-md);background:var(--card);box-shadow:var(--shadow);cursor:pointer;flex:none}
.nav-menu-btn span{display:block;position:relative;width:18px;height:2px;background:var(--ink);border-radius:var(--r-pill)}.nav-menu-btn span::before,.nav-menu-btn span::after{content:"";position:absolute;left:0;width:18px;height:2px;background:var(--ink);border-radius:var(--r-pill)}.nav-menu-btn span::before{top:-6px}.nav-menu-btn span::after{top:6px}
.lang-dropdown{position:relative}.lang-menu{display:none;position:absolute;right:0;top:100%;padding-top:var(--s-1);min-width:168px;z-index:20}.lang-menu.is-open{display:block}
.lang-menu-inner{background:var(--card);border-radius:var(--r-md);box-shadow:var(--shadow-lift);padding:var(--s-2)}.lang-menu button{display:block;width:100%;min-height:44px;padding:10px 12px;border:0;border-radius:var(--r-sm);background:none;font:700 1rem/1.4 var(--font);text-align:left;color:var(--ink);cursor:pointer;white-space:nowrap}.lang-menu button:hover{background:var(--accent-soft)}
.theme-picker,.theme-options{display:flex;align-items:center}.theme-label{display:none}.theme-dot{display:flex;align-items:center;justify-content:center;width:44px;height:44px;padding:0;border:0;border-radius:var(--r-md);background:none;cursor:pointer;flex:none}.theme-dot::before{content:"";display:block;width:22px;height:22px;border-radius:var(--r-pill);background:var(--theme-standard);box-shadow:0 0 0 2px var(--card),var(--shadow)}.theme-dot[data-theme="ocean"]::before{background:var(--theme-ocean)}.theme-dot[data-theme="blossom"]::before{background:var(--theme-blossom)}.theme-dot.is-active::before{box-shadow:0 0 0 2px var(--card),0 0 0 4px var(--accent)}
.nav-mobile{display:none}
@media(min-width:1025px) and (max-width:1199px){.nav-links>a,.lang-btn{padding-inline:8px}}
@media(max-width:1024px){.nav-links,.nav-store-desktop{display:none}.nav-menu-btn{display:inline-flex}.nav-store-mobile-wrap{display:inline-flex;position:absolute;left:0;right:0;top:0;bottom:0;width:max-content;margin:auto;align-items:center;transform:scale(.92)}nav.is-store-visible .nav-store-mobile-wrap{transform:scale(1)}.nav-mobile{position:absolute;top:100%;left:0;right:0;background:var(--card);border-radius:0 0 var(--r-lg) var(--r-lg);box-shadow:var(--shadow-lift);padding:8px 20px 20px;max-height:calc(100dvh - var(--nav-height));overflow:auto}.nav-mobile.is-open{display:block}.nav-mobile-inner{max-width:var(--container);margin:auto;display:flex;flex-direction:column}.nav-mobile-inner>a,.nav-mobile-inner>button{display:flex;align-items:center;min-height:52px;width:100%;padding:10px 14px;border:0;border-radius:var(--r-md);background:none;color:var(--ink);font:700 var(--fs-body)/1.4 var(--font);text-align:left;cursor:pointer}.nav-mobile-inner>a:hover,.nav-mobile-inner>button:hover,.nav-mobile-inner>a[aria-current="page"]{background:var(--accent-soft)}.nav-mobile-inner>button:first-of-type{border-top:1px solid var(--hairline);border-radius:0;margin-top:var(--s-2);padding-top:var(--s-4)}.theme-picker-mobile{padding:var(--s-2) 0 0}}
`;

  var styleEl = document.createElement('style');
  styleEl.id = 'geni-nav-styles';
  styleEl.textContent = css;
  document.head.appendChild(styleEl);

  // ── HTML ───────────────────────────────────────────────────────────────────
  var STORE_URL    = 'https://apps.apple.com/app/geni-kids/id6761134405';
  var logoHref     = isLanding ? '#top' : (isBlog ? '../' : '/');
  var featHref     = isLanding ? '#features-heading' : (base || './') + '#features-heading';
  var storeVisible = isLanding ? '' : ' class="is-store-visible"';

  function dlBtn(tabindex) {
    return '<a href="' + STORE_URL + '" class="nav-store-mobile btn btn--primary btn--sm"' +
           (tabindex ? ' tabindex="-1"' : '') +
           ' aria-label="Download on the App Store">' +
           '<span data-i18n="nav_download">Download</span></a>';
  }

  var html =
    '<nav aria-label="Main navigation"' + storeVisible + '>' +
      '<div class="container">' +
        '<a href="' + logoHref + '" class="nav-logo" aria-label="Geni home" onclick="closeMenu()"><img src="' + base + 'icon-mark.png" alt="" width="40" height="40"><span>Geni</span></a>' +
        '<div class="nav-links">' +
          '<a href="' + featHref + '" data-i18n="nav_features">Features</a>' +
          '<a href="' + base + 'math.html" data-i18n="nav_math">Math</a>' +
          '<a href="' + base + 'reading.html" data-i18n="nav_reading">Reading</a>' +
          '<a href="' + base + 'parents.html" data-i18n="nav_parents">For parents</a>' +
          '<a href="' + base + 'privacy.html" data-i18n="nav_privacy">Privacy</a>' +
          '<a href="' + base + 'blog/">Blog</a>' +
          '<div class="theme-picker" aria-label="Theme selector">' +
            '<div class="theme-options">' +
              '<button class="theme-dot" type="button" data-theme="standard" data-i18n-aria-label="theme_standard" aria-label="Standard theme"></button>' +
              '<button class="theme-dot" type="button" data-theme="ocean" data-i18n-aria-label="theme_ocean" aria-label="Ocean theme"></button>' +
              '<button class="theme-dot" type="button" data-theme="blossom" data-i18n-aria-label="theme_blossom" aria-label="Blossom theme"></button>' +
            '</div>' +
          '</div>' +
          '<div class="lang-dropdown">' +
            '<button class="lang-btn" id="langBtn" type="button" aria-expanded="false" aria-controls="langMenu" aria-label="Language"><span aria-hidden="true">\uD83C\uDDEC\uD83C\uDDE7</span> EN</button>' +
            '<div class="lang-menu" id="langMenu"><div class="lang-menu-inner">' +
              '<button onclick="applyLang(\'en\')"><span aria-hidden="true">\uD83C\uDDEC\uD83C\uDDE7</span> English</button>' +
              '<button onclick="applyLang(\'nb\')"><span aria-hidden="true">\uD83C\uDDF3\uD83C\uDDF4</span> Norsk</button>' +
              '<button onclick="applyLang(\'es\')"><span aria-hidden="true">\uD83C\uDDEA\uD83C\uDDF8</span> Espa\u00F1ol</button>' +
              '<button onclick="applyLang(\'pt\')"><span aria-hidden="true">\uD83C\uDDF5\uD83C\uDDF9</span> Portugu\u00EAs</button>' +
            '</div></div>' +
          '</div>' +
        '</div>' +
        '<div class="nav-store-desktop" aria-hidden="true">' + dlBtn(true) + '</div>' +
        '<button class="nav-menu-btn" id="menuToggle" type="button" aria-expanded="false" aria-controls="mobileMenu" aria-label="Open menu"><span aria-hidden="true"></span></button>' +
      '</div>' +
      '<div class="nav-store-mobile-wrap" aria-hidden="true">' + dlBtn(true) + '</div>' +
      '<div class="nav-mobile" id="mobileMenu">' +
        '<div class="nav-mobile-inner">' +
          '<a href="' + featHref + '" data-i18n="nav_features" onclick="closeMenu()">Features</a>' +
          '<a href="' + base + 'math.html" data-i18n="nav_math" onclick="closeMenu()">Math</a>' +
          '<a href="' + base + 'reading.html" data-i18n="nav_reading" onclick="closeMenu()">Reading</a>' +
          '<a href="' + base + 'parents.html" data-i18n="nav_parents" onclick="closeMenu()">For parents</a>' +
          '<a href="' + base + 'privacy.html" data-i18n="nav_privacy" onclick="closeMenu()">Privacy</a>' +
          '<a href="' + base + 'blog/" onclick="closeMenu()">Blog</a>' +
          '<button type="button" onclick="applyLang(\'en\')"><span aria-hidden="true">\uD83C\uDDEC\uD83C\uDDE7</span> English</button>' +
          '<button type="button" onclick="applyLang(\'nb\')"><span aria-hidden="true">\uD83C\uDDF3\uD83C\uDDF4</span> Norsk</button>' +
          '<button type="button" onclick="applyLang(\'es\')"><span aria-hidden="true">\uD83C\uDDEA\uD83C\uDDF8</span> Espa\u00F1ol</button>' +
          '<button type="button" onclick="applyLang(\'pt\')"><span aria-hidden="true">\uD83C\uDDF5\uD83C\uDDF9</span> Portugu\u00EAs</button>' +
          '<div class="theme-picker-mobile">' +
            '<div class="theme-options">' +
              '<button class="theme-dot" type="button" data-theme="standard" data-i18n-aria-label="theme_standard" aria-label="Standard theme"></button>' +
              '<button class="theme-dot" type="button" data-theme="ocean" data-i18n-aria-label="theme_ocean" aria-label="Ocean theme"></button>' +
              '<button class="theme-dot" type="button" data-theme="blossom" data-i18n-aria-label="theme_blossom" aria-label="Blossom theme"></button>' +
            '</div>' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</nav>';

  document.currentScript.insertAdjacentHTML('afterend', html);

  // ── Interactions (after DOM is ready) ──────────────────────────────────────
  function onReady(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  // Define closeMenu immediately so applyLang() can call it safely during
  // initial page load (before DOMContentLoaded fires).
  window.closeMenu = function () {
    var t = document.getElementById('menuToggle');
    var m = document.getElementById('mobileMenu');
    if (!t || !m) return;
    t.setAttribute('aria-expanded', 'false');
    m.classList.remove('is-open');
  };

  onReady(function () {
    var nav         = document.querySelector('nav[aria-label="Main navigation"]');
    var menuToggle  = document.getElementById('menuToggle');
    var mobileMenu  = document.getElementById('mobileMenu');
    var themeBtns   = document.querySelectorAll('.theme-dot');
    var themeColor  = document.querySelector('meta[name="theme-color"]');
    if (menuToggle) {
      menuToggle.addEventListener('click', function () {
        var open = menuToggle.getAttribute('aria-expanded') !== 'true';
        menuToggle.setAttribute('aria-expanded', String(open));
        mobileMenu.classList.toggle('is-open', open);
      });
    }

    var languageButton = document.getElementById('langBtn');
    var languageMenu = document.getElementById('langMenu');
    function closeLanguage() {
      languageMenu.classList.remove('is-open');
      languageButton.setAttribute('aria-expanded', 'false');
    }
    languageButton.addEventListener('click', function () {
      var open = languageButton.getAttribute('aria-expanded') !== 'true';
      languageButton.setAttribute('aria-expanded', String(open));
      languageMenu.classList.toggle('is-open', open);
    });
    document.addEventListener('click', function (event) {
      if (!event.target.closest('.lang-dropdown')) closeLanguage();
    });
    languageMenu.addEventListener('click', function (event) {
      if (event.target.closest('button')) { closeLanguage(); languageButton.focus(); }
    });
    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') {
        if (languageMenu.classList.contains('is-open')) { closeLanguage(); languageButton.focus(); }
        if (mobileMenu.classList.contains('is-open')) { window.closeMenu(); menuToggle.focus(); }
      }
    });
    document.addEventListener('focusin', function (event) {
      if (!event.target.closest('.lang-dropdown')) closeLanguage();
    });
    nav.querySelectorAll('.nav-links > a, .nav-mobile-inner > a').forEach(function (link) {
      var url = new URL(link.href);
      if (!url.hash && url.pathname.replace(/index\.html$/, '') === pathname.replace(/index\.html$/, '')) {
        link.setAttribute('aria-current', 'page');
      }
    });
    function updateNav() { nav.classList.toggle('is-scrolled', window.scrollY > 8); }
    window.addEventListener('scroll', updateNav, { passive: true });
    updateNav();
    function updateDownload() {
      var visible = nav.classList.contains('is-store-visible');
      nav.querySelectorAll('.nav-store-desktop, .nav-store-mobile-wrap').forEach(function (wrap) {
        wrap.setAttribute('aria-hidden', String(!visible));
        wrap.querySelector('a').tabIndex = visible ? 0 : -1;
      });
    }
    updateDownload();
    new MutationObserver(updateDownload).observe(nav, { attributes: true, attributeFilter: ['class'] });

    // Shared navigation translations also cover pages without a full T dictionary.
    var navText = {
      en: { nav_features:'Features', nav_math:'Math', nav_reading:'Reading', nav_parents:'For parents', nav_privacy:'Privacy', nav_download:'Download', theme_standard:'Standard theme', theme_ocean:'Ocean theme', theme_blossom:'Blossom theme' },
      nb: { nav_features:'Funksjoner', nav_math:'Matte', nav_reading:'Lesing', nav_parents:'For foreldre', nav_privacy:'Personvern', nav_download:'Last ned', theme_standard:'Standardtema', theme_ocean:'Havtema', theme_blossom:'Blomstertema' },
      es: { nav_features:'Funciones', nav_math:'Matemáticas', nav_reading:'Lectura', nav_parents:'Para padres', nav_privacy:'Privacidad', nav_download:'Descargar', theme_standard:'Tema estándar', theme_ocean:'Tema océano', theme_blossom:'Tema floración' },
      pt: { nav_features:'Recursos', nav_math:'Matemática', nav_reading:'Leitura', nav_parents:'Para pais', nav_privacy:'Privacidade', nav_download:'Baixar', theme_standard:'Tema padrão', theme_ocean:'Tema oceano', theme_blossom:'Tema florescer' }
    };
    function translateNav() {
      var text = navText[document.documentElement.lang] || navText.en;
      nav.querySelectorAll('[data-i18n]').forEach(function (element) {
        var value = text[element.getAttribute('data-i18n')];
        if (value) element.textContent = value;
      });
      nav.querySelectorAll('[data-i18n-aria-label]').forEach(function (element) {
        var value = text[element.getAttribute('data-i18n-aria-label')];
        if (value) element.setAttribute('aria-label', value);
      });
      nav.querySelectorAll('.nav-store-mobile').forEach(function (link) { link.setAttribute('aria-label', text.nav_download); });
      menuToggle.setAttribute('aria-label', ({ en:'Menu', nb:'Meny', es:'Menú', pt:'Menu' })[document.documentElement.lang] || 'Menu');
      languageButton.setAttribute('aria-label', ({ en:'Language', nb:'Språk', es:'Idioma', pt:'Idioma' })[document.documentElement.lang] || 'Language');
    }
    var originalApplyLang = window.applyLang;
    if (typeof originalApplyLang === 'function') {
      window.applyLang = function (lang) {
        originalApplyLang(lang);
        translateNav();
        window.closeMenu();
      };
    }
    translateNav();

    // Theme
    window.applyTheme = function (theme) {
      var v = (theme === 'ocean' || theme === 'blossom') ? theme : 'standard';
      document.body.setAttribute('data-theme', v);
      for (var i = 0; i < themeBtns.length; i++) {
        var active = themeBtns[i].getAttribute('data-theme') === v;
        themeBtns[i].classList.toggle('is-active', active);
        themeBtns[i].setAttribute('aria-pressed', String(active));
      }
      if (themeColor) {
        themeColor.setAttribute('content', v === 'ocean' ? '#E6F2FF' : v === 'blossom' ? '#FFEDF2' : '#FFF7E0');
      }
      try { localStorage.setItem('geni_theme', v); } catch (e) {}
    };
    for (var i = 0; i < themeBtns.length; i++) {
      themeBtns[i].addEventListener('click', function () { window.applyTheme(this.getAttribute('data-theme')); });
    }
    try { window.applyTheme(localStorage.getItem('geni_theme') || 'standard'); } catch (e) { window.applyTheme('standard'); }

    // Scroll-triggered download button (landing page only)
    if (isLanding && nav) {
      var hero = document.getElementById('hero');
      if (hero && 'IntersectionObserver' in window) {
        new IntersectionObserver(function (entries) {
          nav.classList.toggle('is-store-visible', !entries[0].isIntersecting);
        }, { rootMargin: '-80px 0px 0px 0px', threshold: 0 }).observe(hero);
      }
    }
  });

}());
