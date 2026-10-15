const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { runInNewContext } = require('node:vm');
const script = readFileSync(require('node:path').join(__dirname, '../wisprflowisdead/assets/account.js'), 'utf8');
const tick = () => new Promise(resolve => setImmediate(resolve));
const response = (status, value) => ({ status, ok: status >= 200 && status < 300, json: async () => value });

async function page(fetch) {
  const nodes = Object.fromEntries(['box', 'loading', 'retry', 'load-status', 'who', 'out', 'signout-status'].map(id => [id, {
    hidden: id === 'box', textContent: '', attrs: {}, setAttribute(key, value) { this.attrs[key] = value; }
  }]));
  const redirects = [], events = {};
  runInNewContext(script, {
    document: { getElementById: id => nodes[id] }, fetch, AbortSignal,
    location: { replace: url => redirects.push(url) }, addEventListener: (name, fn) => { events[name] = fn; }
  });
  await tick();
  return { nodes, redirects, events };
}

test('expired sessions go to login with a return path', async () => {
  const p = await page(async () => response(401));
  assert.deepEqual(p.redirects, ['/wisprflowisdead/login?next=/wisprflowisdead/app']);
  assert.equal(p.nodes.box.hidden, true);
});

test('network, server and malformed-response failures remain retryable', async () => {
  for (const fail of [async () => { throw Error('offline'); }, async () => response(503), async () => response(200, null), async () => ({ok:true, json:async () => {throw Error('bad JSON');}})]) {
    let attempt = 0;
    const p = await page(async () => ++attempt === 1 ? fail() : response(200, {email:'qa@example.com'}));
    assert.deepEqual(p.redirects, []);
    assert.equal(p.nodes.box.hidden, true);
    assert.equal(p.nodes.retry.hidden, false);
    assert.equal(p.nodes.loading.attrs['aria-busy'], 'false');
    await p.nodes.retry.onclick();
    assert.equal(p.nodes.box.hidden, false);
    assert.equal(p.nodes.loading.hidden, true);
    assert.equal(p.nodes.who.textContent, 'Signed in as qa@example.com.');
  }
});

test('failed sign-out preserves the account and allows retry', async () => {
  let deletes = 0;
  const p = await page(async (_, options) => options.method === 'DELETE' ? response(++deletes === 1 ? 503 : 204) : response(200, {email:'qa@example.com'}));
  await p.nodes.out.onclick();
  assert.deepEqual(p.redirects, []);
  assert.equal(p.nodes.box.hidden, false);
  assert.match(p.nodes['signout-status'].textContent, /may still be active/);
  assert.equal(p.nodes.out.disabled, false);
  await p.nodes.out.onclick();
  assert.deepEqual(p.redirects, ['/wisprflowisdead']);
});

test('double click sends one DELETE and network rejection restores controls', async () => {
  let reject, deletes = 0;
  const p = await page(async (_, options) => options.method === 'DELETE' ? (++deletes, new Promise((_, no) => { reject = no; })) : response(200, {}));
  const pending = p.nodes.out.onclick();
  await p.nodes.out.onclick();
  assert.equal(deletes, 1);
  assert.equal(p.nodes.out.disabled, true);
  reject(Error('offline'));
  await pending;
  assert.equal(p.nodes.out.disabled, false);
  assert.deepEqual(p.redirects, []);
});

test('back-forward cache rechecks identity and hides stale account details', async () => {
  let calls = 0;
  const p = await page(async () => response(++calls === 1 ? 200 : 401, {email:'qa@example.com'}));
  p.events.pageshow({persisted:true});
  assert.equal(p.nodes.box.hidden, true);
  await tick();
  assert.equal(calls, 2);
  assert.equal(p.redirects.length, 1);
});
