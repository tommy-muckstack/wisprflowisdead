import {History, HISTORY_KEY} from './history.mjs';

export function mountHistory({restore}) {
  const $ = id => document.getElementById(id);
  let storage, busy = false, pending = null, timer;
  try {storage = window.localStorage;} catch { /* Page-only history still works. */ }
  const history = new History({storage});
  const expanded = new Set();
  const status = message => {$('history-status').textContent = message;};
  const hints = {
    session:'Results stay in this page until you close or reload it. Nothing is saved to browser storage.',
    day:'Text is saved in this browser profile. Results older than 24 hours are deleted when this page opens and while it is open; deletion cannot run while it is closed.',
    forever:'Text is saved in this browser profile until you delete it. Anyone using this profile can read it.',
    off:'History is disabled. Only this preference is remembered; new results are not added to history.'
  };
  function node(tag, text, className) {
    const element = document.createElement(tag);
    if (text !== undefined) element.textContent = text;
    if (className) element.className = className;
    return element;
  }
  function render() {
    const active = document.activeElement;
    const focusId = active?.dataset.historyId, focusAction = active?.dataset.action;
    const entries = history.list($('history-search').value);
    $('history-mode').value = history.mode;
    $('history-storage-hint').textContent = hints[history.mode];
    $('history-empty').textContent = history.mode === 'off' ? 'History disabled.'
      : history.corrupt ? 'Saved history needs attention. It has not been overwritten.'
      : $('history-search').value.trim() ? 'No results match your search.' : 'No results yet. Dictate or use typed practice to begin.';
    $('history-empty').hidden = entries.length > 0;
    $('history-count').textContent = `${entries.length} ${entries.length === 1 ? 'result' : 'results'}`;
    $('history-retry').hidden = !pending;
    const list = $('history-list'); list.replaceChildren();
    for (const entry of entries) {
      const item = node('li');
      const date = node('time', new Date(entry.createdAt).toLocaleString());
      date.dateTime = new Date(entry.createdAt).toISOString();
      const meta = node('p', `${entry.source === 'practice' ? 'Typed practice' : 'Dictation'} · ${entry.language} · `, 'history-meta');
      meta.append(date);
      const preview = node('p', entry.text.length > 240 ? entry.text.slice(0, 240) + '…' : entry.text, 'history-preview');
      const details = node('details'), summary = node('summary', 'View result and original');
      summary.dataset.historyId = entry.id; summary.dataset.action = 'view';
      details.append(summary);
      const full = node('div'); details.append(full);
      details.addEventListener('toggle', () => {
        if (details.open) expanded.add(entry.id); else expanded.delete(entry.id);
        if (details.open && !full.childNodes.length) {
          full.append(node('h3', 'Result'), node('pre', entry.text), node('h3', 'Original words'), node('pre', entry.raw));
        }
      });
      details.open = expanded.has(entry.id);
      const actions = node('div', undefined, 'history-actions');
      function button(label, action, handler) {
        const button = node('button', label); button.type = 'button';
        button.dataset.historyId = entry.id; button.dataset.action = action;
        if (action.startsWith('restore')) button.disabled = busy;
        button.addEventListener('click', handler); actions.append(button);
      }
      button('Copy', 'copy', async () => {
        try {await navigator.clipboard.writeText(entry.text); status('Copied result.');}
        catch {details.open = true; status('Clipboard access is unavailable. Select the result under “View result and original” and copy it manually.');}
      });
      button('Restore result', 'restore', () => {if (!busy) restore(entry, entry.text);});
      button('Restore original', 'restore-raw', () => {if (!busy) restore(entry, entry.raw);});
      button('Delete', 'delete', () => {
        if (!confirm('Delete this result and its original words from history? This cannot be undone.')) return;
        try {history.remove(entry.id); expanded.delete(entry.id); render(); $('history-search').focus(); status('Result deleted.');}
        catch (error) {status(error.message);}
      });
      item.append(meta, preview, details, actions); list.append(item);
    }
    if (focusId) {
      [...list.querySelectorAll('[data-history-id]')].find(button => button.dataset.historyId === focusId && button.dataset.action === focusAction)?.focus();
    }
  }
  function reload(announce = true) {
    let ok = false;
    try {history.load(); ok = true; if (announce) status('Saved history reloaded.');}
    catch (error) {status(error.message);}
    render(); return ok;
  }
  $('history-mode').addEventListener('change', () => {
    const mode = $('history-mode').value;
    if (mode === history.mode) return;
    const prompt = mode === 'off' ? 'Disable history and delete all saved results? Your current editor text is kept.'
      : mode === 'session' ? 'Remove the saved copy and keep history only in this page?'
      : mode === 'day' ? 'Save history in this browser and delete results older than 24 hours?'
      : 'Save history in this browser until you delete it? Anyone using this browser profile can read it.';
    if (!confirm(prompt)) {$('history-mode').value = history.mode; return;}
    try {history.setMode(mode); if (mode === 'off') pending = null; status('History setting updated.');}
    catch (error) {status(error.message);}
    render();
  });
  $('history-clear').addEventListener('click', () => {
    if (!confirm('Delete all history and any result waiting to be saved? Your current editor text, dictionary and snippets are kept.')) return;
    try {history.clear(); pending = null; expanded.clear(); status('History cleared.');}
    catch (error) {status(error.message);}
    render();
  });
  $('history-reload').addEventListener('click', () => {
    if (history.mode === 'session' && history.entries.length && !confirm('Reload saved history and replace the page-only history?')) return;
    reload();
  });
  function record(result) {
    if (history.mode === 'off') return;
    try {history.add(result); pending = null; status(history.mode === 'session' ? 'Result added to page-only history.' : 'Result saved in browser history.');}
    catch (error) {pending = result; status(error.message + ' You can retry saving the latest result.');}
    render();
  }
  $('history-retry').addEventListener('click', () => {if (pending) record(pending);});
  $('history-search').addEventListener('input', render);
  addEventListener('storage', event => {
    if (event.storageArea !== storage || (event.key !== HISTORY_KEY && event.key !== null)) return;
    if (reload(false)) {
      if (history.mode === 'off') pending = null;
      render(); status('History changed in another tab. The latest saved history is now shown.');
    }
  });
  function prune() {
    try {if (history.prune()) render();}
    catch (error) {render(); status('Expired results are hidden, but their saved copy could not be deleted. ' + error.message);}
  }
  function startTimer() {clearInterval(timer); timer = setInterval(prune, 60000);}
  addEventListener('pagehide', () => clearInterval(timer));
  addEventListener('pageshow', () => {
    if (history.mode !== 'session') reload(false);
    prune(); startTimer();
  });
  document.addEventListener('visibilitychange', () => {if (!document.hidden) prune();});
  reload(false); startTimer();
  return {
    record,
    setBusy(value) {
      if (busy === value) return; busy = value;
      $('history-list').querySelectorAll('[data-action^="restore"]').forEach(button => {button.disabled = busy;});
    }
  };
}
