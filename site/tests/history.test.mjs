import {test} from 'node:test';
import assert from 'node:assert/strict';
import {History, HISTORY_KEY, DAY} from '../wisprflowisdead/assets/history.mjs';

const result = (text = 'Review the draft.') => ({raw:'um review the draft', text, context:'email', source:'dictation', language:'en-US', style:'formal'});
function setup() {
  const data = new Map(); let time = DAY * 2, serial = 0, failure;
  const storage = {
    getItem(key) {if (failure === 'read') throw Error(); return data.get(key) ?? null;},
    setItem(key, value) {if (failure === 'write') throw Error(); data.set(key, value);},
    removeItem(key) {if (failure === 'remove') throw Error(); data.delete(key);}
  };
  const make = () => new History({storage, now:() => time, id:() => String(++serial)});
  return {data, storage, make, history:make(), advance:ms => {time += ms;}, fail:kind => {failure = kind;}};
}

test('page-only history stores no browser data and preserves literal original and cleaned text', () => {
  const {history, data} = setup();
  const entry = history.add({...result('<script>literal</script>\nNext line.'), raw:'uh <script>literal</script> new paragraph Next line.'});
  assert.equal(data.size, 0);
  assert.equal(history.list()[0].text, entry.text);
  assert.equal(history.list('uh <script>')[0].raw, entry.raw);
  history.remove(entry.id); assert.equal(history.list().length, 0);
});

test('persistent history restores after reload and clearing leaves other app storage intact', () => {
  const {history, data, make} = setup(); data.set('other-app', 'keep');
  history.add(result()); history.setMode('forever');
  const next = make(); next.load();
  assert.equal(next.mode, 'forever'); assert.equal(next.list().length, 1);
  next.clear();
  const again = make(); again.load();
  assert.equal(again.mode, 'forever'); assert.equal(again.list().length, 0);
  assert.equal(data.get('other-app'), 'keep');
});

test('never-history clears transcripts and remembers the disabled preference', () => {
  const {history, make, data} = setup(); history.add(result()); history.setMode('forever'); history.setMode('off');
  assert.equal(history.add(result('Do not keep this.')), null);
  assert.equal(history.list().length, 0);
  assert.deepEqual(JSON.parse(data.get(HISTORY_KEY)), {version:1, mode:'off', entries:[]});
  const next = make(); next.load(); assert.equal(next.mode, 'off');
  assert.equal(next.add(result()), null);
});

test('switching to page-only removes the saved copy while keeping current results', () => {
  const {history, data, make} = setup(); history.setMode('forever'); history.add(result());
  history.setMode('session');
  assert.equal(data.has(HISTORY_KEY), false); assert.equal(history.list().length, 1);
  const next = make(); next.load(); assert.equal(next.list().length, 0);
});

test('24-hour expiry removes exact-boundary entries on load and while the page is open', () => {
  const {history, make, advance, data} = setup();
  history.setMode('day'); history.add(result('Old.')); advance(DAY - 1); history.add(result('New.'));
  assert.equal(history.list().length, 2);
  advance(1); assert.deepEqual(history.list().map(x => x.text), ['New.']);
  const next = make(); next.load();
  assert.deepEqual(JSON.parse(data.get(HISTORY_KEY)).entries.map(x => x.text), ['New.']);
  advance(DAY); assert.equal(next.prune(), true);
  assert.equal(next.list().length, 0); assert.equal(next.prune(), false);
});

test('failed expiry deletion hides expired text and can retry its saved copy', () => {
  const {history, make, advance, data, fail} = setup();
  history.setMode('day'); history.add(result()); advance(DAY); fail('write');
  const next = make(); assert.throws(() => next.load(), /could not be saved/);
  assert.equal(next.list().length, 0);
  assert.equal(JSON.parse(data.get(HISTORY_KEY)).entries.length, 1);
  fail(); assert.equal(next.prune(), true);
  assert.equal(JSON.parse(data.get(HISTORY_KEY)).entries.length, 0);
});

test('write/remove failures do not claim that results or settings were changed', () => {
  const {history, data, fail} = setup(); history.setMode('forever'); const entry = history.add(result());
  const before = data.get(HISTORY_KEY); fail('write');
  assert.throws(() => history.add(result('New.'))); assert.throws(() => history.remove(entry.id));
  assert.throws(() => history.clear()); assert.throws(() => history.setMode('off'));
  assert.equal(history.mode, 'forever'); assert.equal(history.list().length, 1);
  assert.equal(data.get(HISTORY_KEY), before);
  fail('remove'); assert.throws(() => history.setMode('session'));
  assert.equal(history.mode, 'forever'); assert.equal(data.get(HISTORY_KEY), before);
});

test('cross-tab changes prevent stale saves, including another tab disabling history', () => {
  const {history, make} = setup(); history.setMode('forever'); history.add(result());
  const next = make(); next.load(); history.setMode('off');
  assert.throws(() => next.add(result('Stale.')), /another tab/);
  next.load(); assert.equal(next.mode, 'off'); assert.equal(next.add(result()), null);
});

test('corrupt, unsupported and duplicate saved data is preserved until explicit clearing', () => {
  const {history, data, make} = setup(); history.setMode('forever'); const entry = history.add(result());
  for (const value of ['{bad', JSON.stringify({version:2, mode:'forever', entries:[]}), JSON.stringify({version:1, mode:'forever', entries:[entry, entry]}), JSON.stringify({version:1, mode:'off', entries:[entry]})]) {
    data.set(HISTORY_KEY, value); const next = make();
    assert.throws(() => next.load(), /not been overwritten/); assert.equal(data.get(HISTORY_KEY), value);
    assert.throws(() => next.setMode('forever'), /unreadable/);
    next.clear(); assert.equal(data.has(HISTORY_KEY), false); assert.equal(next.corrupt, false);
  }
});

test('invalid results and capacity limits do not silently drop earlier transcripts', () => {
  const {history} = setup();
  for (const bad of [{text:''}, {raw:''}, {context:'unknown'}, {style:'unknown'}, {source:'invented'}, {text:'a'.repeat(200001)}]) {
    assert.throws(() => history.add({...result(), ...bad}));
  }
  for (let i = 0; i < 200; i++) history.add(result(String(i)));
  assert.throws(() => history.add(result('overflow')), /200 results/);
  assert.equal(history.list().length, 200);
});

test('command history retains the original passage, result and instruction across reload', () => {
  const {history, make} = setup();
  history.add(result());
  const command = history.add({...result('• First\n• Second'), raw:'First\nSecond', source:'command', instruction:'bullet list'});
  history.setMode('forever'); const next = make(); next.load();
  assert.equal(next.list().length, 2);
  assert.deepEqual(next.list('bullet list'), [command]);
  assert.equal(next.list('bullet list')[0].raw, 'First\nSecond');
  for (const instruction of [undefined, '', 'a'.repeat(1001)]) assert.throws(() => next.add({...result(), source:'command', instruction}));
  assert.equal(next.list().length, 2);
});
