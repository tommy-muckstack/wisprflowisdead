// PostHog for the WisprFlowIsDead website (shared IsDead project 666931, US cloud).
// Contract: yourappisdead/ANALYTICS.md. This app's events and where they fire: docs/ANALYTICS.md.
// Super properties: product=wisprflowisdead, surface (landing | app), platform=web. Page views are PostHog's $pageview.
// Autocapture and session replay are off. Never pass user content (dictated text, emails, URLs, file names) as properties.
// Every other script calls window.isdeadAnalytics.{track,trackNow,identify,reset}; all of them are no-ops when analytics is off.
(() => {
  const KEY = 'phc_nrzr9eEcwg6H89hkh4DmBU4nL9ntSArzQXV2SR2vaE2F'; // publishable project token
  const BASE = '/wisprflowisdead';
  // Requests go through this site's own origin (vercel.json rewrites <BASE>/ingest → us.i.posthog.com) so ad blockers don't drop them.
  const API_HOST = location.origin + BASE + '/ingest';
  const APP = 'wisprflowisdead';
  // The working product: the browser demo and the signed-in account page. Everything else is the marketing site.
  const surface = () => (/^\/wisprflowisdead\/(demo|app)(\.html)?\/?$/.test(location.pathname) ? 'app' : 'landing');
  const superProps = () => ({product: APP, surface: surface(), platform: 'web'});
  // Keys older IsDead taxonomies (and other apps on this shared origin) persisted in the yourappisdead.com cookie.
  const LEGACY_PROPS = ['app', 'app_family', 'base_path', 'suite_id', 'app_id', 'schema_version', 'source', 'site_id', 'environment', 'account_type'];

  const local = /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);
  // Local runs stay silent unless explicitly opted in (scripts/ph-check style checks set isdead_ph_debug=1).
  let debug = false;
  try { debug = local && localStorage.getItem('isdead_ph_debug') === '1'; } catch { /* storage blocked */ }
  const off = (local && !debug) || navigator.doNotTrack === '1' || window.doNotTrack === '1';

  const api = {track() {}, trackNow: async () => {}, identify() {}, reset() {}, enabled: !off};
  window.isdeadAnalytics = api;
  if (off) return;

  let resolveReady;
  const ready = new Promise(resolve => { resolveReady = resolve; });
  // Official posthog-js snippet, trimmed. array.js loads from <API_HOST>/static/array.js (proxied to us-assets.i.posthog.com).
  !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.crossOrigin="anonymous",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="init capture register register_once register_for_session unregister unregister_for_session identify setPersonProperties reset get_distinct_id alias set_config opt_in_capturing opt_out_capturing has_opted_in_capturing has_opted_out_capturing is_capturing".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);

  // array.js replaces window.posthog (the stub queue) with the real client, so always look it up at call time.
  const ph = () => window.posthog;
  ph().init(KEY, {
    api_host: API_HOST,
    ui_host: 'https://us.posthog.com',
    capture_pageview: true, // a full page load per route on this static site
    capture_pageleave: true,
    autocapture: false,
    disable_session_recording: true,
    persistence: 'localStorage+cookie',
    person_profiles: 'always',
    debug,
    opt_out_useragent_filter: debug, // local checks only: accept automated browsers
    // Runs before the initial $pageview and before any queued capture: clear other apps' leftovers, then set ours.
    loaded: ph => {
      LEGACY_PROPS.forEach(k => ph.unregister(k));
      ph.register({...superProps(), env: local ? 'development' : 'production'});
      if (debug) window.__posthog = ph;
      resolveReady(ph);
    },
  });
  ph().register(superProps());

  api.track = (event, props = {}) => { ph().capture(event, {surface: surface(), ...props}); };
  // Sent immediately; await it before navigating away. Never throws or waits longer than 1.5s.
  api.trackNow = (event, props = {}) => Promise.race([
    ready.then(ph => { ph.capture(event, {surface: surface(), ...props}, {send_instantly: true}); }).catch(() => {}),
    new Promise(resolve => setTimeout(resolve, 1500)),
  ]);
  // Signed-in users are identified by Firebase uid, shared across the IsDead family.
  api.identify = uid => { if (typeof uid === 'string' && uid) ph().identify(uid, {account_type: 'firebase'}); };
  // reset() wipes super properties too, so put this app's back straight away.
  api.reset = () => { ph().reset(); ph().register(superProps()); };

  // Marketing CTAs (landing pages only). Records where the link sits and what it leads to, never the URL itself.
  const where = a => a.closest('.banner') ? 'banner' : a.closest('nav') ? 'nav' : a.closest('.hero') ? 'hero'
    : a.closest('footer') ? 'footer' : a.closest('#download') ? 'download_section' : 'page';
  document.addEventListener('click', event => {
    if (surface() !== 'landing') return;
    const a = event.target instanceof Element ? event.target.closest('a[href]') : null;
    if (!a) return;
    const href = a.getAttribute('href') || '';
    if (a.id === 'dl') return api.track('landing_download_clicked', {target: /^https?:/.test(a.href) && !a.href.startsWith(location.origin) ? 'dmg' : 'source_build', location: where(a)});
    if (/#download$/.test(href)) return api.track('landing_download_clicked', {target: 'download_section', location: where(a)});
    const target = /\/login$/.test(href) ? 'login' : /\/demo$/.test(href) ? 'demo' : /\/pricing$/.test(href) ? 'pricing'
      : /\/support$/.test(href) ? 'support' : /github\.com\//.test(href) ? 'github' : null;
    if (target) api.track('landing_cta_clicked', {target, location: where(a)});
  }, true);
})();
