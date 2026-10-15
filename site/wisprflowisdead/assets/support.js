// Guide links open their native disclosure before moving keyboard focus to it.
(() => {
  function showGuide() {
    const guide = document.getElementById(location.hash.slice(1));
    if (!(guide instanceof HTMLDetailsElement) || !guide.closest('.support-guide-answers')) return;
    guide.open = true;
    guide.querySelector('summary').focus({preventScroll:true});
    guide.scrollIntoView({block:'start',behavior:'instant'});
  }
  addEventListener('hashchange', showGuide);
  document.querySelectorAll('a[href^="#guide-"]').forEach(link => {
    link.addEventListener('click', () => {
      // Clicking the same hash again does not fire hashchange.
      if (link.hash === location.hash) showGuide();
    });
  });
  showGuide();
})();
