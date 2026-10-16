(() => {
  const tabs = [...document.querySelectorAll('.tabs [role="tab"]')];
  function select(tab) {
    tabs.forEach(item => {
      const selected = item === tab;
      item.setAttribute('aria-selected', String(selected));
      item.tabIndex = selected ? 0 : -1;
      item.classList.toggle('on', selected);
      document.getElementById(item.getAttribute('aria-controls')).hidden = !selected;
    });
  }
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => select(tab));
    tab.addEventListener('keydown', event => {
      const next = {ArrowRight:(index + 1) % tabs.length, ArrowLeft:(index + tabs.length - 1) % tabs.length, Home:0, End:tabs.length - 1}[event.key];
      if (next === undefined) return;
      event.preventDefault();
      select(tabs[next]);
      tabs[next].focus();
    });
  });
  select(tabs[0]);
  document.body.classList.add('home-enhanced');

  const pin = document.querySelector('.pin');
  const stages = [...pin.querySelectorAll('.stage-in')];
  const staticLayout = matchMedia('(prefers-reduced-motion: reduce), (max-height: 720px), (max-width: 600px)');
  let frame = 0;
  function update() {
    frame = 0;
    if (staticLayout.matches) return;
    const span = pin.offsetHeight - innerHeight;
    const progress = span > 0 ? Math.min(.999, Math.max(0, -pin.getBoundingClientRect().top / span)) : 0;
    const index = Math.floor(progress * stages.length);
    stages.forEach((stage, i) => stage.classList.toggle('on', i === index));
  }
  function schedule() { if (!frame) frame = requestAnimationFrame(update); }
  addEventListener('scroll', schedule, {passive:true});
  addEventListener('resize', schedule);
  addEventListener('pageshow', schedule);
  staticLayout.addEventListener('change', schedule);
  update();
})();
