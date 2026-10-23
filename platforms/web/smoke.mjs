#!/usr/bin/env node
// Smoke test of a web export: serves a folder (index.html, factoria_player.js/.wasm, game.pak), opens it in a headless
// Chrome or Edge (software WebGL2) and waits for the player's run marker, "60 frames rendered" (the same line the Android and
// iOS smoke tests wait for). Fails on a page error, a console.error line, or when the marker does not come in time.
//
//   node platforms/web/smoke.mjs <export folder> [--browser <path>] [--timeout <seconds>] [--screenshot <png>]
//                                [--type <text> --expect <console line>]
//
// --type: once the frames are rendered, clicks the canvas and types <text> with real key events (CDP Input.dispatchKeyEvent:
// keydown, keypress and input, like a keyboard), and waits for a console line containing <text> after --expect (the game
// logs what its TextField holds). The web player takes typed text from the keypress events of the window, so this is the
// check that typing works in a browser; scripts/web-smoke.sh puts a TextField in the game for it.
//
// The browser: --browser, else $CHROME_BIN, else the first of google-chrome, chromium, chrome, msedge found in PATH or in
// the usual install folders of Windows and macOS. Needs Node 22 or newer (built-in WebSocket and fetch), nothing to install.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(name);
  return i >= 0 ? args.splice(i, 2)[1] : fallback;
};
const browserArg = opt('--browser', process.env.CHROME_BIN || '');
const timeoutMs = Number(opt('--timeout', '60')) * 1000;
const screenshot = opt('--screenshot', '');
const typeText = opt('--type', '');
const expectPrefix = opt('--expect', '');
const dir = args[0];
if (!dir || !fs.existsSync(path.join(dir, 'index.html'))) {
  console.error('usage: node smoke.mjs <export folder with index.html> [--browser path] [--timeout seconds] [--screenshot out.png] [--type text --expect prefix]');
  process.exit(2);
}

function findBrowser() {
  if (browserArg) return browserArg;
  const names = process.platform === 'win32' ? ['chrome.exe', 'msedge.exe'] : ['google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser', 'chrome', 'microsoft-edge', 'msedge'];
  const places = [
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  ];
  for (const p of places) if (fs.existsSync(p)) return p;
  for (const d of (process.env.PATH || '').split(path.delimiter))
    for (const n of names) if (d && fs.existsSync(path.join(d, n))) return path.join(d, n);
  console.error('no Chrome, Chromium or Edge found: pass --browser <path> or set CHROME_BIN');
  process.exit(2);
}

const types = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pak': 'application/octet-stream', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(new URL(req.url, 'http://x').pathname).replace(/^\/+/, '') || 'index.html';
  const file = path.resolve(dir, rel);
  if (!file.startsWith(path.resolve(dir)) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) { res.writeHead(404).end('not found'); return; }
  res.writeHead(200, { 'content-type': types[path.extname(file)] || 'application/octet-stream', 'content-length': fs.statSync(file).size });
  fs.createReadStream(file).pipe(res);  // no COOP/COEP headers on purpose: the player must not need them
});
await new Promise((r) => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}/index.html`;

const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'fa-web-smoke-'));
const browser = spawn(findBrowser(), [
  '--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--remote-debugging-port=0', `--user-data-dir=${profile}`,
  '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-webgl',
  '--autoplay-policy=no-user-gesture-required', '--window-size=1280,720', '--no-first-run', 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });

let code = 1;
function finish(status, why) {
  if (why) console.log(why);
  code = status;
  try { browser.kill(); } catch {}
  server.close();
  setTimeout(() => { try { fs.rmSync(profile, { recursive: true, force: true }); } catch {} process.exit(code); }, 500);
}
const timer = setTimeout(() => finish(1, `FAIL: no "60 frames rendered" line within ${timeoutMs / 1000} s`), timeoutMs);

const wsUrl = await new Promise((resolve) => {
  let buf = '';
  browser.stderr.on('data', (d) => {
    buf += d;
    const m = buf.match(/DevTools listening on (ws:\/\/\S+)/);
    if (m) resolve(m[1]);
  });
  browser.on('exit', () => resolve(null));
});
if (!wsUrl) finish(1, 'FAIL: the browser did not start');
else {
  const ws = new WebSocket(wsUrl);
  let nextId = 1;
  let typing = false, typeTimer = null;
  const pending = new Map();
  const send = (method, params = {}, sessionId) => new Promise((resolve) => {
    const id = nextId++;
    pending.set(id, resolve);
    ws.send(JSON.stringify({ id, method, params, sessionId }));
  });
  // Clicks the middle of the canvas (it takes the keyboard focus, as a player's click does), then presses each character
  // of typeText as a key: keydown with text, which the browser turns into keypress and input, and keyup.
  async function typeIntoPage(sessionId) {
    const wait = (ms) => new Promise((r) => setTimeout(r, ms));
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 640, y: 360, button: 'left', clickCount: 1 }, sessionId);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 640, y: 360, button: 'left', clickCount: 1 }, sessionId);
    await wait(300);
    for (const ch of typeText) {
      const upper = ch.toUpperCase();
      const key = { key: ch, text: ch, unmodifiedText: ch, code: /[a-z]/i.test(ch) ? `Key${upper}` : /[0-9]/.test(ch) ? `Digit${ch}` : '', windowsVirtualKeyCode: upper.charCodeAt(0) };
      await send('Input.dispatchKeyEvent', { type: 'keyDown', ...key }, sessionId);
      await send('Input.dispatchKeyEvent', { type: 'keyUp', ...key, text: undefined, unmodifiedText: undefined }, sessionId);
      await wait(50);  // a frame or three: each character arrives on its own
    }
  }
  ws.onmessage = async (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg.result || msg.error); pending.delete(msg.id); return; }
    if (msg.method === 'Runtime.consoleAPICalled') {
      const text = msg.params.args.map((a) => a.value ?? a.description ?? '').join(' ');
      console.log(`[console.${msg.params.type}] ${text}`);
      if (msg.params.type === 'error') { clearTimeout(timer); finish(1, `FAIL: console.error: ${text}`); }
      if (typing && text.includes(expectPrefix + typeText)) {
        clearTimeout(typeTimer);
        finish(0, `OK: the player rendered 60 frames and the field took "${typeText}"`);
      } else if (/60 frames rendered/.test(text) && !typing) {
        clearTimeout(timer);
        if (screenshot) {
          const shot = await send('Page.captureScreenshot', { format: 'png' }, msg.sessionId);
          if (shot.data) fs.writeFileSync(screenshot, Buffer.from(shot.data, 'base64'));
        }
        if (!typeText) finish(0, 'OK: the player rendered 60 frames');
        else {
          typing = true;
          typeTimer = setTimeout(() => finish(1, `FAIL: typed "${typeText}" into the page but the game never logged "${expectPrefix}${typeText}"`), 20000);
          await typeIntoPage(msg.sessionId);
        }
      }
    } else if (msg.method === 'Runtime.exceptionThrown') {
      const d = msg.params.exceptionDetails;
      clearTimeout(timer);
      finish(1, `FAIL: page error: ${d.exception?.description || d.text}`);
    } else if (msg.method === 'Log.entryAdded' && msg.params.entry.level === 'error') {
      console.log(`[log.error] ${msg.params.entry.text} ${msg.params.entry.url || ''}`);
      if (/favicon/.test(msg.params.entry.url || '')) return;  // a missing favicon is not a failure
      clearTimeout(timer);
      finish(1, `FAIL: ${msg.params.entry.text} ${msg.params.entry.url || ''}`);
    }
  };
  ws.onopen = async () => {
    const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
    const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
    await send('Runtime.enable', {}, sessionId);
    await send('Log.enable', {}, sessionId);
    await send('Page.enable', {}, sessionId);
    await send('Page.navigate', { url }, sessionId);
  };
}
