// Execute the pinned shared smoke2 flow with session assertions and guaranteed cleanup attempts.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {readFile, realpath, mkdir, writeFile} from 'node:fs/promises';
import path from 'node:path';

const mode = process.argv[2];
assert.ok(['live','candidate'].includes(mode), 'Choose live or candidate');
const base = 'https://yourappisdead.com/wisprflowisdead';
const tools = path.resolve(process.env.PARITY_TOOLS_DIR || 'parity-tools');
const output = path.resolve('qa-artifacts/auth');
const root = await realpath('site/wisprflowisdead');
await mkdir(output,{recursive:true});
let source = await readFile(path.join(tools,'templates/smoke2.mjs'),'utf8');
assert.equal(createHash('sha256').update(source).digest('hex'),
  'c0da6a7b7e8cc15cd1970bee703171646d51131fd5fcbfb00c5b31960db7c61c',
  'Shared smoke2 changed; inspect its flow before running');
const state = {mode,sessionChecks:[],screenshots:[],accountObserved:false};
let browser, context, page, email, password, apiKey, token, uid, result;
const responses = [];
const safe = value => String(value).replaceAll(password || '\0','[password]').replaceAll(token || '\0','[token]')
  .replace(/([?&]key=)[^&\s"']+/g,'$1[public-key]').slice(0,1500);
const originalLog = console.log;
console.log = (...values) => originalLog(...values.map(safe));
const types = {'.html':'text/html','.css':'text/css','.js':'text/javascript','.mjs':'text/javascript','.png':'image/png','.woff2':'font/woff2','.svg':'image/svg+xml'};

globalThis.smokeSetup = async values => {
  ({b:browser,ctx:context,p:page,email,pw:password} = values);
  page.setDefaultTimeout(10000); page.setDefaultNavigationTimeout(30000);
  if (mode === 'candidate') await context.route(url => url.origin === 'https://yourappisdead.com' &&
    (url.pathname === '/wisprflowisdead' || url.pathname.startsWith('/wisprflowisdead/')),async route => {
    const request = route.request(); const url = new URL(request.url());
    if (request.method() !== 'GET' || url.pathname.startsWith('/wisprflowisdead/api/')) return route.continue();
    if (url.pathname !== '/wisprflowisdead' && !url.pathname.startsWith('/wisprflowisdead/')) return route.continue();
    let relative = decodeURIComponent(url.pathname.slice('/wisprflowisdead'.length)).replace(/^\/+/, '') || 'index.html';
    if (!path.extname(relative)) relative += '.html';
    try {
      const file = await realpath(path.resolve(root,relative)); const contentType = types[path.extname(file)];
      if (!file.startsWith(root + path.sep) || !contentType) return route.fulfill({status:404,body:'Not found'});
      return route.fulfill({status:200,contentType,body:await readFile(file)});
    } catch {return route.fulfill({status:404,body:'Not found'});}
  });
  // Only observe this test's own email/password responses; never persist tokens or cookie values.
  page.on('response',response => {
    const url = new URL(response.url());
    if (url.hostname !== 'identitytoolkit.googleapis.com' || !/\/accounts:(signUp|signInWithPassword)$/.test(url.pathname)) return;
    let sent; try {sent = response.request().postDataJSON();} catch {return;}
    if (sent?.email !== email) return;
    responses.push((async () => {
      const body = await response.json().catch(() => null);
      if (response.ok() && body?.email === email && body.idToken) {
        token = body.idToken; uid = body.localId; state.accountObserved = true;
      }
    })());
  });
  const config = await context.request.get(base + '/api/config',{timeout:15000});
  assert.equal(config.status(),200,'Public Firebase config unavailable');
  apiKey = (await config.json()).firebase?.apiKey;
  assert.equal(typeof apiKey,'string','Public Firebase config missing');
};
globalThis.smokeSession = async (stage,signedIn) => {
  const response = await context.request.get(base + '/api/session',{timeout:15000});
  const cookies = (await context.cookies()).filter(cookie => cookie.name === 'isdead_session' && cookie.value);
  const identity = response.ok() ? await response.json() : null;
  const cookieFlags = cookies.length === 1 && cookies[0].httpOnly && cookies[0].secure && cookies[0].sameSite === 'Lax' && cookies[0].path === '/';
  const passed = signedIn ? response.status() === 200 && identity?.email === email && cookieFlags : response.status() === 401 && cookies.length === 0;
  state.sessionChecks.push({stage,status:response.status(),passed,identityMatches:identity?.email === email,cookieFlags:Boolean(cookieFlags)});
  return passed;
};
globalThis.smokeAccount = async stage => {
  await page.locator('#box').waitFor({state:'visible',timeout:15000});
  assert.ok((await page.locator('#who').textContent()).includes(email),'Account identity did not render');
  for (const width of [1440,390]) {
    await page.setViewportSize({width,height:width === 390 ? 844 : 900});
    const name = `${mode}-${stage}-${width}.png`;
    await page.screenshot({path:path.join(output,name),mask:[page.locator('#who')]});
    state.screenshots.push(name);
  }
  await page.setViewportSize({width:1440,height:900});
};
globalThis.smokeResult = value => {result = value;};

function replace(before,after) {
  assert.equal(source.split(before).length,2,'Shared smoke2 patch point changed');
  source = source.replace(before,after);
}
replace('createRequire(process.cwd() + "/")("playwright-core")', `createRequire(${JSON.stringify(path.join(tools,'scripts/package.json'))})("playwright-core")`);
replace('width: 1280, height: 900','width: 1440, height: 900');
replace('const p = await ctx.newPage();','const p = await ctx.newPage();\nawait globalThis.smokeSetup({b,ctx,p,email,pw});');
replace('res.signup = await wizard("signup");','res.signup = await wizard("signup");\n  res.signup = (await globalThis.smokeSession("signup",true)) && res.signup;');
replace('res.login = await wizard("login");','res.login = await wizard("login");\n  res.login = (await globalThis.smokeSession("login",true)) && res.login;');
replace('async function logout() {','async function logout() {\n  await globalThis.smokeAccount("account-" + (res.logout1 ? "login" : "signup"));');
replace('res.logout1 = !lo.session;','res.logout1 = (await globalThis.smokeSession("logout1",false)) && !lo.session;');
replace('res.logout2 = !lo.session;','res.logout2 = (await globalThis.smokeSession("logout2",false)) && !lo.session;');
replace('await p.screenshot({ path: `/workspace/isdead-shots/smoke/${tag}-end.png` }).catch(() => {});','');
replace('console.log("RESULT " + JSON.stringify(res));','globalThis.smokeResult(res);');
replace('await b.close();','');
if (process.argv.includes('--check')) {
  execFileSync(process.execPath,['--check','--input-type=module'],{input:source,stdio:['pipe','inherit','inherit']});
  console.log('Pinned smoke2 hooks and generated module syntax verified; no browser or account used.');
  process.exit(0);
}
process.argv = [process.execPath,'smoke2.mjs',base,`wispr-${mode}-${process.env.GITHUB_RUN_ID || 'local'}`];

async function firebase(operation,data) {
  const response = await context.request.post(`https://identitytoolkit.googleapis.com/v1/accounts:${operation}?key=${encodeURIComponent(apiKey)}`,
    {data,timeout:15000});
  const body = await response.json().catch(() => ({}));
  return {ok:response.ok(),body};
}
async function cleanup() {
  await Promise.allSettled(responses);
  if (!context || !apiKey) return {account:'not-started',session:'not-started'};
  let account = 'failed', failure;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      if (!token) {
        const login = await firebase('signInWithPassword',{email,password,returnSecureToken:true});
        if (!login.ok) {
          const code = login.body.error?.message;
          if (!state.accountObserved && ['EMAIL_NOT_FOUND','INVALID_LOGIN_CREDENTIALS'].includes(code)) {account = 'no-matching-account'; break;}
          throw Error('Cleanup sign-in: ' + code);
        }
        assert.ok(login.body.email === email,'Cleanup identity mismatch');
        token = login.body.idToken; uid = login.body.localId;
      }
      const lookup = await firebase('lookup',{idToken:token});
      if (!lookup.ok && lookup.body.error?.message === 'USER_NOT_FOUND') {account = 'already-deleted'; break;}
      assert.ok(lookup.ok,'Cleanup identity lookup failed');
      assert.equal(lookup.body.users?.length,1,'Cleanup identity count mismatch');
      assert.ok(lookup.body.users[0].email === email,'Refusing to delete a different account');
      assert.ok(lookup.body.users[0].localId === uid,'Cleanup UID mismatch');
      const deletion = await firebase('delete',{idToken:token});
      assert.ok(deletion.ok,'Account deletion failed: ' + deletion.body.error?.message);
      account = 'deleted'; break;
    } catch (error) {
      failure = safe(error.message); token = undefined;
      if (attempt < 2) await new Promise(resolve => setTimeout(resolve,1000 * (attempt + 1)));
    }
  }
  let session = 'failed';
  try {
    const response = await context.request.delete(base + '/api/session',{timeout:15000});
    if (response.status() === 204 && await globalThis.smokeSession('cleanup',false)) session = 'cleared';
  } catch (error) {failure ||= safe(error.message);}
  return {account,session,...(account === 'failed' || session === 'failed' ? {failure,email,uid} : {})};
}
try {await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));}
catch (error) {state.failure = safe(error.message);}
finally {
  try {state.cleanup = await cleanup();}
  catch (error) {state.cleanup = {account:'failed',failure:safe(error.message),email,uid};}
  state.flow = result ? {signup:result.signup,logout1:result.logout1,login:result.login,logout2:result.logout2,notes:result.notes.map(safe),errors:result.errs.map(safe)} : null;
  state.passed = Boolean(state.flow && ['signup','logout1','login','logout2'].every(key => state.flow[key]) &&
    state.flow.errors.length === 0 && state.cleanup.account === 'deleted' && state.cleanup.session === 'cleared' && !state.failure);
  await writeFile(path.join(output,`${mode}.json`),JSON.stringify(state,null,2));
  console.log(JSON.stringify(state));
  await browser?.close();
  password = token = undefined;
}
if (!state.passed) process.exitCode = 1;
