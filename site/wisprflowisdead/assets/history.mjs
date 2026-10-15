export const HISTORY_KEY = 'wisprflowisdead.history.v1';
export const DAY = 24 * 60 * 60 * 1000;
const modes = ['session', 'day', 'forever', 'off'];
const contexts = ['prompt', 'message', 'list', 'email'];

function validate(entry) {
  if (!entry || typeof entry.id !== 'string' || !entry.id || entry.id.length > 100
    || !Number.isSafeInteger(entry.createdAt) || entry.createdAt < 0 || entry.createdAt > 8640000000000000
    || !contexts.includes(entry.context) || !['dictation','practice'].includes(entry.source)
    || typeof entry.language !== 'string' || entry.language.length > 40
    || !['formal','casual','very-casual','excited'].includes(entry.style)
    || typeof entry.raw !== 'string' || !entry.raw.trim() || entry.raw.length > 200000
    || typeof entry.text !== 'string' || !entry.text.trim() || entry.text.length > 200000) {
    throw Error('This result cannot be added to history. Keep a copy in your editor.');
  }
  return {id:entry.id, createdAt:entry.createdAt, context:entry.context, source:entry.source,
    language:entry.language, style:entry.style, raw:entry.raw, text:entry.text};
}

export class History {
  constructor({storage, now = Date.now, id = () => crypto.randomUUID()} = {}) {
    Object.assign(this, {storage, now, id});
    this.entries = []; this.mode = 'session'; this.saved = null; this.corrupt = false;
  }
  visible(entries = this.entries, mode = this.mode) {
    return mode === 'off' ? [] : mode === 'day' ? entries.filter(entry => entry.createdAt > this.now() - DAY) : entries;
  }
  load() {
    let saved;
    try { saved = this.storage?.getItem(HISTORY_KEY) ?? null; }
    catch { throw Error('Saved history cannot be read. Keep results in the editor, check browser storage and reload history.'); }
    if (saved === null) {
      this.entries = []; this.mode = 'session'; this.saved = null; this.corrupt = false;
      return;
    }
    let data, entries;
    try {
      if (saved.length > 4000000) throw Error();
      data = JSON.parse(saved);
      if (data.version !== 1 || !['day','forever','off'].includes(data.mode) || !Array.isArray(data.entries) || data.entries.length > 200) throw Error();
      entries = data.entries.map(validate);
      if (new Set(entries.map(entry => entry.id)).size !== entries.length || (data.mode === 'off' && entries.length)) throw Error();
    } catch {
      this.corrupt = true;
      throw Error('Saved history could not be read and has not been overwritten. Clear history to start again.');
    }
    this.saved = saved; this.mode = data.mode; this.entries = this.visible(entries, data.mode); this.corrupt = false;
    // Expired text stays out of the UI even when deleting its saved copy fails.
    if (this.entries.length !== entries.length) this.persist(this.mode, this.entries);
  }
  persist(mode, entries, overwrite = false) {
    if (!this.storage) throw Error('Browser storage is unavailable. Use page-only history.');
    if (this.corrupt && !overwrite) throw Error('Clear unreadable history before saving new results.');
    let current;
    try { current = this.storage.getItem(HISTORY_KEY); }
    catch { throw Error('History storage cannot be read. Your result remains in the editor.'); }
    if (!overwrite && current !== this.saved) throw Error('History changed in another tab. Reload history before saving.');
    const saved = JSON.stringify({version:1, mode, entries});
    if (saved.length > 4000000) throw Error('History storage is full. Copy or delete older results before saving more.');
    try {this.storage.setItem(HISTORY_KEY, saved);}
    catch {throw Error('History could not be saved. Check storage permissions or space. Your result remains in the editor.');}
    this.saved = saved; this.corrupt = false;
  }
  setMode(mode) {
    if (!modes.includes(mode)) throw Error('Choose a history setting.');
    const entries = this.visible(this.entries, mode);
    if (mode === 'session') {
      try {this.storage?.removeItem(HISTORY_KEY);}
      catch {throw Error('The saved copy could not be removed. The previous history setting is still active.');}
      this.saved = null; this.corrupt = false;
    } else {
      // Turning history off explicitly discards all history and remembers only that preference.
      this.persist(mode, entries, mode === 'off');
    }
    this.entries = entries; this.mode = mode;
  }
  commit(entries) {
    if (this.mode !== 'session') this.persist(this.mode, entries);
    this.entries = entries;
  }
  add(result) {
    if (this.mode === 'off') return null;
    const entries = this.visible();
    if (entries.length >= 200) throw Error('History holds up to 200 results. Delete older results before saving more; this result remains in the editor.');
    const entry = validate({...result, id:this.id(), createdAt:this.now()});
    if (entries.some(item => item.id === entry.id)) throw Error('Could not create a unique history entry. Your result remains in the editor.');
    this.commit([entry, ...entries]);
    return entry;
  }
  remove(id) {this.commit(this.visible().filter(entry => entry.id !== id));}
  prune() {
    if (this.mode !== 'day') return false;
    const entries = this.visible();
    // Retry a failed purge even if a previous load already hid expired entries.
    const savedEntries = this.saved ? JSON.parse(this.saved).entries : [];
    if (entries.length === this.entries.length && savedEntries.length === entries.length) return false;
    this.persist(this.mode, entries); this.entries = entries; return true;
  }
  clear() {
    if (this.corrupt || this.mode === 'session') {
      try {this.storage?.removeItem(HISTORY_KEY);}
      catch {throw Error('Saved history could not be deleted. Check browser storage and retry.');}
      this.saved = null; this.corrupt = false; this.mode = 'session'; this.entries = [];
    } else this.commit([]);
  }
  list(query = '') {
    const term = query.trim().toLocaleLowerCase();
    return this.visible().filter(entry => !term || (entry.text + '\n' + entry.raw).toLocaleLowerCase().includes(term))
      .slice().sort((a, b) => b.createdAt - a.createdAt);
  }
}
