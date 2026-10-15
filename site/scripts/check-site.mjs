// Static site validation: parse JS (without running APIs) and verify local assets.
// This site is deployed as source HTML/CSS/JS; it does not need a bundler.
import {readdir, readFile, access} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root = fileURLToPath(new URL('../', import.meta.url));
async function files(directory) {
  const result = [];
  for (const item of await readdir(directory, {withFileTypes:true})) {
    if (['node_modules','.vercel'].includes(item.name)) continue;
    const filename = path.join(directory,item.name);
    if (item.isDirectory()) result.push(...await files(filename)); else result.push(filename);
  }
  return result;
}
let count = 0;
function syntax(source, type, label) {
  const check = spawnSync(process.execPath, ['--check', '--input-type='+type], {input:source, encoding:'utf8'});
  if (check.status !== 0) throw Error(`${label}\n${check.stderr}`);
  count++;
}
for (const filename of await files(root)) {
  if (!/\.(?:m?js|cjs|html|css)$/.test(filename)) continue;
  const source = await readFile(filename, 'utf8');
  if (/\.(?:m?js|cjs)$/.test(filename)) syntax(source, filename.endsWith('.mjs') ? 'module' : 'commonjs', filename);
  if (filename.endsWith('.html')) {
    for (const [,attributes,body] of source.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)) {
      if (/\bsrc=/.test(attributes) || /type=["']application\//.test(attributes)) continue;
      syntax(body, /type=["']module/.test(attributes) ? 'module' : 'commonjs', filename+' inline script');
    }
    for (const [,url] of source.matchAll(/(?:href|src)=["'](\/wisprflowisdead\/assets\/[^"']+)["']/g)) {
      await access(path.join(root,url.split(/[?#]/)[0]));
    }
  }
  if (filename.endsWith('.css')) {
    for (const [,url] of source.matchAll(/url\(["']?([^\s)'";]+)["']?\)/g)) {
      if (/^(?:data:|https?:|#)/.test(url)) continue;
      await access(url.startsWith('/') ? path.join(root,url) : path.resolve(path.dirname(filename),url));
    }
  }
}
console.log(`Static website verified: ${count} JavaScript sources parsed; referenced local HTML/CSS assets exist. No bundling required.`);
