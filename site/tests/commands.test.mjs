import {test} from 'node:test';
import assert from 'node:assert/strict';
import {captureCommand, transformText, applyCommand, CommandError} from '../wisprflowisdead/assets/commands.mjs';
import {Dictation} from '../wisprflowisdead/assets/dictation.mjs';

test('a command replaces only the selection, including a partial word, and preserves an undo snapshot', () => {
  const selection = captureCommand('Keep preFixSuffix and URL/Case.', 8, 11);
  const result = transformText('Please uppercase.', selection);
  assert.equal(selection.target, 'Fix');
  assert.deepEqual(applyCommand(selection, result), {value:'Keep preFIXSuffix and URL/Case.', start:8, end:11});
  assert.equal(selection.text, 'Keep preFixSuffix and URL/Case.');
  const unicode = captureCommand('Go ß!', 3, 4);
  assert.deepEqual(applyCommand(unicode, transformText('uppercase', unicode)), {value:'Go SS!', start:3, end:5});
});

test('an empty selection uses the whole editor and literal case changes have no cleanup side effects', () => {
  const selection = captureCommand('um Visit https://Example.com/A', 4, 4);
  assert.equal(selection.start, 0); assert.equal(selection.end, selection.text.length);
  assert.equal(transformText('lower case!', selection), 'um visit https://example.com/a');
  assert.equal(transformText('make it uppercase', {target:'café <b>Text</b>'}), 'CAFÉ <B>TEXT</B>');
});

test('lists keep one item per nonempty line, renumber existing markers and preserve numeric values', () => {
  const target = ' • First. Another sentence.\r\n2) Second\n\n-2 degrees\n3.14 total\n* https://example.com';
  assert.equal(transformText('make a numbered list', {target}), '1. First. Another sentence.\n2. Second\n3. -2 degrees\n4. 3.14 total\n5. https://example.com');
  assert.equal(transformText('bullet list', {target:'1. One\n2. Two'}), '• One\n• Two');
});

test('spacing preserves paragraph breaks and cleanup retains existing language and literal safeguards', () => {
  assert.equal(transformText('trim spacing', {target:'  One\t two \r\n\r\n three   four '}), 'One two\n\nthree four');
  assert.equal(transformText('clean up text', {target:'um send the the draft question mark', language:'en-US',style:'formal'}), 'Send the draft?');
  assert.equal(transformText('clean up', {target:'bonjour le monde',language:'fr-FR'}), 'bonjour le monde');
  assert.equal(transformText('clean up text', {target:'um https://Example.com/Case `new paragraph`'}), 'https://Example.com/Case `new paragraph`');
});

test('unknown, ambiguous, destructive and oversized inputs fail without inventing a rewrite', () => {
  for (const instruction of ['', 'make it friendlier', 'uppercase and lowercase', 'do not uppercase', 'delete everything', 'a'.repeat(1001)]) {
    assert.throws(() => transformText(instruction, {target:'Keep this.'}), CommandError);
  }
  assert.throws(() => transformText('clean up text', {target:'um uh'}), /draft is unchanged/);
  assert.throws(() => captureCommand('   ',0,0), /nonempty/);
  assert.throws(() => captureCommand('Text',0,5), /Select the text again/);
  assert.throws(() => captureCommand('Text',3,1), CommandError);
  assert.throws(() => captureCommand('a'.repeat(200001),0,0), /shorter passage/);
  assert.throws(() => transformText('uppercase', {target:'ß'.repeat(100001)}), /result is too long/);
});

test('typed commands use result/error states, keep instructions for recovery, and allow retry', async () => {
  const changes = [];
  const machine = new Dictation({createRecognition:null, polish:transformText, onChange:value => changes.push(value)});
  const options = {action:'command',target:'Keep this.'};
  await machine.practice('make it friendlier', options);
  assert.equal(machine.state, 'error'); assert.match(machine.message, /Command not supported/);
  assert.equal(machine.result, ''); assert.equal(machine.raw, 'make it friendlier');
  await machine.practice('uppercase', options);
  assert.equal(machine.state, 'result'); assert.equal(machine.result, 'KEEP THIS.');
  assert.deepEqual(changes.map(change => change.state), ['polishing','error','polishing','result']);
  await machine.practice(' ', options);
  assert.equal(machine.state, 'error'); assert.equal(machine.message, 'Say or type a command first.');
});

test('voice commands use the captured target and cancellation discards late instructions', async () => {
  let recognition;
  const machine = new Dictation({createRecognition:() => recognition = {start(){},stop(){},abort(){}}, polish:transformText, onChange(){}});
  const options = {action:'command',target:'one\ntwo'};
  machine.start(options); options.target = 'Changed elsewhere'; recognition.onstart();
  recognition.onresult({results:[Object.assign([{transcript:'numbered list'}], {isFinal:true})]});
  machine.stop(); recognition.onend(); await new Promise(resolve => setImmediate(resolve));
  assert.equal(machine.result, '1. one\n2. two');
  machine.start({action:'command',target:'keep'}); const late = recognition.onresult;
  machine.cancel(); late({results:[Object.assign([{transcript:'uppercase'}], {isFinal:true})]});
  assert.equal(machine.state, 'idle'); assert.equal(machine.result, '');
  assert.match(machine.message, /Command cancelled/);
});
