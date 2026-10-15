import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Dictation, speechErrors} from '../wisprflowisdead/assets/dictation.mjs';
import {cleanText} from '../wisprflowisdead/assets/text.mjs';
const tick = () => new Promise(resolve => setImmediate(resolve));
const result = (text, isFinal = true) => Object.assign([{transcript:text}], {isFinal});
function setup(extra = {}) {
  const changes = [], timers = new Map(), recognitions = [];
  const createRecognition = () => {
    const recognition = {start(){this.starts = (this.starts || 0) + 1;}, stop(){this.stopped = true;}, abort(){this.aborted = true;}};
    recognitions.push(recognition); return recognition;
  };
  const machine = new Dictation({createRecognition, onChange:s => changes.push(s), schedule:fn => {const id = Symbol(); timers.set(id,fn); return id;}, unschedule:id => timers.delete(id), ...extra});
  return {machine, changes, timers, recognitions};
}
test('recognition uses final results once, includes stop-time results, and produces all core states', async () => {
  const {machine, changes, recognitions, timers} = setup();
  machine.start({language:'en-GB'});
  const r = recognitions[0]; assert.equal(r.lang, 'en-GB');
  r.onstart();
  r.onresult({results:[result('um review', false)]});
  r.onresult({results:[result('um review the outline')]});
  machine.stop();
  assert.equal(r.stopped, true);
  r.onresult({results:[result('um review the outline'),result('tomorrow')]});
  r.onend(); await tick();
  assert.equal(machine.result, 'Review the outline tomorrow.');
  assert.equal(timers.size, 0);
  assert.deepEqual([...new Set(changes.map(s=>s.state))], ['requesting','listening','transcribing','polishing','result']);
});
test('late events from cancelled runs cannot overwrite the next run', async () => {
  const {machine, recognitions} = setup();
  machine.start(); const r = recognitions[0], oldResult = r.onresult, oldEnd = r.onend;
  machine.cancel(); machine.start();
  oldResult({results:[result('stale text')]}); oldEnd(); await tick();
  assert.equal(machine.state, 'requesting'); assert.equal(machine.raw, '');
  assert.equal(r.aborted, true); machine.cancel();
});
test('denied permission, network and microphone errors remain recoverable', () => {
  for (const code of ['not-allowed','network','audio-capture','language-not-supported']) {
    const {machine, recognitions, timers} = setup();
    machine.start(); recognitions[0].onerror({error:code});
    assert.equal(machine.state, 'error'); assert.equal(machine.message, speechErrors[code]);
    assert.equal(timers.size, 0); assert.equal(machine.start(), true); machine.cancel();
  }
});
test('silent and interim-only recordings do not fabricate a successful transcript', async () => {
  for (const interim of ['', 'unfinished words']) {
    const {machine, recognitions} = setup(); machine.start(); const r = recognitions[0]; r.onstart();
    r.onresult({results:[result(interim,false)]}); r.onend(); await tick();
    assert.equal(machine.state, 'error'); assert.equal(machine.result, ''); assert.equal(machine.interim, interim);
  }
});
test('stop timeout retains text for recovery and aborts the service', () => {
  const {machine, recognitions, timers} = setup(); machine.start(); const r = recognitions[0]; r.onstart();
  r.onresult({results:[result('recover these words')]}); machine.stop(); [...timers.values()][0]();
  assert.equal(machine.state, 'error'); assert.equal(machine.raw, 'recover these words'); assert.equal(r.aborted, true);
});
test('duplicate starts and typed practice cannot interrupt recording; pending permission can be cancelled', async () => {
  const {machine, recognitions} = setup(); assert.equal(machine.start(), true); assert.equal(machine.start(), false);
  assert.equal(await machine.practice('typed text'), false); assert.equal(recognitions.length, 1);
  machine.stop(); assert.equal(machine.state, 'idle'); assert.equal(recognitions[0].aborted,true);
});
test('cancel during asynchronous cleanup discards late completion', async () => {
  let resolve; const {machine} = setup({polish:() => new Promise(done => {resolve = done;})});
  const pending = machine.practice('please do not insert'); machine.cancel(); resolve('late result'); await pending;
  assert.equal(machine.state, 'idle'); assert.equal(machine.result, '');
});
test('unsupported browsers can still use the real cleanup path without speech', async () => {
  const {machine} = setup({createRecognition:null}); assert.equal(machine.start(),false);
  await machine.practice('um send the the outline full stop'); assert.equal(machine.result,'Send the outline.');
});
test('empty input and filler-only input produce useful empty states', async () => {
  const {machine} = setup(); await machine.practice('  '); assert.equal(machine.state,'error');
  await machine.practice('um uh'); assert.equal(machine.state,'error'); assert.equal(machine.result,'');
});
test('cleanup is conservative with meaningful words, punctuation and non-English text', () => {
  assert.equal(cleanText('I like this and you know the answer'), 'I like this and you know the answer.');
  assert.equal(cleanText('I had had enough'), 'I had had enough.');
  assert.equal(cleanText('is this ready question mark'), 'Is this ready?');
  assert.equal(cleanText('new bullet milk new bullet eggs'), '• Milk\n• Eggs.');
  assert.equal(cleanText('bonjour le monde', {language:'fr-FR'}), 'bonjour le monde');
  assert.equal(cleanText('visit example.com'), 'Visit example.com.');
  assert.equal(cleanText('um https://example.com/UmCase'), 'https://example.com/UmCase');
  assert.equal(cleanText('Contact Me@Example.com', {style:'very-casual'}), 'contact Me@Example.com');
  assert.equal(cleanText('use `new paragraph` literally'), 'Use `new paragraph` literally.');
  assert.equal(cleanText('Um. hello'), 'Hello.');
  assert.equal(cleanText('keep \uE0000\uE001 and `code`'), 'Keep \uE0000\uE001 and `code`');
  assert.equal(cleanText('hello', {style:'casual'}), 'Hello');
  assert.equal(cleanText('Hello.', {style:'very-casual'}), 'hello');
  assert.equal(cleanText('hello', {style:'excited'}), 'Hello!');
});
