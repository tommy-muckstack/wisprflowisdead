export const PREFERENCES_KEY = 'wisprflowisdead.preferences.v1';
export const defaults = Object.freeze({language:'en-US', style:'formal', cleanup:'light', shortcut:'Space', shift:false, enabled:true, activation:'toggle'});
const languages = ['en-US','en-GB','es-ES','fr-FR','de-DE','pt-BR','hi-IN','ja-JP'];
export function validatePreferences(value) {
  // Existing version-1 settings predate cleanup levels; retain their behavior.
  if (value && value.cleanup === undefined) value = {...value, cleanup:defaults.cleanup};
  if (!value || !languages.includes(value.language) || !['formal','casual','very-casual','excited'].includes(value.style)
    || !['none','light','medium'].includes(value.cleanup)
    || typeof value.shortcut !== 'string' || !/^(Space|Key[A-Z]|Digit[0-9])$/.test(value.shortcut)
    || typeof value.shift !== 'boolean' || typeof value.enabled !== 'boolean' || !['toggle','hold'].includes(value.activation)) {
    throw Error('These settings are not supported. Reset settings to use the defaults.');
  }
  return Object.fromEntries(Object.keys(defaults).map(key => [key, value[key]]));
}
export function shortcutLabel(value) {
  return `Ctrl + Alt${value.shift ? ' + Shift' : ''} + ${value.shortcut.replace(/^(Key|Digit)/, '')}`;
}
export function shortcutMatches(event, value) {
  return value.enabled && event.code === value.shortcut && event.ctrlKey && event.altKey
    && !event.metaKey && !event.getModifierState?.('AltGraph') && Boolean(event.shiftKey) === value.shift && !event.repeat && !event.isComposing && !event.defaultPrevented;
}
export class Preferences {
  constructor(storage) {this.storage = storage; this.value = {...defaults}; this.remember = false; this.saved = null; this.corrupt = false;}
  load() {
    let saved;
    try {saved = this.storage?.getItem(PREFERENCES_KEY) ?? null;}
    catch {throw Error('Saved settings cannot be read. Defaults are available for this page.');}
    if (saved === null) {this.value = {...defaults}; this.saved = null; this.remember = false; this.corrupt = false; return;}
    try {
      if (saved.length > 5000) throw Error();
      const data = JSON.parse(saved);
      if (data.version !== 1) throw Error();
      this.value = validatePreferences(data.value);
    } catch {this.corrupt = true; throw Error('Saved settings could not be read. They have not been overwritten. Reset settings to replace them.');}
    this.saved = saved; this.remember = true; this.corrupt = false;
  }
  persist(value) {
    if (!this.storage) throw Error('Browser storage is unavailable. Use these settings for this page only.');
    if (this.corrupt) throw Error('Reset unreadable settings before saving.');
    let current;
    try {current = this.storage.getItem(PREFERENCES_KEY);}
    catch {throw Error('Settings storage cannot be read. Your previous settings are unchanged.');}
    if (current !== this.saved) throw Error('Settings changed in another tab. Reload saved settings before saving.');
    const saved = JSON.stringify({version:1, value});
    try {this.storage.setItem(PREFERENCES_KEY, saved);}
    catch {throw Error('Settings could not be saved. Your previous settings are unchanged. Disable remembering to use page-only settings.');}
    this.saved = saved;
  }
  update(patch) {
    const value = validatePreferences({...this.value, ...patch});
    if (this.remember) this.persist(value);
    this.value = value;
  }
  setRemember(remember) {
    if (remember) this.persist(this.value);
    else {
      try {this.storage?.removeItem(PREFERENCES_KEY);}
      catch {throw Error('Saved settings could not be removed. Check browser storage and retry.');}
      this.saved = null; this.corrupt = false;
    }
    this.remember = remember;
  }
  reset() {this.setRemember(false); this.value = {...defaults};}
}

export class Shortcut {
  constructor({preferences, start, stop, toggle, allowed = () => true}) {Object.assign(this, {preferences, start, stop, toggle, allowed}); this.held = null;}
  down(event) {
    const value = this.preferences();
    if (!this.allowed() || !shortcutMatches(event, value) || this.held) return;
    event.preventDefault();
    if (value.activation === 'toggle') this.toggle();
    else if (this.start()) this.held = event.code;
  }
  up(event) {
    if (event.code !== this.held) return;
    event.preventDefault(); this.held = null; this.stop();
  }
  reset() {this.held = null;}
}
