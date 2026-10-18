import {Library, LIBRARY_KEY} from './library.mjs';

export function mountLibrary() {
  const $ = id => document.getElementById(id);
  let storage;
  try {storage = window.localStorage;} catch { /* Private/restricted storage: page-only mode. */ }
  const library = new Library({storage});
  let kind = 'dictionary', editing = null;
  const tabs = [...document.querySelectorAll('[data-library-kind]')];
  const say = (text, error = false) => {$('library-status').textContent = text; $('library-status').classList.toggle('error', error);};
  const act = action => {
    try {action(); render(); return true;}
    catch (error) {say(error.message || 'The library could not be updated. Try again.', true); return false;}
  };
  function resetForm() {
    editing = null; $('entry-form').reset(); $('entry-form').hidden = true;
    $('add-entry').focus();
  }
  function fields() {
    const dictionary = kind === 'dictionary';
    $('entry-heading').textContent = (editing ? 'Edit ' : 'Add ') + (dictionary ? 'word' : 'snippet');
    $('primary-label').textContent = dictionary ? 'Preferred spelling' : 'Spoken phrase';
    $('primary').maxLength = 60;
    $('correction-row').hidden = !dictionary;
    $('wrong-row').hidden = !dictionary || !$('correction').checked;
    $('wrong').required = dictionary && $('correction').checked;
    $('wrong').disabled = !$('wrong').required;
    $('expansion-row').hidden = dictionary;
    $('expansion').required = !dictionary;
    $('expansion').disabled = dictionary;
    $('expansion-count').textContent = `${$('expansion').value.length} / 4,000 characters`;
    $('save-entry').textContent = editing ? 'Save changes' : dictionary ? 'Add word' : 'Add snippet';
  }
  function openForm(entry = null) {
    editing = entry ? {...entry} : null;
    $('entry-form').reset();
    $('primary').value = entry ? kind === 'dictionary' ? entry.value : entry.trigger : '';
    $('correction').checked = Boolean(entry && kind === 'dictionary' && entry.trigger !== entry.value);
    $('wrong').value = entry?.trigger || '';
    $('expansion').value = entry && kind === 'snippet' ? entry.value : '';
    $('entry-form').hidden = false; fields(); $('primary').focus(); say('');
  }
  function button(label, action) {
    const item = document.createElement('button'); item.type = 'button'; item.textContent = label;
    item.addEventListener('click', action); return item;
  }
  function render() {
    const focusedEntry = document.activeElement?.dataset.entryId;
    const focusedAction = document.activeElement?.dataset.action;
    $('remember-library').checked = library.remember;
    $('library-storage').textContent = library.remember ? 'Saved in this browser profile. Anyone using this profile can access these entries.' : 'Entries last until you close or reload this page. Enable saving to keep them in this browser profile.';
    tabs.forEach(tab => {const selected = tab.dataset.libraryKind === kind; tab.setAttribute('aria-selected', String(selected)); tab.tabIndex = selected ? 0 : -1;});
    $('library-panel').setAttribute('aria-labelledby', `library-${kind}`);
    $('starred-sort').hidden = kind !== 'dictionary';
    $('library-sort').value = kind === 'snippet' && library.sort === 'starred' ? '' : library.sort;
    $('add-entry').textContent = kind === 'dictionary' ? 'Add word' : 'Add snippet';
    $('library-help').textContent = kind === 'dictionary' ? 'Keep preferred spellings and replace recurring mistakes after recognition. These rules do not train your browser’s speech service.' : 'Speak a phrase to insert saved text. Expansions preserve their casing and line breaks. Choose a distinctive phrase.';
    const entries = library.list(kind, $('library-search').value);
    const list = $('entry-list'); list.replaceChildren();
    $('library-empty').hidden = entries.length > 0;
    $('library-empty').textContent = library.entries.some(entry => entry.kind === kind) ? 'No matching entries. Try another search.' : `No ${kind === 'dictionary' ? 'words' : 'snippets'} yet. Add your first one to try it.`;
    for (const entry of entries) {
      const row = document.createElement('li'), content = document.createElement('div'), title = document.createElement('strong'), value = document.createElement('p'), actions = document.createElement('div');
      title.textContent = entry.trigger; value.textContent = entry.value; content.append(title, value);
      actions.className = 'entry-actions';
      if (kind === 'dictionary') {
        const star = button(entry.starred ? 'Unstar' : 'Star', () => act(() => {library.save({...entry, starred:!entry.starred}, entry.updatedAt); say(entry.starred ? 'Word unstarred.' : 'Word starred.');}));
        star.setAttribute('aria-pressed', String(entry.starred)); actions.append(star);
      }
      actions.append(button('Edit', () => openForm(entry)), button('Delete', () => {
        if (!confirm(`Delete “${entry.trigger}” from your ${kind === 'dictionary' ? 'dictionary' : 'snippets'}?`)) return;
        act(() => {library.remove(entry.id); if (editing?.id === entry.id) resetForm(); say('Entry deleted.');});
      }));
      actions.querySelectorAll('button').forEach(item => {item.dataset.entryId = entry.id; item.dataset.action = /star/i.test(item.textContent) ? 'star' : item.textContent;});
      row.append(content, actions); list.append(row);
    }
    if (focusedEntry) {
      const next = [...list.querySelectorAll('button')].find(item => item.dataset.entryId === focusedEntry && item.dataset.action === focusedAction);
      (next || $('add-entry')).focus();
    }
  }
  tabs.forEach((tab,index) => {
    const select = target => {
      kind = target.dataset.libraryKind;
      resetForm(); render(); target.focus();
    };
    tab.addEventListener('click', () => select(tab));
    tab.addEventListener('keydown', event => {
      if (!['ArrowLeft','ArrowRight','Home','End'].includes(event.key)) return;
      event.preventDefault(); select(tabs[event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length-1 : (index+1)%tabs.length]);
    });
  });
  $('add-entry').addEventListener('click', () => openForm());
  $('cancel-entry').addEventListener('click', resetForm);
  $('correction').addEventListener('change', fields);
  $('expansion').addEventListener('input', fields);
  $('entry-form').addEventListener('submit', event => {
    event.preventDefault(); if (!$('entry-form').reportValidity()) return;
    const entry = {id:editing?.id, kind, starred:editing?.starred,
      trigger:kind === 'dictionary' && $('correction').checked ? $('wrong').value : $('primary').value,
      value:kind === 'dictionary' ? $('primary').value : $('expansion').value};
    const edited = Boolean(editing);
    act(() => {library.save(entry, editing?.updatedAt); globalThis.isdeadAnalytics?.track('app_library_entry_saved', {kind, edited}); resetForm(); say(library.remember ? 'Entry saved in this browser.' : 'Entry added for this page.');});
  });
  $('entry-form').addEventListener('keydown', event => {
    if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {event.preventDefault(); $('entry-form').requestSubmit();}
    if (event.key === 'Escape') {event.preventDefault(); resetForm();}
  });
  $('library-search').addEventListener('input', render);
  $('library-sort').addEventListener('change', () => {
    if (!act(() => library.setSort($('library-sort').value))) render();
  });
  $('remember-library').addEventListener('change', () => {
    act(() => {library.setRemember($('remember-library').checked); say(library.remember ? 'This library will stay in this browser.' : 'Saved copy removed. Current entries remain available until you close this page.');});
    $('remember-library').checked = library.remember;
  });
  $('clear-library').addEventListener('click', () => {
    if (!confirm('Delete all dictionary and snippet entries from this page and this browser’s saved library?')) return;
    act(() => {library.clear(); resetForm(); say('Library cleared.');});
  });
  $('reload-library').addEventListener('click', () => {
    if (!$('entry-form').hidden && !confirm('Discard the open entry form and reload saved entries?')) return;
    if (!library.remember && library.entries.length && !confirm('Replace this page’s unsaved entries with the saved library?')) return;
    act(() => {library.load(); resetForm(); say('Saved library loaded.');});
  });
  addEventListener('storage', event => {
    if (event.key === LIBRARY_KEY || event.key === null) say('The saved library changed in another tab. Reload its latest entries before editing.', true);
  });
  act(() => library.load()); render();
  return library;
}
