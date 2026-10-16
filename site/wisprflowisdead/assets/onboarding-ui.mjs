import {Onboarding, steps} from './onboarding.mjs';

export function mountOnboarding({settings, start, canDictate}) {
  const $ = id => document.getElementById(id);
  let storage, busy = false;
  try {storage = window.localStorage;} catch { /* The guide also works without storage. */ }
  const guide = new Onboarding(storage);
  const titles = {privacy:'Before you speak', microphone:'Check your microphone', preferences:'Make it comfortable', practice:'Try your first dictation'};
  const notice = message => {$('setup-notice').textContent = message; $('setup-notice').hidden = !message;};
  function render() {
    $('setup-guide').hidden = !guide.visible;
    $('open-setup').setAttribute('aria-expanded', String(guide.visible));
    $('setup-heading').textContent = titles[guide.current];
    $('setup-progress').textContent = `Step ${guide.index + 1} of ${steps.length}`;
    for (const step of steps) {
      $('setup-' + step).hidden = step !== guide.current;
      const marker = document.querySelector(`[data-setup-step="${step}"]`);
      if (step === guide.current) marker.setAttribute('aria-current', 'step'); else marker.removeAttribute('aria-current');
      marker.querySelector('small').textContent = guide.marks[step] === 'completed' ? 'Done' : guide.marks[step] === 'skipped' ? 'Skipped' : '';
    }
    const micMessage = guide.marks.microphone === 'completed' ? 'Input level detected. You can continue.'
      : !settings.microphone.getUserMedia || !settings.microphone.createContext ? 'Microphone checking is unavailable here. Skip this step and use typed practice.'
      : 'Speak during the check to see the input level. You can skip this step.';
    const practiceMessage = guide.marks.practice === 'completed' ? 'Your own text is ready in the editor. Review it before copying.'
      : !canDictate() ? 'Speech recognition is unavailable here. Use typed practice to complete this step.'
      : 'A successful dictation or typed cleanup completes this step.';
    if ($('setup-mic-result').textContent !== micMessage) $('setup-mic-result').textContent = micMessage;
    if ($('setup-practice-result').textContent !== practiceMessage) $('setup-practice-result').textContent = practiceMessage;
    $('setup-next').disabled = busy || !guide.ready;
    $('setup-next').textContent = guide.index === steps.length - 1 ? 'Finish setup' : guide.current === 'preferences' ? 'Use current settings' : 'Continue';
    $('setup-back').hidden = guide.index === 0;
    $('setup-skip-step').hidden = !['microphone','practice'].includes(guide.current);
    for (const id of ['open-setup','setup-back','setup-skip-step','setup-skip','setup-settings','setup-type']) $(id).disabled = busy;
    $('setup-test-mic').disabled = busy || !settings.microphone.getUserMedia || !settings.microphone.createContext;
    $('setup-dictate').disabled = busy || !canDictate();
  }
  function navigate(action) {
    try {notice(action() || ''); render(); if (guide.visible) $('setup-heading').focus(); else $('editor').focus();}
    catch (error) {notice(error.message);}
  }
  $('open-setup').addEventListener('click', () => navigate(() => {if (!guide.visible) guide.open();}));
  $('setup-next').addEventListener('click', () => navigate(() => guide.next()));
  $('setup-back').addEventListener('click', () => navigate(() => guide.previous()));
  $('setup-skip-step').addEventListener('click', () => navigate(() => guide.next(true)));
  $('setup-skip').addEventListener('click', () => navigate(() => guide.finish('skipped')));
  $('setup-settings').addEventListener('click', () => settings.openTo('settings-language'));
  $('setup-test-mic').addEventListener('click', () => {
    if (settings.openTo('microphone-start')) void settings.microphone.start();
  });
  $('setup-dictate').addEventListener('click', () => {
    start(); $('workspace').focus(); $('record').scrollIntoView({block:'center'});
  });
  $('setup-type').addEventListener('click', () => {
    document.querySelector('.practice').open = true; $('practice-input').focus();
  });
  notice(guide.load()); render();
  return {
    setBusy(value) {if (busy !== value) {busy = value; render();}},
    microphoneLevel(value) {
      if (guide.visible && value > .02 && guide.marks.microphone !== 'completed') {guide.observe('microphone', true); render();}
    },
    result(snapshot) {
      if (guide.visible && snapshot.state === 'result' && snapshot.raw.trim() && snapshot.result.trim() && guide.marks.practice !== 'completed') {
        guide.observe('practice', true); render();
      }
    }
  };
}
