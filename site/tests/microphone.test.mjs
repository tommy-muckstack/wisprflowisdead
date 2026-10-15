import {test} from 'node:test';
import assert from 'node:assert/strict';
import {MicrophoneCheck} from '../wisprflowisdead/assets/microphone.mjs';
const deferred = () => {let resolve, reject; const promise = new Promise((yes, no) => {resolve = yes; reject = no;}); return {promise, resolve, reject};};
function setup(getUserMedia) {
  const events = [], levels = [], timers = new Map(), frames = new Map(); let serial = 0, closed = 0, disconnected = 0;
  const track = {readyState:'live', label:'Test input', stopped:0, stop() {this.stopped++;}};
  const stream = {getTracks:() => [track], getAudioTracks:() => [track]};
  const microphone = new MicrophoneCheck({getUserMedia:getUserMedia || (async () => stream),
    createContext:() => ({createAnalyser:() => ({fftSize:0, getFloatTimeDomainData:array => array.fill(.1)}),
      createMediaStreamSource:() => ({connect() {}, disconnect() {disconnected++;}}), resume:async () => {}, close:async () => {closed++;}}),
    onChange:event => events.push(event), onLevel:level => levels.push(level),
    schedule:(fn, ms) => {const id = ++serial; timers.set(id, {fn, ms}); return id;}, unschedule:id => timers.delete(id),
    frame:fn => {const id = ++serial; frames.set(id, fn); return id;}, cancelFrame:id => frames.delete(id)});
  return {microphone, stream, track, events, levels, timers, frames, closed:() => closed, disconnected:() => disconnected};
}
test('microphone check requests audio only, reports actual levels and releases every resource on stop', async () => {
  const p = setup(); let options;
  p.microphone.getUserMedia = async input => {options = input; return p.stream;};
  await p.microphone.start(); assert.deepEqual(options, {audio:true, video:false});
  assert.equal(p.microphone.state, 'testing'); assert.ok(p.levels.at(-1) > 0);
  p.microphone.stop(); assert.equal(p.track.stopped, 1); assert.equal(p.closed(), 1); assert.equal(p.disconnected(), 1);
  assert.equal(p.timers.size, 0); assert.equal(p.frames.size, 0); assert.equal(p.levels.at(-1), 0);
});
test('cancelling a pending permission request stops a late stream without opening audio processing', async () => {
  const request = deferred(), p = setup(() => request.promise);
  const starting = p.microphone.start(); p.microphone.stop(); request.resolve(p.stream); await starting;
  assert.equal(p.track.stopped, 1); assert.equal(p.closed(), 0); assert.equal(p.microphone.state, 'idle');
});
test('permission timeout rejects late grants and duplicate starts do not request twice', async () => {
  const request = deferred(); let calls = 0;
  const p = setup(() => {calls++; return request.promise;});
  const starting = p.microphone.start(); await p.microphone.start(); assert.equal(calls, 1);
  assert.equal([...p.timers.values()][0].ms, 15000); [...p.timers.values()][0].fn();
  assert.equal(p.microphone.state, 'error'); request.resolve(p.stream); await starting;
  assert.equal(p.track.stopped, 1); assert.equal(p.frames.size, 0);
});
test('successful tests stop automatically after twenty seconds', async () => {
  const p = setup(); await p.microphone.start(); const timer = [...p.timers.values()][0];
  assert.equal(timer.ms, 20000); timer.fn();
  assert.equal(p.microphone.state, 'idle'); assert.equal(p.track.stopped, 1); assert.equal(p.closed(), 1);
});
test('permission/device errors remain explicit and do not show a connected microphone', async () => {
  for (const name of ['NotAllowedError','SecurityError','NotFoundError','NotReadableError','AbortError','InvalidStateError']) {
    const p = setup(async () => {throw {name};}); await p.microphone.start();
    assert.equal(p.microphone.state, 'error'); assert.ok(p.events.at(-1).message);
    assert.equal(p.events.some(event => event.state === 'testing'), false); assert.equal(p.timers.size, 0);
  }
});
test('disconnecting the device releases the stream and old callbacks cannot stop a later test', async () => {
  const p = setup(); await p.microphone.start(); const oldEnded = p.track.onended;
  oldEnded(); assert.equal(p.microphone.state, 'error'); assert.equal(p.track.stopped, 1);
  await p.microphone.start(); oldEnded(); assert.equal(p.microphone.state, 'testing');
  p.microphone.stop();
});
test('audio processing failures release acquired input and unsupported browsers do not prompt', async () => {
  const p = setup(); p.microphone.createContext = () => {throw Error();}; await p.microphone.start();
  assert.equal(p.track.stopped, 1); assert.equal(p.microphone.state, 'error');
  const unsupported = setup(); unsupported.microphone.getUserMedia = null; await unsupported.microphone.start();
  assert.equal(unsupported.microphone.state, 'error'); assert.equal(unsupported.track.stopped, 0);
});
