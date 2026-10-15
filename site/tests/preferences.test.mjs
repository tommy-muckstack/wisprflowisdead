import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Preferences, PREFERENCES_KEY, defaults, validatePreferences, shortcutMatches, Shortcut} from '../wisprflowisdead/assets/preferences.mjs';
function setup() {
  const data = new Map(); let failure;
  const storage = {getItem:key => data.get(key) ?? null,
    setItem(key, value) {if (failure === 'write') throw Error(); data.set(key, value);},
    removeItem(key) {if (failure === 'remove') throw Error(); data.delete(key);}};
  return {data, storage, preferences:new Preferences(storage), fail:value => {failure = value;}};
}
const key = patch => ({code:'Space', ctrlKey:true, altKey:true, shiftKey:false, metaKey:false, preventDefault() {this.defaultPrevented = true;}, ...patch});

test('settings are page-only until explicitly remembered and restore after reload', () => {
  const {preferences:p, data, storage} = setup(); p.update({language:'fr-FR', activation:'hold'});
  assert.equal(data.size, 0); p.setRemember(true);
  const next = new Preferences(storage); next.load(); assert.deepEqual(next.value, p.value);
  assert.equal(next.remember, true); next.setRemember(false); assert.equal(data.size, 0);
  assert.equal(next.value.language, 'fr-FR');
});
test('failed saves/deletes preserve active settings and the saved copy', () => {
  const {preferences:p, data, fail} = setup(); p.setRemember(true); const saved = data.get(PREFERENCES_KEY);
  fail('write'); assert.throws(() => p.update({language:'ja-JP'}));
  assert.deepEqual(p.value, defaults); assert.equal(data.get(PREFERENCES_KEY), saved);
  fail('remove'); assert.throws(() => p.setRemember(false)); assert.equal(p.remember, true);
});
test('corrupt settings are not silently overwritten and reset only removes their own key', () => {
  const {preferences:p, data} = setup(); data.set(PREFERENCES_KEY, '{bad'); data.set('history', 'keep');
  assert.throws(() => p.load()); assert.throws(() => p.setRemember(true)); assert.equal(data.get(PREFERENCES_KEY), '{bad');
  p.reset(); assert.equal(data.has(PREFERENCES_KEY), false); assert.equal(data.get('history'), 'keep');
});
test('known cross-tab changes require reload before another saved update', () => {
  const {preferences:p, storage} = setup(); p.setRemember(true);
  const other = new Preferences(storage); other.load(); other.update({shortcut:'KeyD'});
  assert.throws(() => p.update({style:'casual'}), /another tab/);
  p.load(); assert.equal(p.value.shortcut, 'KeyD'); p.update({style:'casual'});
});
test('only supported preference values and shortcuts are accepted', () => {
  for (const patch of [{language:'unknown'}, {style:'unknown'}, {shortcut:'Escape'}, {shortcut:'Control'}, {shift:1}, {enabled:null}, {activation:'always'}]) {
    assert.throws(() => validatePreferences({...defaults, ...patch}));
  }
  assert.deepEqual(validatePreferences({...defaults, unrelated:'ignored'}), defaults);
});
test('shortcuts reject repeats, composition, AltGraph, extra modifiers and disabled settings', () => {
  assert.equal(shortcutMatches(key(), defaults), true);
  for (const patch of [{repeat:true}, {isComposing:true}, {metaKey:true}, {shiftKey:true}, {ctrlKey:false}, {altKey:false}, {code:'KeyD'}, {defaultPrevented:true}, {getModifierState:() => true}]) {
    assert.equal(shortcutMatches(key(patch), defaults), false);
  }
  assert.equal(shortcutMatches(key(), {...defaults, enabled:false}), false);
});
test('hold-to-talk stops on primary-key release even after modifier release and ignores repeats', () => {
  let starts = 0, stops = 0, toggles = 0;
  const shortcut = new Shortcut({preferences:() => ({...defaults, activation:'hold'}), start:() => {starts++; return true;}, stop:() => stops++, toggle:() => toggles++});
  shortcut.down(key()); shortcut.down(key({repeat:true})); shortcut.up(key({code:'AltLeft'}));
  assert.equal(starts, 1); assert.equal(stops, 0);
  shortcut.up(key({ctrlKey:false, altKey:false})); assert.equal(stops, 1); assert.equal(toggles, 0);
  shortcut.up(key()); assert.equal(stops, 1);
  shortcut.down(key()); shortcut.reset(); shortcut.up(key()); assert.equal(stops, 1);
});
test('failed starts and blocked contexts cannot leave a held shortcut behind', () => {
  let stops = 0, toggles = 0, allowed = false;
  const shortcut = new Shortcut({preferences:() => ({...defaults, activation:'hold'}), allowed:() => allowed,
    start:() => false, stop:() => stops++, toggle:() => toggles++});
  shortcut.down(key()); allowed = true; shortcut.down(key()); shortcut.up(key());
  assert.equal(stops, 0); assert.equal(shortcut.held, null);
  shortcut.preferences = () => defaults; shortcut.down(key()); assert.equal(toggles, 1);
});
