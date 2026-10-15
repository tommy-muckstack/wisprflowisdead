import {Preferences, PREFERENCES_KEY, shortcutLabel} from './preferences.mjs';
import {MicrophoneCheck} from './microphone.mjs';

export function mountSettings({onMicrophoneBusy, onMicrophoneLevel = () => {}}) {
  const $ = id => document.getElementById(id);
  const dialog = $('settings-dialog');
  let storage, busy = false, capturing = false;
  try {storage = window.localStorage;} catch { /* Settings can remain page-only. */ }
  const preferences = new Preferences(storage);
  const say = message => {
    $('settings-status').textContent = $('preferences-notice').textContent = message;
    $('preferences-notice').hidden = dialog.open || !message;
  };
  for (const id of ['language','style','cleanup']) {
    $('settings-' + id).replaceChildren(...[...$(id).children].map(option => option.cloneNode(true)));
  }
  const Audio = window.AudioContext || window.webkitAudioContext;
  const microphone = new MicrophoneCheck({
    getUserMedia: window.isSecureContext && navigator.mediaDevices?.getUserMedia ? options => navigator.mediaDevices.getUserMedia(options) : null,
    createContext: Audio ? () => new Audio() : null,
    onChange({state, message}) {
      const stopWasFocused = document.activeElement === $('microphone-stop');
      $('microphone-status').textContent = message;
      $('microphone-start').disabled = busy || microphone.busy;
      $('microphone-stop').hidden = !microphone.busy;
      $('microphone-start').textContent = state === 'requesting' ? 'Waiting for microphone…' : 'Test microphone';
      if (stopWasFocused && !microphone.busy && dialog.open) $('microphone-start').focus();
      onMicrophoneBusy(microphone.busy);
    },
    onLevel: value => {$('microphone-level').value = value; onMicrophoneLevel(value);}
  });
  function render() {
    const value = preferences.value;
    for (const id of ['language','style','cleanup']) {$(id).value = $('settings-' + id).value = value[id];}
    $('style').disabled = $('settings-style').disabled = !value.language.startsWith('en') || value.cleanup === 'none';
    $('cleanup-hint').textContent = value.cleanup === 'none'
      ? 'None keeps the transcript as received, including fillers and spoken punctuation. Writing styles, dictionary corrections and snippets are skipped.'
      : value.cleanup === 'medium'
        ? 'Medium applies Light cleanup and shortens three common English phrases, such as “in order to” to “to”. It does not rewrite whole sentences.'
        : 'Light removes common English fillers and repeated words, adds punctuation and applies your writing style. This is the default.';
    $('settings-cleanup-hint').textContent = $('cleanup-hint').textContent;
    $('practice-submit').textContent = value.cleanup === 'none' ? 'Use raw text' : 'Clean up text';
    $('shortcut-enabled').checked = value.enabled;
    $('shortcut-activation').value = value.activation;
    $('shortcut-capture').value = shortcutLabel(value);
    $('shortcut-current').textContent = value.enabled ? shortcutLabel(value) : 'Disabled';
    $('shortcut-change').disabled = $('shortcut-activation').disabled = !value.enabled;
    $('remember-settings').checked = preferences.remember;
    $('settings-storage-hint').textContent = preferences.remember ? 'Settings are saved in this browser profile.' : 'Settings apply only to this page. Enable remembering to keep them after reload.';
    $('shortcut').textContent = value.enabled ? `${shortcutLabel(value)} ${value.activation === 'hold' ? '— hold to talk, release to finish' : 'to start or stop'} · Esc to cancel. Shortcuts work while this page is focused.` : 'Keyboard shortcut disabled. Use Start dictating; Esc cancels an active dictation.';
    if (value.enabled) $('record').setAttribute('aria-keyshortcuts', `Control+Alt+${value.shift ? 'Shift+' : ''}${value.shortcut.replace(/^(Key|Digit)/, '')}`);
    else $('record').removeAttribute('aria-keyshortcuts');
  }
  function act(action, success) {
    try {action(); if (success) say(success);}
    catch (error) {say(error.message);}
    render();
  }
  for (const id of ['language','style','cleanup']) {
    for (const control of [$(id), $('settings-' + id)]) {
      control.addEventListener('change', () => act(() => preferences.update({[id]:control.value}), 'Settings updated.'));
    }
  }
  $('shortcut-enabled').addEventListener('change', () => act(() => preferences.update({enabled:$('shortcut-enabled').checked}), 'Shortcut updated.'));
  $('shortcut-activation').addEventListener('change', () => act(() => preferences.update({activation:$('shortcut-activation').value}), 'Shortcut updated.'));
  $('shortcut-change').addEventListener('click', () => {
    capturing = true; $('shortcut-capture').hidden = false; $('shortcut-capture').value = '';
    $('shortcut-capture').focus(); say('Press Ctrl + Alt with a letter, number or Space. Shift is optional. Esc cancels.');
  });
  function stopCapture() {capturing = false; $('shortcut-capture').hidden = true;}
  $('shortcut-capture').addEventListener('keydown', event => {
    if (!capturing) return;
    if (event.key === 'Tab') {capturing = false; say('Shortcut change cancelled.'); return;}
    event.preventDefault(); event.stopPropagation();
    if (event.key === 'Escape') {stopCapture(); $('shortcut-change').focus(); say('Shortcut change cancelled.'); return;}
    if (event.repeat || event.isComposing || event.getModifierState?.('AltGraph') || !event.ctrlKey || !event.altKey || event.metaKey || !/^(Space|Key[A-Z]|Digit[0-9])$/.test(event.code)) return;
    act(() => preferences.update({shortcut:event.code, shift:event.shiftKey}), 'Shortcut saved.');
    stopCapture(); $('shortcut-change').focus();
  });
  $('shortcut-capture').addEventListener('blur', stopCapture);
  $('remember-settings').addEventListener('change', () => act(() => preferences.setRemember($('remember-settings').checked), 'Storage preference updated.'));
  $('settings-reload').addEventListener('click', () => act(() => preferences.load(), 'Saved settings reloaded.'));
  $('settings-reset').addEventListener('click', () => act(() => preferences.reset(), 'Default settings restored. Saved settings removed; history and library are unchanged.'));
  function openTo(id = 'settings-close') {
    if (busy) return false;
    if (!dialog.open) dialog.showModal();
    $('preferences-notice').hidden = true; $(id).focus(); return true;
  }
  $('open-settings').addEventListener('click', () => openTo());
  $('settings-close').addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => {stopCapture(); if (microphone.busy) microphone.stop();});
  $('microphone-start').addEventListener('click', () => {if (!busy) void microphone.start();});
  $('microphone-stop').addEventListener('click', () => microphone.stop());
  addEventListener('pagehide', () => {if (microphone.busy) microphone.stop();});
  document.addEventListener('visibilitychange', () => {if (document.hidden && microphone.busy) microphone.stop();});
  addEventListener('storage', event => {
    if (event.storageArea === storage && (event.key === PREFERENCES_KEY || event.key === null)) say('Settings changed in another tab. Reload saved settings to use them here.');
  });
  act(() => preferences.load());
  return {
    preferences, microphone, openTo,
    get open() {return dialog.open;},
    setBusy(value) {
      busy = value;
      $('open-settings').disabled = $('settings-fields').disabled = value;
      $('microphone-start').disabled = value || microphone.busy;
    }
  };
}
