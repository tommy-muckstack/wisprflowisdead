(() => {
  const root = document.querySelector('.feature-stories');
  const stories = [...root.querySelectorAll('.feature-story')];
  const animated = matchMedia('(min-width:901px) and (min-height:721px) and (prefers-reduced-motion:no-preference)');
  let frame = 0;
  function select(story) {
    stories.forEach(item => item.classList.toggle('active', item === story));
  }
  function update() {
    frame = 0;
    if (!animated.matches) return;
    const focused = document.activeElement.closest('.feature-art');
    if (focused && root.contains(focused)) {select(focused.closest('.feature-story')); return;}
    const center = innerHeight / 2;
    const nearest = stories.reduce((best, story) => {
      const box = story.querySelector('.feature-copy').getBoundingClientRect();
      const distance = Math.abs(box.top + box.height / 2 - center);
      return distance < best.distance ? {story, distance} : best;
    }, {story:stories[0],distance:Infinity});
    select(nearest.story);
  }
  function schedule() {if (!frame) frame = requestAnimationFrame(update);}
  root.addEventListener('focusin', event => {
    const story = event.target.closest('.feature-story');
    if (!animated.matches || !story) return;
    select(story);
    if (event.target.closest('.feature-art')) story.querySelector('.feature-copy').scrollIntoView({block:'center',behavior:'instant'});
  });
  root.addEventListener('focusout', schedule);
  addEventListener('scroll', schedule, {passive:true});
  addEventListener('resize', schedule);
  addEventListener('pageshow', schedule);
  animated.addEventListener('change', schedule);
  root.classList.add('enhanced');
  update();
})();
