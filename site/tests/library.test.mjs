import {test} from 'node:test';
import assert from 'node:assert/strict';
import {Library, LIBRARY_KEY, polishWithLibrary} from '../wisprflowisdead/assets/library.mjs';
function setup() {
  const data = new Map(); let next = 0, time = 10;
  const storage = {getItem:key => data.get(key) ?? null, setItem:(key,value) => data.set(key,value), removeItem:key => data.delete(key)};
  const library = new Library({storage, id:() => `id-${++next}`, now:() => ++time});
  return {library, storage, data};
}
const word = (trigger, value = trigger) => ({kind:'dictionary',trigger,value});
const snippet = (trigger, value) => ({kind:'snippet',trigger,value});
test('None skips dictionary and exact snippets; Medium preserves saved literal text', () => {
  const entries = [word('open aye','OpenAI'), snippet('my phrase','In order to Keep THIS')];
  assert.equal(polishWithLibrary('um open aye question mark',{entries,cleanup:'none'}),'um open aye question mark');
  assert.equal(polishWithLibrary('my phrase',{entries,cleanup:'none'}),'my phrase');
  assert.equal(polishWithLibrary('my phrase',{entries,cleanup:'medium'}),'In order to Keep THIS');
  assert.equal(polishWithLibrary('in order to use my phrase',{entries,cleanup:'medium'}),'To use In order to Keep THIS');
});
test('page-only library creates, edits and removes without writing browser storage', () => {
  const {library,data} = setup(); const entry = library.save(word('wisper','Wispr'));
  const edit = library.save({...entry,value:'WisprFlowIsDead'},entry.updatedAt);
  assert.equal(library.entries.length,1); assert.ok(edit.updatedAt > entry.updatedAt); assert.equal(data.size,0);
  library.remove(entry.id); assert.equal(library.entries.length,0);
});
test('opt-in storage restores entries and disabling it removes only the saved copy', () => {
  const {library,storage,data} = setup(); const entry = library.save(snippet('my sign off','Thanks,\nA person'));
  library.setRemember(true);
  const restored = new Library({storage}); restored.load();
  assert.equal(restored.remember,true); assert.deepEqual(restored.entries,[entry]);
  data.set('another-app','preserved'); library.setRemember(false);
  assert.equal(library.entries.length,1); assert.equal(data.get('another-app'),'preserved'); assert.equal(data.has(LIBRARY_KEY),false);
  library.clear(); assert.equal(library.entries.length,0);
});
test('failed writes and cross-tab changes preserve existing entries and editing data', () => {
  const {library,storage,data} = setup(); const entry = library.save(word('Name')); library.setRemember(true);
  const saved = data.get(LIBRARY_KEY); storage.setItem = () => {throw Error('Quota exceeded');};
  assert.throws(() => library.save({...entry,value:'Changed'}),/could not be saved/);
  assert.deepEqual(library.entries,[entry]); assert.equal(data.get(LIBRARY_KEY),saved);
  data.set(LIBRARY_KEY,JSON.stringify({version:1,entries:[]}));
  assert.throws(() => library.remove(entry.id),/another tab/); assert.deepEqual(library.entries,[entry]);
});
test('failed deletion does not falsely report forgotten data', () => {
  const {library,storage} = setup(); library.save(word('Name')); library.setRemember(true);
  storage.removeItem = () => {throw Error('Blocked');};
  assert.throws(() => library.clear(),/could not be removed/);
  assert.equal(library.remember,true); assert.equal(library.entries.length,1);
});
test('unreadable or incompatible stored data stays intact until explicit clearing', () => {
  for (const value of ['', '{broken',JSON.stringify({version:2,entries:[]}),JSON.stringify({version:1,entries:[{kind:'snippet'}]})]) {
    const {library,data} = setup(); data.set(LIBRARY_KEY,value);
    assert.throws(() => library.load(),/not been overwritten/); assert.equal(data.get(LIBRARY_KEY),value);
    library.save(word('Temporary')); assert.throws(() => library.setRemember(true),/unreadable/);
    library.clear(); assert.equal(data.has(LIBRARY_KEY),false); library.setRemember(true);
  }
});
test('validation rejects cross-library duplicate triggers, empty entries and overlong values', () => {
  const {library} = setup(); library.save(word('  Proper Name  '));
  assert.throws(() => library.save(snippet('proper name','Expansion')),/already/);
  for (const entry of [word('   '),word('!!!'),word('x'.repeat(61)),word('valid','x'.repeat(61)),snippet('valid',' '),snippet('valid','x'.repeat(4001))]) assert.throws(() => library.save(entry));
  assert.equal(library.entries.length,1);
});
test('search, star sorting and stale edits use the actual entry state', () => {
  const {library} = setup(); const first = library.save(word('zee','Zeta')); library.save(word('alpha','Alpha'));
  const starred = library.save({...first,starred:true},first.updatedAt);
  assert.equal(library.list('dictionary','', 'starred')[0].id,first.id);
  assert.equal(library.list('dictionary','zet')[0].id,first.id);
  assert.equal(library.list('dictionary','', 'alphabetical')[0].trigger,'alpha');
  assert.throws(() => library.save({...first,value:'Stale'},first.updatedAt),/changed/);
  assert.equal(library.entries.find(item=>item.id===first.id).value,starred.value);
});
test('longest phrase wins and expansions are literal, case-preserving and nonrecursive', () => {
  const entries = [snippet('short','a+b $1 <name>'),snippet('short phrase','Keep THIS\n\nexact.'),word('THIS','changed')];
  assert.equal(polishWithLibrary('SHORT, PHRASE!',{entries,style:'very-casual'}),'Keep THIS\n\nexact.');
  assert.equal(polishWithLibrary('please use short phrase tomorrow',{entries}),'Please use Keep THIS\n\nexact. tomorrow.');
  assert.equal(polishWithLibrary('short',{entries}),'a+b $1 <name>');
});
test('whole-word matching preserves contractions, URLs, email and inline code', () => {
  const entries = [word('don','Dawn'),word('cat','CAT'),word('a+b','APlusB')];
  assert.equal(polishWithLibrary("don and don't and DON’T and don's",{entries}),"Dawn and don't and DON’T and Dawn's.");
  assert.equal(polishWithLibrary('cat concatenate cat_id',{entries}),'CAT concatenate cat_id.');
  assert.equal(polishWithLibrary('a+b',{entries}),'APlusB.');
  assert.equal(polishWithLibrary('cat https://example.com/cat CAT@Example.com `cat`',{entries}),'CAT https://example.com/cat CAT@Example.com `cat`');
});
test('personal words keep their spelling through styles and work in non-English output', () => {
  const entries = [word('muck stack','MuckStack'),snippet('saludo','¡Hola!')];
  assert.equal(polishWithLibrary('um hello muck stack',{entries}),'Hello MuckStack.');
  assert.equal(polishWithLibrary('hello muck stack',{entries,style:'very-casual'}),'hello MuckStack');
  assert.equal(polishWithLibrary('muck stack',{entries,language:'es-ES'}),'MuckStack');
  assert.equal(polishWithLibrary('SALUDO!',{entries,language:'es-ES'}),'¡Hola!');
  assert.equal(polishWithLibrary('keep \uE0000\uE001 and muck stack',{entries}),'Keep \uE0000\uE001 and MuckStack.');
});
