// Anonymous visual preview only; this is not the Vercel/auth runtime.
import {createServer} from 'node:http';
import {readFile, realpath} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = await realpath(fileURLToPath(new URL('../site/wisprflowisdead/', import.meta.url)));
const missingPage = await readFile(new URL('../site/404.html', import.meta.url));
const prefix = '/wisprflowisdead';
const types = {'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.js':'text/javascript; charset=utf-8','.png':'image/png','.webp':'image/webp','.svg':'image/svg+xml','.woff2':'font/woff2'};
const server = createServer(async (req, res) => {
  function send(status, body, type = 'application/json') {
    res.writeHead(status, {'content-type':type, 'cache-control':'no-store'});
    res.end(req.method === 'HEAD' ? undefined : body);
  }
  const notFound = () => send(404, missingPage, 'text/html; charset=utf-8');
  if (!['GET','HEAD'].includes(req.method)) return send(405, '{"error":"Read-only QA preview"}');
  let pathname;
  try {pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);}
  catch {return send(400, '{"error":"Invalid URL"}');}
  if (pathname === '/__qa_health') return send(200, '{"ok":true,"auth":"unavailable"}');
  if (pathname === prefix + '/api/session') return send(401, '{"error":"Anonymous QA preview; no sessions"}');
  if (pathname === prefix + '/api/config') {
    try {
      // Fixed public endpoint only: never forward caller cookies, tokens or headers.
      const response = await fetch('https://yourappisdead.com/wisprflowisdead/api/config', {signal:AbortSignal.timeout(10000)});
      if (!response.ok) throw Error('Public configuration unavailable');
      const data = await response.json();
      return send(200, JSON.stringify({firebase:data.firebase ?? null, downloadUrl:data.downloadUrl ?? null}));
    } catch {return send(502, '{"error":"Public configuration unavailable"}');}
  }
  if (pathname !== prefix && !pathname.startsWith(prefix + '/')) return notFound();
  let relative = pathname.slice(prefix.length).replace(/^\/+/, '') || 'index.html';
  if (!path.extname(relative)) relative += '.html';
  try {
    const file = await realpath(path.resolve(root, relative));
    if (!file.startsWith(root + path.sep)) return notFound();
    const type = types[path.extname(file)];
    if (!type) return notFound();
    send(200, await readFile(file), type);
  } catch {notFound();}
});
server.listen(Number(process.argv[2] || 3300), '127.0.0.1', () => console.log('Anonymous QA preview listening on', server.address().port));
