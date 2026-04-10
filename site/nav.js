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
  var css =
    ':root{--nav-height:76px}' +
    'nav[aria-label="Main navigation"]{background:var(--bg);border-bottom:0;padding:10px 0;position:sticky;top:0;z-index:10;min-height:var(--nav-height);display:flex;align-items:center}' +
    'nav[aria-label="Main navigation"] .container{max-width:1120px;display:flex;align-items:center;justify-content:space-between;width:100%;padding-right:28px;gap:16px}' +
    '.nav-logo{display:inline-flex;align-items:center;justify-content:center;height:48px;padding:0 16px;background:#fff;border:3px solid #000;box-shadow:var(--shadow-sm);font-weight:900;font-size:1.05rem;line-height:1;color:#000;text-transform:uppercase;letter-spacing:1px}' +
    '.nav-logo:hover{text-decoration:none}' +
    '.nav-store{display:none;align-items:center;opacity:0;pointer-events:none;transform:scale(0.92);transform-origin:center;transition:opacity 0.2s ease,transform 0.2s ease}' +
    '.nav-store-desktop{display:inline-flex;align-items:center;opacity:0;pointer-events:none;transform:scale(0.92);transform-origin:center;transition:opacity 0.2s ease,transform 0.2s ease}' +
    '.nav-store-mobile-wrap{display:none}' +
    '.nav-store-mobile{display:inline-flex;align-items:center;justify-content:center;height:48px;padding:0 12px;background:#fff;border:3px solid #000;border-radius:999px;box-shadow:var(--shadow-sm);font-weight:900;font-size:0.82rem;line-height:1;color:#000;text-transform:uppercase;letter-spacing:0.5px;white-space:nowrap}' +
    '.nav-store-mobile:hover{text-decoration:none}' +
    'nav[aria-label="Main navigation"].is-store-visible .nav-store-desktop,' +
    'nav[aria-label="Main navigation"].is-store-visible .nav-store{opacity:1;pointer-events:auto;transform:scale(1)}' +
    '.nav-links{display:flex;gap:16px;align-items:center;font-weight:800;font-size:0.9rem;margin-left:auto}' +
    '.nav-links a{color:var(--on-bg);text-transform:uppercase;letter-spacing:0.5px;border-bottom:3px solid transparent;padding:6px 0 2px}' +
    '.nav-links a:hover{border-bottom-color:var(--on-bg);text-decoration:none}' +
    '.nav-menu-btn{display:none;align-items:center;justify-content:center;width:48px;height:48px;background:#fff;border:3px solid #000;box-shadow:var(--shadow-sm);color:#000;cursor:pointer}' +
    '.nav-menu-btn span{display:block;width:18px;height:2px;background:#000;box-shadow:0 -6px 0 #000,0 6px 0 #000}' +
    '.lang-dropdown{position:relative}' +
    '.lang-btn{background:none;border:none;border-bottom:3px solid transparent;padding:6px 4px 2px;font-weight:900;font-size:0.85rem;cursor:pointer;font-family:var(--font);text-transform:uppercase;letter-spacing:0.5px;color:var(--on-bg)}' +
    '.lang-btn:hover{opacity:0.7}' +
    '.lang-btn:active{opacity:0.5}' +
    '.lang-menu{display:none;position:absolute;right:0;top:100%;padding-top:4px;min-width:168px;z-index:20}' +
    '.lang-menu-inner{background:var(--card);border:3px solid var(--border);box-shadow:var(--shadow-sm)}' +
    '.lang-dropdown:hover .lang-menu{display:block}' +
    '.lang-menu button{display:block;width:100%;background:none;border:none;padding:8px 12px;font-weight:800;font-size:0.85rem;cursor:pointer;font-family:var(--font);text-align:left;color:#000;white-space:nowrap}' +
    '.lang-dropdown,.lang-dropdown:hover,.lang-menu,.lang-menu-inner{cursor:pointer}' +
    '.lang-menu button:hover{background:var(--yellow)}' +
    '.theme-picker{display:flex;align-items:center;gap:8px}' +
    '.theme-label{display:none}' +
    '.theme-options{display:flex;align-items:center;gap:8px}' +
    '.theme-dot{width:18px;height:18px;border-radius:999px;border:3px solid #000;box-shadow:1px 1px 0 #000;cursor:pointer}' +
    '.theme-dot[data-theme="standard"]{background:#FFF7E0}' +
    '.theme-dot[data-theme="ocean"]{background:#E6F2FF}' +
    '.theme-dot[data-theme="blossom"]{background:#FFEDEF}' +
    '.theme-dot.is-active{outline:3px solid var(--accent);outline-offset:2px}' +
    '.nav-mobile{display:none}' +
    '@media(max-width:1024px){' +
      '.nav-menu-btn{display:inline-flex}' +
      '.nav-links{display:none}' +
      '.nav-store-desktop{display:none}' +
      '.nav-store{display:none}' +
      '.nav-store-mobile-wrap{display:inline-flex;position:absolute;left:50%;top:50%;opacity:0;pointer-events:none;transform:translate(-50%,-50%) scale(0.92);transform-origin:center;transition:opacity 0.2s ease,transform 0.2s ease}' +
      'nav[aria-label="Main navigation"].is-store-visible .nav-store-mobile-wrap{opacity:1;pointer-events:auto;transform:translate(-50%,-50%) scale(1)}' +
      '.nav-mobile{display:none;position:absolute;top:100%;left:0;right:0;background:#fff;padding:8px 20px 20px;border-top:3px solid #000;box-shadow:0 8px 0 #000}' +
      '.nav-mobile.is-open{display:block}' +
      '.nav-mobile-inner{max-width:1120px;margin:0 auto;display:flex;flex-direction:column;gap:8px}' +
      '.nav-mobile a,.nav-mobile button{display:block;width:100%;padding:14px 0;color:#000;font-weight:900;font-size:0.95rem;text-align:left;text-transform:uppercase;letter-spacing:0.5px;background:none;border:none;border-bottom:1px solid rgba(0,0,0,0.15);font-family:var(--font)}' +
      '.nav-mobile a:hover,.nav-mobile button:hover{text-decoration:none;opacity:0.8}' +
      '.theme-picker-mobile{padding:10px 0 4px}' +
    '}' +
    '@media(max-width:600px){:root{--nav-height:74px}}';

  var styleEl = document.createElement('style');
  styleEl.id = 'geni-nav-styles';
  styleEl.textContent = css;
  document.head.appendChild(styleEl);

  // ── HTML ───────────────────────────────────────────────────────────────────
  var APPLE        = '\uF8FF'; // Apple logo (private-use U+F8FF)
  var STORE_URL    = 'https://apps.apple.com/app/geni-kids/id6761134405';
  var logoHref     = isLanding ? '#top' : (isBlog ? '../' : '/');
  var featHref     = isLanding ? '#features-heading' : base + '#features-heading';
  var storeVisible = isLanding ? '' : ' class="is-store-visible"';

  function dlBtn(tabindex) {
    return '<a href="' + STORE_URL + '" class="nav-store-mobile"' +
           (tabindex ? ' tabindex="-1"' : '') +
           ' aria-label="Download on the App Store">' +
           '<span aria-hidden="true">' + APPLE + '</span>&nbsp;' +
           '<span data-i18n="nav_download">Download</span></a>';
  }

  var html =
    '<nav aria-label="Main navigation"' + storeVisible + '>' +
      '<div class="container">' +
        '<a href="' + logoHref + '" class="nav-logo" aria-label="Geni home" onclick="closeMenu()">GENI</a>' +
        '<div class="nav-links">' +
          '<a href="' + featHref + '" data-i18n="nav_features">Features</a>' +
          '<a href="' + base + 'math.html" data-i18n="nav_math">Math</a>' +
          '<a href="' + base + 'reading.html" data-i18n="nav_reading">Reading</a>' +
          '<a href="' + base + 'parents.html" data-i18n="nav_parents">For Parents</a>' +
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
            '<button class="lang-btn" id="langBtn" type="button"><span aria-hidden="true">\uD83C\uDDEC\uD83C\uDDE7</span> EN</button>' +
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
          '<a href="' + base + 'parents.html" data-i18n="nav_parents" onclick="closeMenu()">For Parents</a>' +
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

    // Theme
    window.applyTheme = function (theme) {
      var v = (theme === 'ocean' || theme === 'blossom') ? theme : 'standard';
      document.body.setAttribute('data-theme', v);
      for (var i = 0; i < themeBtns.length; i++) {
        themeBtns[i].classList.toggle('is-active', themeBtns[i].getAttribute('data-theme') === v);
      }
      if (themeColor) {
        themeColor.setAttribute('content', v === 'ocean' ? '#E6F2FF' : v === 'blossom' ? '#FFEDEF' : '#FFF7E0');
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
