const ROOT = '/wisprflowisdead';

export function safeNext(value, origin) {
  const fallback = ROOT + '/app';
  if (!value || !value.startsWith('/') || value.startsWith('//') || /[\\\u0000-\u0020]/.test(value)) return fallback;
  try {
    const url = new URL(value, origin);
    if (url.origin !== origin || !(url.pathname === ROOT || url.pathname.startsWith(ROOT + '/'))) return fallback;
    if (/^\/wisprflowisdead\/login(?:\.html)?\/?$/.test(url.pathname)) return fallback;
    return url.pathname + url.search + url.hash;
  } catch { return fallback; }
}

export function friendly(error) {
  const code = String(error?.code || '');
  if (/invalid-credential|wrong-password|user-not-found/.test(code)) return 'The email or password is incorrect. Try again or reset your password.';
  if (code.includes('email-already-in-use')) return 'An account already uses this email. Log in or reset your password.';
  if (code.includes('weak-password')) return 'Use at least 6 characters for your password.';
  if (code.includes('invalid-email')) return 'Enter a valid email address.';
  if (code.includes('popup-closed')) return 'Google sign-in was closed. You can try again or use email.';
  if (code.includes('popup-blocked')) return 'Your browser blocked the sign-in window. Allow pop-ups here or use email.';
  if (code.includes('account-exists-with-different-credential')) return 'This email uses a different sign-in method. Use the method you originally chose.';
  if (code.includes('too-many-requests')) return 'Too many attempts. Wait a few minutes before trying again.';
  if (code.includes('network-request-failed')) return 'Could not connect. Check your connection and try again.';
  if (code.includes('user-disabled')) return 'This account is disabled. Contact the project maintainer for help.';
  if (/operation-not-allowed|unauthorized-domain/.test(code)) return 'This sign-in method is unavailable here. Try another method.';
  if (code === 'session-failed') return 'Could not start your website session. Please try again.';
  return 'Sign-in could not finish. Please try again.';
}

// The Firebase SDK remains in memory; the server cookie is the session authority.
export class AuthFlow {
  constructor({load, startSession, navigate, next, onChange, onSignedIn}) {
    Object.assign(this, {load, startSession, navigate, next, onChange, onSignedIn});
    this.ready = false; this.busy = false; this.mode = 'login'; this.step = 0;
    this.message = ''; this.kind = ''; this.pendingLabel = '';
  }
  emit() {
    this.onChange({ready:this.ready, busy:this.busy, mode:this.mode, step:this.step,
      message:this.message, kind:this.kind, pendingLabel:this.pendingLabel});
  }
  say(message, kind = '') { this.message = message; this.kind = kind; this.emit(); }
  async run(label, action) {
    if (this.busy) return false;
    this.busy = true; this.pendingLabel = label; this.message = ''; this.kind = ''; this.emit();
    try { await action(); return true; }
    catch (error) { this.say(friendly(error), 'err'); return false; }
    finally { this.busy = false; this.pendingLabel = ''; this.emit(); }
  }
  async initialize() {
    return this.run('Loading sign-in…', async () => {
      this.ready = false;
      try { this.sdk = await this.load(); this.ready = true; }
      catch { this.say('Sign-in could not load. Check your connection and retry. If it keeps failing, use the browser demo or contact the project maintainer.', 'err'); }
    });
  }
  setMode(mode) {
    if (this.busy || !['login','signup','reset'].includes(mode)) return;
    this.mode = mode; this.step = mode === 'signup' ? 1 : 0;
    this.user = null; this.say('');
  }
  editEmail() { if (!this.busy && this.mode === 'login') {this.step = 0; this.say('');} }
  async done(user, method = 'password', created = false) {
    await this.startSession(user);
    // Failure to clear the in-memory SDK must not turn a successful cookie login into an error.
    try { await this.sdk.signOut(); } catch { /* Navigating destroys this in-memory auth instance. */ }
    // Analytics (identify + sign-in event) must never block or fail a successful sign-in.
    try { await this.onSignedIn?.({uid:user?.uid, method, created}); } catch { /* analytics only */ }
    this.say('You’re signed in.', 'ok');
    this.navigate(this.next);
  }
  async submit({email = '', password = '', name = ''} = {}) {
    if (!this.ready || this.busy) return false;
    if (this.mode === 'login' && !this.step) {this.step = 1; this.say('Enter your password to continue.'); return true;}
    return this.run(this.mode === 'signup' ? 'Creating account…' : this.mode === 'reset' ? 'Sending reset link…' : 'Signing in…', async () => {
      if (this.mode === 'created') return this.done(this.user, 'password', true);
      if (this.mode === 'reset') {
        try { await this.sdk.reset(email.trim()); }
        catch (error) { if (error?.code !== 'auth/user-not-found') throw error; }
        this.say('If an account uses this email, a password reset link is on its way. Check your inbox and spam folder.', 'ok');
        return;
      }
      if (this.mode === 'login') return this.done(await this.sdk.login(email.trim(), password));
      // Once creation succeeds, retries must continue this account rather than create it again.
      this.user = await this.sdk.create(email.trim(), password);
      this.mode = 'created';
      if (name.trim()) {
        try { await this.sdk.profile(this.user, name.trim()); }
        catch { /* A profile-name failure must not block the new account's session. */ }
      }
      return this.done(this.user, 'password', true);
    });
  }
  async google() {
    if (!this.ready) return false;
    return this.run('Opening Google…', async () => {
      const user = await this.sdk.google();
      return this.done(user, 'google', Boolean(this.sdk.googleWasNew?.()));
    });
  }
}
