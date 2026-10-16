import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Onboarding, ONBOARDING_KEY} from '../wisprflowisdead/assets/onboarding.mjs';
function setup() {
  const data = new Map(); let fail = false;
  const storage = {getItem:key => data.get(key) ?? null, setItem(key, value) {if (fail) throw Error(); data.set(key, value);}};
  return {data, storage, guide:new Onboarding(storage), fail:() => {fail = true;}};
}
test('new setup cannot claim microphone/practice success without observed results', () => {
  const {guide:g, data} = setup(); assert.equal(g.load(), ''); assert.equal(g.current, 'privacy');
  assert.throws(() => g.finish('completed')); g.next(); assert.equal(g.current, 'microphone');
  assert.throws(() => g.next()); g.observe('microphone', false); assert.equal(g.ready, false);
  g.observe('microphone', true); g.next(); g.next(); assert.equal(g.current, 'practice');
  assert.throws(() => g.next()); assert.equal(data.size, 0);
  g.observe('practice', true); const message = g.next();
  assert.match(message, /Setup complete/); assert.equal(g.visible, false); assert.equal(g.persisted, true);
});
test('individual steps can be skipped without claiming they were tested', () => {
  const {guide:g} = setup(); g.next(); g.next(true); g.next(); g.next(true);
  assert.equal(g.marks.microphone, 'skipped'); assert.equal(g.marks.practice, 'skipped');
  assert.equal(g.visible, false);
});
test('skip-all stores only a completion choice and prevents the guide returning on reload', () => {
  const {guide:g, data, storage} = setup(); g.finish('skipped');
  assert.deepEqual(JSON.parse(data.get(ONBOARDING_KEY)), {version:1, status:'skipped'});
  const next = new Onboarding(storage); next.load(); assert.equal(next.visible, false);
  next.open(); assert.equal(next.visible, true); assert.deepEqual(next.marks, {}); assert.equal(next.index, 0);
});
test('back navigation preserves genuine observations and never goes below the first step', () => {
  const {guide:g} = setup(); g.previous(); assert.equal(g.index, 0);
  g.next(); g.observe('microphone', true); g.next(); g.previous(); assert.equal(g.ready, true);
  g.next(); assert.equal(g.current, 'preferences');
});
test('failed completion storage finishes this visit but explicitly reports that it was not remembered', () => {
  const {guide:g, data, fail} = setup(); fail();
  const message = g.finish('skipped'); assert.equal(g.visible, false); assert.equal(g.persisted, false);
  assert.match(message, /could not be remembered/); assert.equal(data.size, 0);
});
test('unreadable/unknown completion data is preserved until an explicit completion action', () => {
  const {guide:g, data} = setup(); data.set(ONBOARDING_KEY, '{bad'); data.set('library', 'keep');
  assert.match(g.load(), /could not be read/); assert.equal(g.visible, true); assert.equal(data.get(ONBOARDING_KEY), '{bad');
  g.finish('skipped'); assert.equal(data.get('library'), 'keep');
  data.set(ONBOARDING_KEY, JSON.stringify({version:2, status:'completed'}));
  g.open(); assert.match(g.load(), /could not be read/); assert.equal(g.visible, true);
});
