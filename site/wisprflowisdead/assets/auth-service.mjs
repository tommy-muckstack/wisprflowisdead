const ROOT = '/wisprflowisdead/api';
async function request(url, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15000);
  try { return await fetch(url, {...options, signal:controller.signal, credentials:'same-origin', cache:'no-store'}); }
  finally { clearTimeout(timer); }
}
async function initializeAuth() {
  const response = await request(ROOT + '/config');
  if (!response.ok) throw Error('Configuration unavailable');
  const config = await response.json();
  if (!config.firebase) throw Error('Configuration unavailable');
  // Keep the existing SDK version and shared Firebase project configuration.
  const version = '10.14.1';
  const [appModule, A] = await Promise.all([
    import(`https://www.gstatic.com/firebasejs/${version}/firebase-app.js`),
    import(`https://www.gstatic.com/firebasejs/${version}/firebase-auth.js`)
  ]);
  const app = appModule.getApps().find(item => item.name === 'isdead') || appModule.initializeApp(config.firebase, 'isdead');
  const auth = A.getAuth(app);
  await A.setPersistence(auth, A.inMemoryPersistence);
  return {
    login: async (email, password) => (await A.signInWithEmailAndPassword(auth, email, password)).user,
    create: async (email, password) => (await A.createUserWithEmailAndPassword(auth, email, password)).user,
    google: async () => (await A.signInWithPopup(auth, new A.GoogleAuthProvider())).user,
    profile: (user, name) => A.updateProfile(user, {displayName:name}),
    verify: user => A.sendEmailVerification(user),
    reset: email => A.sendPasswordResetEmail(auth, email),
    signOut: () => A.signOut(auth)
  };
}
export async function loadAuth() {
  let timer;
  try {
    return await Promise.race([
      initializeAuth(),
      new Promise((_, reject) => {timer = setTimeout(() => reject(Error('Sign-in setup timed out')), 25000);})
    ]);
  } finally { clearTimeout(timer); }
}
export async function startSession(user) {
  try {
    const response = await request(ROOT + '/session', {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify({idToken:await user.getIdToken(true)})});
    if (!response.ok) throw Error('Session rejected');
  } catch { throw Object.assign(Error('Session unavailable'), {code:'session-failed'}); }
}
