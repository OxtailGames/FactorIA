#!/usr/bin/env node
// A WebSocket echo server for the web smoke test (scripts/web-smoke.sh): the exported game opens it with the browser's
// WebSocket (engine/platform/src/websocket_web.cpp). It answers the handshake (and picks the first subprotocol the page
// offers), echoes text and binary messages, answers pings and answers a close frame with the same code. It reads whole
// frames only (no fragments): the smoke game sends short messages. Nothing leaves 127.0.0.1.
//
//   node platforms/web/ws-echo.mjs <port>      (runs until it is killed; web-smoke.sh does that)
import crypto from 'node:crypto';
import http from 'node:http';

const port = Number(process.argv[2]);
if (!port) { console.error('usage: node ws-echo.mjs <port>'); process.exit(2); }

function frame(opcode, payload) {
  const n = payload.length;
  const head = n < 126 ? Buffer.from([0x80 | opcode, n]) : Buffer.from([0x80 | opcode, 126, n >> 8, n & 255]);
  return Buffer.concat([head, payload]);
}

const server = http.createServer((req, res) => { res.writeHead(426).end('upgrade required'); });
server.on('upgrade', (req, socket) => {
  const key = req.headers['sec-websocket-key'];
  const protocol = (req.headers['sec-websocket-protocol'] || '').split(',')[0].trim();
  const accept = crypto.createHash('sha1').update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
  socket.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n' +
    `Sec-WebSocket-Accept: ${accept}\r\n` + (protocol ? `Sec-WebSocket-Protocol: ${protocol}\r\n` : '') + '\r\n');
  console.log(`connection: origin ${req.headers.origin} protocol "${protocol}"`);
  let buffer = Buffer.alloc(0);
  socket.on('data', (chunk) => {
    buffer = Buffer.concat([buffer, chunk]);
    for (;;) {
      if (buffer.length < 2) return;
      const opcode = buffer[0] & 15;
      let length = buffer[1] & 127, offset = 2;
      if (length === 126) { if (buffer.length < 4) return; length = buffer.readUInt16BE(2); offset = 4; }
      else if (length === 127) { if (buffer.length < 10) return; length = Number(buffer.readBigUInt64BE(2)); offset = 10; }
      const masked = (buffer[1] & 128) !== 0;
      if (buffer.length < offset + (masked ? 4 : 0) + length) return;
      const mask = masked ? buffer.subarray(offset, offset + 4) : null;
      if (masked) offset += 4;
      const payload = Buffer.from(buffer.subarray(offset, offset + length));
      if (mask) for (let i = 0; i < payload.length; i++) payload[i] ^= mask[i & 3];
      buffer = buffer.subarray(offset + length);
      if (opcode === 1 || opcode === 2) socket.write(frame(opcode, payload));
      else if (opcode === 9) socket.write(frame(10, payload));
      else if (opcode === 8) { socket.write(frame(8, payload.subarray(0, 2))); socket.end(); return; }
    }
  });
  socket.on('error', () => {});
});
server.listen(port, '127.0.0.1', () => console.log(`ws-echo listening on 127.0.0.1:${port}`));
