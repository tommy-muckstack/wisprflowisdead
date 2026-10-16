import {test} from 'node:test';
import assert from 'node:assert/strict';
import {AuthFlow, safeNext, friendly} from '../wisprflowisdead/assets/auth-flow.mjs';
import {startSession} from '../wisprflowisdead/assets/auth-service.mjs';
const user = {getIdToken:async () => 'test-token'};
function setup(extra = {}) {
  const calls = [], states = [];
  const sdk = {
    login:async (...args) => {calls.push(['login', ...args]); return user;},
    create:async () => {calls.push(['create']); return user;},
    google:async () => {calls.push(['google']); return user;},
    profile:async () => {}, verify:async () => {}, reset:async () => {},
    signOut:async () => {calls.push(['sdk-sign-out']);}
  };
  const flow = new AuthFlow({load:async () => sdk, startSession:async () => {calls.push(['session']);},
    navigate:url => calls.push(['navigate',url]), next:'/wisprflowisdead/app', onChange:s => states.push(s), ...extra});
  return {flow, sdk, calls, states};
}
test('setup failure leaves a recoverable state and can retry', async () => {
  const {flow, sdk} = setup({load:async () => {throw Error('offline');}});
  await flow.initialize(); assert.equal(flow.ready,false); assert.equal(flow.busy,false); assert.match(flow.message,/retry/);
  flow.load = async () => sdk; await flow.initialize(); assert.equal(flow.ready,true); assert.equal(flow.message,'');
});
test('email-first login supports correcting email and redirects only after cookie creation', async () => {
  const {flow,calls} = setup(); await flow.initialize();
  await flow.submit({email:'person@example.com'}); assert.equal(flow.step,1); assert.equal(calls.length,0);
  flow.editEmail(); assert.equal(flow.step,0);
  await flow.submit(); await flow.submit({email:' person@example.com ', password:'pass'});
  assert.deepEqual(calls,[['login','person@example.com','pass'],['session'],['sdk-sign-out'],['navigate','/wisprflowisdead/app']]);
});
test('duplicate clicks and mode changes cannot overlap a pending login', async () => {
  let release; const {flow,sdk,calls} = setup(); await flow.initialize(); await flow.submit();
  sdk.login = () => new Promise(resolve => {release = resolve;});
  const pending = flow.submit({email:'person@example.com',password:'pass'});
  assert.equal(await flow.submit(),false); assert.equal(await flow.google(),false);
  flow.setMode('signup'); assert.equal(flow.mode,'login');
  release(user); await pending;
  assert.equal(calls.filter(c=>c[0] === 'session').length,1);
});
test('session failure never redirects and leaves signup continuation retryable without a second account', async () => {
  let attempts = 0;
  const {flow,sdk,calls} = setup({startSession:async () => {if (++attempts === 1) throw {code:'session-failed'};}});
  sdk.profile = sdk.verify = async () => {throw Error('offline');};
  await flow.initialize(); flow.setMode('signup');
  await flow.submit({email:'person@example.com',password:'secret!',name:'Test'});
  assert.equal(flow.mode,'created'); assert.match(flow.message,/account was created/); assert.match(flow.message,/could not be sent/);
  assert.equal(await flow.submit(),false); assert.equal(flow.mode,'created'); assert.match(flow.message,/website session/);
  assert.equal(calls.some(c=>c[0] === 'navigate'),false);
  await flow.submit(); assert.equal(calls.filter(c=>c[0] === 'create').length,1);
  assert.equal(calls.filter(c=>c[0] === 'navigate').length,1);
});
test('verification resend reports success only after the email operation succeeds', async () => {
  const {flow,sdk} = setup(); await flow.initialize(); flow.setMode('signup'); await flow.submit();
  sdk.verify = async () => {throw {code:'auth/too-many-requests'};};
  assert.equal(await flow.resend(),false); assert.match(flow.message,/Too many/);
  sdk.verify = async () => {}; await flow.resend(); assert.match(flow.message,/Verification email sent/);
});
test('password reset neither reveals missing accounts nor reports network failure as sent', async () => {
  const {flow,sdk} = setup(); await flow.initialize(); flow.setMode('reset');
  sdk.reset = async () => {throw {code:'auth/user-not-found'};};
  await flow.submit({email:'person@example.com'}); assert.match(flow.message,/If an account/); assert.equal(flow.kind,'ok');
  sdk.reset = async () => {throw {code:'auth/network-request-failed'};};
  await flow.submit({email:'person@example.com'}); assert.equal(flow.kind,'err'); assert.doesNotMatch(flow.message,/on its way/);
});
test('a successful cookie login is not undone by SDK sign-out failure', async () => {
  const {flow,sdk,calls} = setup(); await flow.initialize();
  sdk.signOut = async () => {throw Error('unavailable');};
  assert.equal(await flow.google(),true); assert.equal(calls.at(-1)[0],'navigate');
});
test('return destinations reject external, backslash, control-character and login-loop URLs', () => {
  const origin = 'https://yourappisdead.com', fallback = '/wisprflowisdead/app';
  for (const next of [null,'https://other.example','//other.example','/\\other.example','/\n/other.example','/another-app','/wisprflowisdead/../other','/wisprflowisdead/login','/wisprflowisdead/login.html?next=x']) {
    assert.equal(safeNext(next,origin),fallback,next);
  }
  assert.equal(safeNext('/wisprflowisdead/demo?mode=list#workspace',origin),'/wisprflowisdead/demo?mode=list#workspace');
});
test('raw backend/SDK messages are not exposed to the form', () => {
  assert.equal(friendly({message:'Sensitive diagnostic'}),'Sign-in could not finish. Please try again.');
  assert.match(friendly({code:'auth/popup-blocked'}),/blocked/);
});
test('session exchange requires a fresh token and a successful server response', async t => {
  const calls = []; t.mock.method(globalThis,'fetch',async (url,options) => {calls.push([url,options]); return {ok:false};});
  let fresh; const account = {getIdToken:async force => {fresh = force; return 'test-token';}};
  await assert.rejects(startSession(account),{code:'session-failed'}); assert.equal(fresh,true);
  assert.equal(calls[0][0],'/wisprflowisdead/api/session'); assert.equal(calls[0][1].credentials,'same-origin');
  assert.equal(calls[0][1].body,JSON.stringify({idToken:'test-token'}));
  globalThis.fetch = async () => ({ok:true}); await startSession(account);
});
