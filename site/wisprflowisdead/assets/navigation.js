(() => {
  const nav = document.querySelector('.nav');
  const toggle = nav.querySelector('.burger');
  const links = nav.querySelector('.links');
  const compact = matchMedia('(max-width:900px)');
  function setOpen(open) {
    nav.classList.toggle('open', open);
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  }
  toggle.addEventListener('click', () => setOpen(toggle.getAttribute('aria-expanded') !== 'true'));
  nav.addEventListener('keydown', event => {
    if (event.key === 'Escape' && toggle.getAttribute('aria-expanded') === 'true') {
      setOpen(false);
      toggle.focus();
    }
  });
  links.addEventListener('click', event => { if (event.target.closest('a')) setOpen(false); });
  document.addEventListener('click', event => { if (!nav.contains(event.target)) setOpen(false); });
  nav.addEventListener('focusout', event => { if (!nav.contains(event.relatedTarget)) setOpen(false); });
  compact.addEventListener('change', () => setOpen(false));

  // Account access lives in the footer and mobile menu, so authentication never
  // inserts extra desktop links or squeezes the download button.
  fetch('/wisprflowisdead/api/session', {credentials:'same-origin', cache:'no-store'})
    .then(response => response.ok ? response.json() : null)
    .then(me => {
      if (!me) return;
      document.querySelectorAll('[data-account-link]').forEach(link => {
        link.textContent = 'Account';
        link.href = '/wisprflowisdead/app';
      });
    }).catch(() => {});
})();
