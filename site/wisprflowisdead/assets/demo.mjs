import {Dictation} from './dictation.mjs';
import {polishWithLibrary} from './library.mjs';
import {mountLibrary} from './library-ui.mjs';

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
let mode = 'prompt', insertion = null, undoValue = null, applied = false;
const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
const states = {idle:'Ready when you are.', requesting:'Allow microphone access in your browser to begin.', listening:'Listening…', transcribing:'Transcribing…', polishing:'Polishing…', result:'Ready to use. Review your text, then copy it.'};
const machine = new Dictation({
  createRecognition: Recognition && window.isSecureContext ? () => new Recognition() : null,
  polish: polishWithLibrary,
  onChange: render
});

function options() { return {language:$('language').value, style:$('style').value, entries:library.entries.map(entry => ({...entry}))}; }
function counts() {
  const words = editor.value.trim().split(/\s+/).filter(Boolean).length;
  $('word-count').textContent = `${words} ${words === 1 ? 'word' : 'words'}`;
  $('copy').disabled = $('clear').disabled = machine.busy || !editor.value.trim();
  $('undo').disabled = machine.busy || undoValue === null;
}
function captureInsertion(replace = false) {
  insertion = {text:editor.value, start:replace ? 0 : editor.selectionStart, end:replace ? editor.value.length : editor.selectionEnd};
  applied = false;
}
function insert(text) {
  const before = insertion.text.slice(0, insertion.start), after = insertion.text.slice(insertion.end);
  const leading = before && !/\s$/.test(before) && !/^[\s,.!?;:]/.test(text) ? ' ' : '';
  const trailing = after && !/^\s|^[,.!?;:]/.test(after) && !/\s$/.test(text) ? ' ' : '';
  return before + leading + text + trailing + after;
}
function render(snapshot) {
  const busy = machine.busy;
  $('options').disabled = busy;
  tabs.forEach(tab => {tab.disabled = busy;});
  editor.readOnly = busy;
  $('practice-submit').disabled = busy;
  $('cancel').hidden = !busy;
  $('record').disabled = ['requesting','transcribing','polishing'].includes(snapshot.state) || !machine.createRecognition;
  $('record').dataset.state = snapshot.state;
  $('record').setAttribute('aria-pressed', String(snapshot.state === 'listening'));
  $('record-label').textContent = ({requesting:'Waiting for microphone…',listening:'Stop dictating',transcribing:'Transcribing…',polishing:'Polishing…'})[snapshot.state] || 'Start dictating';
  $('state').dataset.state = snapshot.state;
  $('state').textContent = snapshot.message || states[snapshot.state];
  $('draft').hidden = !snapshot.raw && !snapshot.interim;
  $('live-transcript').textContent = [snapshot.raw, snapshot.interim].filter(Boolean).join(' ');
  $('recover').hidden = snapshot.state !== 'error' || (!snapshot.raw && !snapshot.interim);
  if (snapshot.state === 'result' && !applied && insertion) {
    undoValue = insert(snapshot.raw);
    editor.value = insert(snapshot.result);
    applied = true;
    drafts.set(mode, editor.value);
    editor.focus();
    editor.setSelectionRange(editor.value.length, editor.value.length);
  }
  counts();
}
function record() {
  if (machine.state === 'listening') return machine.stop();
  if (machine.busy) return;
  captureInsertion(); machine.start(options());
}
$('record').addEventListener('click', record);
$('cancel').addEventListener('click', () => machine.cancel());
$('practice-submit').addEventListener('click', () => {
  captureInsertion(true); void machine.practice($('practice-input').value, options());
});
$('recover').addEventListener('click', () => {
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
  if (event.code === 'Space' && event.ctrlKey && event.altKey && !event.metaKey && !event.shiftKey && !event.repeat && !event.isComposing) {event.preventDefault(); record();}
});
addEventListener('pagehide', () => {if (machine.busy) machine.cancel();});
document.addEventListener('visibilitychange', () => {if (document.hidden && machine.busy) machine.cancel();});
$('language').addEventListener('change', () => {$('style').disabled = !$('language').value.startsWith('en');});
render({state:'idle', message:!machine.createRecognition ? 'Speech recognition is unavailable here. Use typed practice below, or open this page in a supported browser over HTTPS.' : '', raw:'', interim:'', result:''});
