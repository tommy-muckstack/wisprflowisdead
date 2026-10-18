import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';
import {AuthFlow} from '../wisprflowisdead/assets/auth-flow.mjs';

const user = {uid:'uid-1', getIdToken:async () => 'token'};
function flowWith(onSignedIn, sdkExtra = {}) {
  const calls = [];
  const sdk = {login:async () => user, create:async () => user, google:async () => user, profile:async () => {}, reset:async () => {}, signOut:async () => {}, ...sdkExtra};
  const flow = new AuthFlow({load:async () => sdk, startSession:async () => {}, navigate:url => calls.push(['navigate', url]),
    next:'/wisprflowisdead/app', onChange:() => {}, onSignedIn:async info => {calls.push(['signed-in', info]); await onSignedIn?.(info);}});
  return {flow, calls};
}

test('sign-in, sign-up and Google report method and whether the account is new, before navigating', async () => {
  let {flow, calls} = flowWith(); await flow.initialize();
  await flow.submit({email:'a@example.com'}); await flow.submit({email:'a@example.com', password:'pw'});
  assert.deepEqual(calls, [['signed-in', {uid:'uid-1', method:'password', created:false}], ['navigate', '/wisprflowisdead/app']]);

  ({flow, calls} = flowWith()); await flow.initialize(); flow.setMode('signup');
  await flow.submit({email:'a@example.com', password:'secret1'});
  assert.deepEqual(calls[0], ['signed-in', {uid:'uid-1', method:'password', created:true}]);

  ({flow, calls} = flowWith(null, {googleWasNew:() => true})); await flow.initialize(); await flow.google();
  assert.deepEqual(calls[0], ['signed-in', {uid:'uid-1', method:'google', created:true}]);
});

test('an analytics failure never blocks a successful sign-in', async () => {
  const {flow, calls} = flowWith(async () => {throw Error('blocked');}); await flow.initialize();
  await flow.google();
  assert.deepEqual(calls.at(-1), ['navigate', '/wisprflowisdead/app']);
  assert.equal(flow.kind, 'ok');
});

test('analytics.js is a silent no-op on localhost unless debug is opted in', () => {
  const script = readFileSync(new URL('../wisprflowisdead/assets/analytics.js', import.meta.url), 'utf8');
  const window = {};
  runInNewContext(script, {window, location:{hostname:'localhost', pathname:'/wisprflowisdead', origin:'http://localhost:3141'},
    localStorage:{getItem:() => null}, navigator:{}, document:{}});
  assert.equal(window.isdeadAnalytics.enabled, false);
  assert.doesNotThrow(() => window.isdeadAnalytics.track('app_text_copied', {words:1}));
  assert.equal(window.posthog, undefined);
});
