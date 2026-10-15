import {cleanText} from './text.mjs';

export const LIBRARY_KEY = 'wisprflowisdead.library.v1';
const sorts = ['newest', 'oldest', 'alphabetical', 'starred'];
const key = text => text.trim().replace(/\s+/g, ' ').normalize('NFC').toLowerCase();
const standalone = text => key(text).replace(/[^\p{L}\p{N}]/gu, '');
const escaped = text => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function validate(entry) {
  if (!['dictionary','snippet'].includes(entry.kind)) throw Error('Choose Dictionary or Snippets.');
  if (typeof entry.trigger !== 'string' || typeof entry.value !== 'string') throw Error('Enter a phrase and its replacement.');
  const trigger = entry.trigger.trim(), value = entry.kind === 'dictionary' ? entry.value.trim() : entry.value;
  if (!/[\p{L}\p{N}]/u.test(trigger)) throw Error('The spoken phrase needs at least one letter or number.');
  if (trigger.length > 60 || /[\r\n]/.test(trigger)) throw Error('Keep the spoken phrase on one line, up to 60 characters.');
  if (!value.trim()) throw Error('Enter the word or expansion to insert.');
  if (value.length > (entry.kind === 'dictionary' ? 60 : 4000)) throw Error(entry.kind === 'dictionary' ? 'Keep the preferred spelling under 61 characters.' : 'Keep the expansion under 4,001 characters.');
  if (entry.kind === 'dictionary' && (!/[\p{L}\p{N}]/u.test(value) || /[\r\n]/.test(value))) throw Error('Enter a word or phrase on one line.');
  return {kind:entry.kind, trigger, value, starred:entry.kind === 'dictionary' && Boolean(entry.starred)};
}

export class Library {
  constructor({storage, id = () => crypto.randomUUID(), now = Date.now} = {}) {
    Object.assign(this, {storage, id, now});
    this.entries = []; this.sort = 'newest'; this.remember = false; this.corrupt = false; this.saved = null;
  }
  load() {
    let saved;
    try {saved = this.storage?.getItem(LIBRARY_KEY) ?? null;}
    catch {throw Error('Browser storage cannot be read. You can keep working in this page without saving.');}
    if (saved === null) {this.entries = []; this.sort = 'newest'; this.saved = null; this.remember = false; this.corrupt = false; return;}
    try {
      if (saved.length > 5_000_000) throw Error('Too large');
      const data = JSON.parse(saved);
      if (data.version !== 1 || !Array.isArray(data.entries) || data.entries.length > 1000) throw Error('Invalid library');
      const ids = new Set(), triggers = new Set();
      const entries = data.entries.map(entry => {
        const valid = validate(entry);
        if (typeof entry.id !== 'string' || !entry.id || ids.has(entry.id) || triggers.has(key(valid.trigger)) || !Number.isFinite(entry.updatedAt)) throw Error('Invalid entry');
        ids.add(entry.id); triggers.add(key(valid.trigger));
        return {...valid, id:entry.id, updatedAt:entry.updatedAt};
      });
      this.entries = entries; this.sort = sorts.includes(data.sort) ? data.sort : 'newest';
      this.remember = true; this.saved = saved; this.corrupt = false;
    } catch {
      this.corrupt = true;
      throw Error('The saved library could not be read. It has not been overwritten. Clear the library to start again, or keep working without saving.');
    }
  }
  persist(entries, sort = this.sort) {
    if (!this.storage) throw Error('Browser storage is unavailable. Keep the library in this page for now.');
    if (this.corrupt) throw Error('Clear the unreadable saved library before enabling storage.');
    if (this.storage.getItem(LIBRARY_KEY) !== this.saved) throw Error('The library changed in another tab. Reload its latest entries before saving.');
    const data = JSON.stringify({version:1, entries, sort});
    try { this.storage.setItem(LIBRARY_KEY, data); }
    catch { throw Error('The library could not be saved. Check browser storage permissions or available space. Your previous entries are unchanged.'); }
    this.saved = data;
  }
  setRemember(remember) {
    if (remember) this.persist(this.entries);
    else {
      try {this.storage?.removeItem(LIBRARY_KEY);}
      catch {throw Error('Saved entries could not be removed. Check browser storage permissions and retry.');}
      this.saved = null; this.corrupt = false;
    }
    this.remember = remember;
  }
  commit(entries) { if (this.remember) this.persist(entries); this.entries = entries; }
  setSort(sort) {
    if (!sorts.includes(sort)) throw Error('Choose an available sort order.');
    if (sort === this.sort) return;
    if (this.remember) this.persist(this.entries, sort);
    this.sort = sort;
  }
  save(entry, expectedUpdate) {
    const valid = validate(entry), current = this.entries.find(item => item.id === entry.id);
    if (entry.id && !current) throw Error('This entry no longer exists. Cancel editing and add it again.');
    if (current && expectedUpdate !== undefined && current.updatedAt !== expectedUpdate) throw Error('This entry changed in another tab. Cancel editing and reopen the latest version.');
    if (this.entries.some(item => item.id !== entry.id && key(item.trigger) === key(valid.trigger))) throw Error('That spoken phrase is already in your dictionary or snippets. Edit the existing entry instead.');
    if (!current && this.entries.length >= 1000) throw Error('This browser library holds up to 1,000 entries. Delete an entry before adding another.');
    const updated = {...valid, id:current?.id || this.id(), updatedAt:Math.max(this.now(), (current?.updatedAt || 0) + 1)};
    this.commit(current ? this.entries.map(item => item.id === current.id ? updated : item) : [...this.entries, updated]);
    return updated;
  }
  remove(id) { this.commit(this.entries.filter(entry => entry.id !== id)); }
  clear() {
    // Only this feature's key is removed; unrelated IsDead app data is untouched.
    this.setRemember(false); this.entries = []; this.sort = 'newest';
  }
  list(kind, query = '', sort = this.sort) {
    const search = key(query);
    return this.entries.filter(item => item.kind === kind && key(item.trigger+' '+item.value).includes(search)).sort((a,b) => {
      if (sort === 'starred' && a.starred !== b.starred) return Number(b.starred)-Number(a.starred);
      if (sort === 'alphabetical') return a.trigger.localeCompare(b.trigger) || a.value.localeCompare(b.value);
      return sort === 'oldest' ? a.updatedAt-b.updatedAt : b.updatedAt-a.updatedAt;
    });
  }
}

export function polishWithLibrary(input, {entries = [], ...options} = {}) {
  if (options.cleanup === 'none') return String(input);
  let text = String(input).trim();
  if (!text) return '';
  const rules = [...entries].sort((a,b) => b.trigger.length-a.trigger.length);
  const exact = rules.find(entry => entry.kind === 'snippet' && standalone(entry.trigger) === standalone(text));
  if (exact) return exact.value;
  const literals = [], kinds = [];
  const protect = (value, kind = 'literal') => {literals.push(value); kinds.push(kind); return `\uE000${literals.length-1}\uE001`;};
  // Preserve URLs, email addresses, inline code and user-typed marker sequences.
  text = text.replace(/(?:https?:\/\/|www\.)[^\s]+|[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Z0-9-]+(?:\.[A-Z0-9-]+)+|`[^`\n]+`|\uE000\d+\uE001/gi, match => protect(match));
  if (rules.length) {
    const lookup = new Map(rules.map(entry => [key(entry.trigger), entry]));
    const alternatives = rules.map(entry => entry.trigger.split(/[ \t]+/).map(escaped).join('[ \\t]+')).join('|');
    // Whole phrases, longest first. Preserve possessives but leave n't contractions alone.
    const pattern = new RegExp(`(?<![\\p{L}\\p{N}_])(?:${alternatives})(?![\\p{L}\\p{N}_]|['’ʼ]t\\b)`, 'giu');
    text = text.replace(pattern, match => {const entry = lookup.get(key(match)); return protect(entry.value, entry.kind);});
  }
  const ending = text.match(/\uE000(\d+)\uE001$/);
  if (ending && kinds[Number(ending[1])] === 'dictionary' && (options.language || 'en').startsWith('en') && !['casual','very-casual'].includes(options.style) && !/[.!?:;]$/.test(literals[Number(ending[1])])) text += options.style === 'excited' ? '!' : '.';
  return cleanText(text, options).replace(/\uE000(\d+)\uE001/g, (_, index) => literals[Number(index)]);
}
