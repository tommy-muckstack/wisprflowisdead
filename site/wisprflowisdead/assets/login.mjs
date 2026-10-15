import {AuthFlow, safeNext} from './auth-flow.mjs';
import {loadAuth, startSession} from './auth-service.mjs';
const $ = id => document.getElementById(id);
const flow = new AuthFlow({load:loadAuth, startSession, navigate:url => location.assign(url),
  next:safeNext(new URLSearchParams(location.search).get('next'), location.origin), onChange:render});

function render(state) {
  const {mode, step, busy, ready} = state;
  const password = mode === 'signup' || (mode === 'login' && step === 1);
  $('title').textContent = ({login:'Get started', signup:'Create your account', reset:'Reset your password', created:'Your account is ready'})[mode];
  $('card').setAttribute('aria-busy', String(busy));
  $('card').dataset.mode = mode;
  $('card').dataset.step = String(step);
  $('form').setAttribute('aria-busy', String(busy));
  $('nameRow').hidden = mode !== 'signup';
  $('emailRow').hidden = mode === 'created';
  $('pwRow').hidden = !password;
  $('password').required = password;
  $('password').disabled = busy || !password;
  $('password').autocomplete = mode === 'signup' ? 'new-password' : 'current-password';
  $('password').minLength = mode === 'signup' ? 6 : 1;
  $('email').disabled = busy || mode === 'created';
  $('email').readOnly = mode === 'login' && step === 1;
  $('name').disabled = busy || mode !== 'signup';
  $('edit-email').hidden = mode !== 'login' || step !== 1;
  $('edit-email').disabled = busy;
  $('google').disabled = busy || !ready;
  $('providers').hidden = mode === 'created' || mode === 'reset';
  $('submit').disabled = busy || !ready;
  $('submit').textContent = busy ? state.pendingLabel : ({signup:'Create account', reset:'Send reset link', created:'Continue'})[mode] || (step ? 'Log in' : 'Continue');
  $('toggle').hidden = mode === 'created';
  $('toggle').disabled = busy;
  $('toggle').textContent = mode === 'login' ? 'Create an account' : 'Have an account? Log in';
  $('reset').hidden = mode !== 'login';
  $('reset').disabled = busy;
  $('resend').hidden = mode !== 'created';
  $('resend').disabled = busy;
  $('retry').hidden = ready || busy;
  $('msg').textContent = busy ? state.pendingLabel : state.message;
  $('msg').className = 'msg ' + state.kind;
  if (mode === 'created') $('password').value = '';
}
$('form').addEventListener('submit', async event => {
  event.preventDefault();
  if (!$('form').reportValidity()) return;
  const firstStep = flow.mode === 'login' && flow.step === 0;
  await flow.submit({email:$('email').value, password:$('password').value, name:$('name').value});
  if (firstStep && flow.step === 1) $('password').focus();
  else if (flow.mode === 'created') $('submit').focus();
});
$('toggle').addEventListener('click', () => {flow.setMode(flow.mode === 'login' ? 'signup' : 'login'); $('password').value = ''; $('email').focus();});
$('reset').addEventListener('click', () => {flow.setMode('reset'); $('email').focus();});
$('edit-email').addEventListener('click', () => {flow.editEmail(); $('password').value = ''; $('email').focus();});
$('google').addEventListener('click', () => void flow.google());
$('resend').addEventListener('click', () => void flow.resend());
$('retry').addEventListener('click', () => void flow.initialize());
void flow.initialize();
