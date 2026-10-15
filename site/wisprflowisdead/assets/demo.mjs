import {Dictation} from './dictation.mjs';
import {polishWithLibrary} from './library.mjs';
import {mountLibrary} from './library-ui.mjs';
import {mountHistory} from './history-ui.mjs';
import {mountSettings} from './settings-ui.mjs';
import {Shortcut} from './preferences.mjs';
import {mountOnboarding} from './onboarding-ui.mjs';
import {captureCommand, transformText, applyCommand} from './commands.mjs';

const $ = id => document.getElementById(id);
const editor = $('editor');
const tabs = [...document.querySelectorAll('[data-mode]')];
const contexts = {
  prompt: ['Give your next idea some detail.', 'Describe what you want to create, the audience, and the details that matter.'],
  message: ['Say what you want to send.', 'A quick update, a plan for the weekend, or a thought for a friend.'],
  list: ['Get the list out of your head.', 'Say “new bullet” between items, or “new paragraph” to start a new section.'],
  email: ['Start with what you mean.', 'Dictate a greeting, your message, and a sign-off. Say “new paragraph” to separate them.']
};
const drafts = new Map();
const library = mountLibrary();
const history = mountHistory({restore:restoreHistory});
let mode = 'prompt', action = 'dictation', insertion = null, undoValue = null, applied = false, source = 'dictation';
const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
const states = {idle:'Ready when you are.', requesting:'Allow microphone access in your browser to begin.', listening:'Listening…', transcribing:'Transcribing…', polishing:'Polishing…', result:'Ready to use. Review your text, then copy it.'};
const machine = new Dictation({
  createRecognition: Recognition && window.isSecureContext ? () => new Recognition() : null,
  polish: (text, options) => options.action === 'command' ? transformText(text, options) : polishWithLibrary(text, options),
  onChange: render
});
let onboarding;
const settings = mountSettings({onMicrophoneLevel:value => onboarding?.microphoneLevel(value), onMicrophoneBusy:busy => {
  $('record').disabled = busy || ['requesting','transcribing','polishing'].includes(machine.state) || !machine.createRecognition;
}});
const keyboard = new Shortcut({preferences:() => settings.preferences.value, start:startRecording, stop:() => machine.stop(), toggle:record,
  allowed:() => !settings.open && !settings.microphone.busy});
onboarding = mountOnboarding({settings, start:() => {setAction('dictation'); return startRecording();}, canDictate:() => Boolean(machine.createRecognition)});

function options(nextAction = action) { return {action:nextAction, target:insertion?.target, language:$('language').value, style:$('style').value, cleanup:$('cleanup').value, entries:library.entries.map(entry => ({...entry}))}; }
function counts() {
  const words = editor.value.trim().split(/\s+/).filter(Boolean).length;
  $('word-count').textContent = `${words} ${words === 1 ? 'word' : 'words'}`;
  $('copy').disabled = $('clear').disabled = machine.busy || !editor.value.trim();
  $('undo').disabled = machine.busy || undoValue === null;
  $('command-target').textContent = editor.selectionStart !== editor.selectionEnd
    ? `Command will replace the selected ${editor.selectionEnd - editor.selectionStart} characters.`
    : 'No selection: command will replace all text in this editor.';
}
function captureInsertion(replace = false) {
  if (action === 'command' && !replace) {
    try {insertion = captureCommand(editor.value, editor.selectionStart, editor.selectionEnd);}
    catch (error) {$('state').dataset.state = 'error'; $('state').textContent = error.message; return false;}
    source = 'command'; applied = false; return true;
  }
  source = replace ? 'practice' : 'dictation';
  insertion = {text:editor.value, start:replace ? 0 : editor.selectionStart, end:replace ? editor.value.length : editor.selectionEnd};
  applied = false;
  return true;
}
function insert(text) {
  const before = insertion.text.slice(0, insertion.start), after = insertion.text.slice(insertion.end);
  const leading = before && !/\s$/.test(before) && !/^[\s,.!?;:]/.test(text) ? ' ' : '';
  const trailing = after && !/^\s|^[,.!?;:]/.test(after) && !/\s$/.test(text) ? ' ' : '';
  return before + leading + text + trailing + after;
}
function render(snapshot) {
  const busy = machine.busy;
  history.setBusy(busy);
  settings.setBusy(busy);
  onboarding.setBusy(busy);
  if (machine.options?.action !== 'command') onboarding.result(snapshot);
  if (!busy) keyboard.reset();
  $('options').disabled = busy;
  tabs.forEach(tab => {tab.disabled = busy;});
  editor.readOnly = busy;
  $('practice-submit').disabled = busy;
  $('command-mode').disabled = busy;
  $('command-submit').disabled = busy;
  $('command-input').disabled = busy;
  $('cancel').hidden = !busy;
  $('record').disabled = settings.microphone.busy || ['requesting','transcribing','polishing'].includes(snapshot.state) || !machine.createRecognition;
  $('record').dataset.state = snapshot.state;
  $('record').setAttribute('aria-pressed', String(snapshot.state === 'listening'));
  const commanding = action === 'command';
  $('record-label').textContent = ({requesting:'Waiting for microphone…',listening:commanding ? 'Run command' : 'Stop dictating',transcribing:'Transcribing…',polishing:commanding ? 'Applying command…' : 'Polishing…'})[snapshot.state] || (commanding ? 'Speak a command' : 'Start dictating');
  $('state').dataset.state = snapshot.state;
  $('state').textContent = snapshot.message || (commanding && ({idle:'Select text, then speak or type a supported command.',listening:'Listening for your command…',polishing:'Applying command…',result:'Command applied. Review the change or choose Undo edit.'})[snapshot.state]) || states[snapshot.state];
  $('draft').hidden = !snapshot.raw && !snapshot.interim;
  $('live-transcript').textContent = [snapshot.raw, snapshot.interim].filter(Boolean).join(' ');
  $('recover').hidden = snapshot.state !== 'error' || (!snapshot.raw && !snapshot.interim);
  if (snapshot.state === 'result' && !applied && insertion) {
    const command = machine.options.action === 'command';
    const edited = command ? applyCommand(insertion, snapshot.result) : null;
    undoValue = command ? insertion.text : insert(snapshot.raw);
    editor.value = command ? edited.value : insert(snapshot.result);
    applied = true;
    drafts.set(mode, editor.value);
    history.record({raw:command ? insertion.target : snapshot.raw, text:snapshot.result, instruction:command ? snapshot.raw : undefined,
      context:mode, source, language:machine.options.language, style:machine.options.style});
    editor.focus();
    editor.setSelectionRange(edited?.start ?? editor.value.length, edited?.end ?? editor.value.length);
  }
  counts();
}
function startRecording() {
  if (machine.busy || settings.microphone.busy) return false;
  if (!captureInsertion()) return false;
  return machine.start(options());
}
function record() {
  if (machine.state === 'listening') return machine.stop();
  return startRecording();
}
$('record').addEventListener('click', record);
$('cancel').addEventListener('click', () => machine.cancel());
$('practice-submit').addEventListener('click', () => {
  if (machine.busy || settings.microphone.busy) return;
  setAction('dictation'); captureInsertion(true); void machine.practice($('practice-input').value, options());
});
function setAction(next) {
  if (machine.busy) return;
  action = next;
  $('command-mode').setAttribute('aria-pressed', String(action === 'command'));
  $('command-panel').hidden = action !== 'command';
  machine.cancel();
  $('state').textContent = action === 'command' ? 'Select text, then speak or type a supported command.' : states.idle;
}
$('command-mode').addEventListener('click', () => setAction(action === 'command' ? 'dictation' : 'command'));
$('command-form').addEventListener('submit', event => {
  event.preventDefault();
  if (action !== 'command' || machine.busy || settings.microphone.busy || !captureInsertion()) return;
  void machine.practice($('command-input').value, options());
});
editor.addEventListener('select', counts);
$('recover').addEventListener('click', () => {
  if (machine.options?.action === 'command') {
    $('command-input').value = [machine.raw, machine.interim].filter(Boolean).join(' ');
    $('command-input').focus(); return;
  }
  $('practice-input').value = [machine.raw, machine.interim].filter(Boolean).join(' ');
  document.querySelector('.practice').open = true;
  $('practice-input').focus();
});
$('copy').addEventListener('click', async () => {
  try { await navigator.clipboard.writeText(editor.value); $('state').textContent = 'Copied to clipboard.'; }
  catch { editor.focus(); editor.select(); $('state').textContent = 'Clipboard access is unavailable. Your text is selected; press Copy on your keyboard or device.'; }
});
$('undo').addEventListener('click', () => {
  editor.value = undoValue; undoValue = null; drafts.set(mode, editor.value); counts();
  $('state').textContent = 'Original words restored. You can edit them here.';
});
$('clear').addEventListener('click', () => {
  editor.value = ''; undoValue = null; drafts.set(mode, ''); machine.cancel(); editor.focus();
});
editor.addEventListener('input', () => {undoValue = null; drafts.set(mode, editor.value); counts();});
function selectMode(tab) {
  if (machine.busy) return;
  drafts.set(mode, editor.value); mode = tab.dataset.mode; undoValue = null;
  tabs.forEach(item => {item.setAttribute('aria-selected', String(item === tab)); item.tabIndex = item === tab ? 0 : -1;});
  $('workspace').setAttribute('aria-labelledby', tab.id);
  [$('context-title').textContent, $('context-hint').textContent] = contexts[mode];
  editor.value = drafts.get(mode) || '';
  machine.cancel();
}
function restoreHistory(entry, text) {
  if (machine.busy) return;
  const previous = entry.context === mode ? editor.value : drafts.get(entry.context) || '';
  if (previous.trim() && previous !== text && !confirm('Replace the draft in this writing context with the history result?')) return;
  selectMode(tabs.find(tab => tab.dataset.mode === entry.context));
  editor.value = text; undoValue = null; drafts.set(mode, text); counts();
  editor.focus(); editor.setSelectionRange(text.length, text.length);
  $('state').textContent = 'History restored to the editor. Review it before copying.';
}
tabs.forEach((tab,index) => {
  tab.addEventListener('click', () => selectMode(tab));
  tab.addEventListener('keydown', event => {
    const next = ({ArrowRight:(index+1)%tabs.length, ArrowLeft:(index+tabs.length-1)%tabs.length, Home:0, End:tabs.length-1})[event.key];
    if (next === undefined) return;
    event.preventDefault(); selectMode(tabs[next]); tabs[next].focus();
  });
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && machine.busy) {event.preventDefault(); machine.cancel();}
  keyboard.down(event);
});
document.addEventListener('keyup', event => keyboard.up(event));
addEventListener('blur', () => {if (keyboard.held) {keyboard.reset(); if (machine.busy) machine.cancel();}});
addEventListener('pagehide', () => {keyboard.reset(); if (machine.busy) machine.cancel();});
document.addEventListener('visibilitychange', () => {if (document.hidden) {keyboard.reset(); if (machine.busy) machine.cancel();}});
render({state:'idle', message:!machine.createRecognition ? 'Speech recognition is unavailable here. Use typed practice below, or open this page in a supported browser over HTTPS.' : '', raw:'', interim:'', result:''});
