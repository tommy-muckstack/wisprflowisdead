(() => {
  const root = document.querySelector('.home-faq');
  if (!root) return;
  const list = root.querySelector('.home-questions');
  const questions = [...list.querySelectorAll('button')];
  const answers = questions.map(button => document.getElementById(button.getAttribute('aria-controls')));
  const panel = root.querySelector('.home-faq-panel');
  const compact = matchMedia('(max-width:900px)');
  let selected = compact.matches ? -1 : 0;

  function render() {
    const mobile = compact.matches;
    if (!mobile && selected < 0) selected = 0;
    const panelFocused = panel.contains(document.activeElement);
    if (mobile) {
      list.removeAttribute('role'); list.removeAttribute('aria-orientation'); list.removeAttribute('aria-label');
    } else {
      list.setAttribute('role', 'tablist'); list.setAttribute('aria-orientation', 'vertical'); list.setAttribute('aria-label', 'Product questions');
    }
    questions.forEach((button, index) => {
      const active = index === selected;
      button.disabled = false; button.tabIndex = mobile || active ? 0 : -1;
      button.classList.toggle('selected', active);
      button.setAttribute('aria-controls', mobile ? answers[index].id : panel.id);
      if (mobile) {
        button.removeAttribute('role'); button.removeAttribute('aria-selected');
        button.setAttribute('aria-expanded', String(active)); button.parentElement.removeAttribute('role');
      } else {
        button.setAttribute('role', 'tab'); button.setAttribute('aria-selected', String(active));
        button.removeAttribute('aria-expanded'); button.parentElement.setAttribute('role', 'presentation');
      }
      answers[index].hidden = !mobile || !active;
    });
    panel.hidden = mobile;
    if (!mobile) {
      panel.setAttribute('role', 'tabpanel'); panel.tabIndex = 0;
      panel.setAttribute('aria-labelledby', questions[selected].id);
      panel.querySelector('.home-faq-prompt').textContent = questions[selected].textContent;
      panel.querySelector('.home-faq-response').replaceChildren(...[...answers[selected].childNodes].map(node => node.cloneNode(true)));
    } else if (panelFocused) questions[Math.max(0, selected)].focus();
  }
  questions.forEach((button, index) => {
    button.addEventListener('click', () => {
      selected = compact.matches && selected === index ? -1 : index;
      render();
    });
    button.addEventListener('keydown', event => {
      if (compact.matches) return;
      const next = {ArrowDown:(index + 1) % questions.length, ArrowUp:(index + questions.length - 1) % questions.length, Home:0, End:questions.length - 1}[event.key];
      if (next === undefined) return;
      event.preventDefault(); selected = next; render(); questions[next].focus();
    });
  });
  compact.addEventListener('change', () => {
    const focused = questions.indexOf(document.activeElement);
    if (!compact.matches && focused >= 0) selected = focused;
    render();
  });
  root.classList.add('enhanced'); render();
})();
