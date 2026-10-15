const http = require('http');
const db = require('./db');

const PORT = process.env.PORT || 3001;

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end(JSON.stringify(data));
}

const server = http.createServer((req, res) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    res.end();
    return;
  }

  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === '/api/health' && req.method === 'GET') {
    return sendJson(res, 200, { status: 'ok', app: 'Vibe Study Timer Mobile API', version: '1.0.0' });
  }

  if (url.pathname === '/api/sessions' && req.method === 'GET') {
    const sessions = db.getSessions();
    const stats = db.getStats();
    return sendJson(res, 200, { success: true, sessions, stats });
  }

  if (url.pathname === '/api/sessions' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const session = db.addSession(payload);
        const stats = db.getStats();
        return sendJson(res, 201, { success: true, session, stats });
      } catch (err) {
        return sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
      }
    });
    return;
  }

  if (url.pathname === '/api/prompts' && req.method === 'GET') {
    const prompts = db.getPrompts();
    return sendJson(res, 200, { success: true, prompts });
  }

  if (url.pathname === '/api/prompts' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const prompt = db.addPrompt(payload);
        return sendJson(res, 201, { success: true, prompt });
      } catch (err) {
        return sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
      }
    });
    return;
  }

  if (url.pathname === '/api/stats' && req.method === 'GET') {
    return sendJson(res, 200, { success: true, stats: db.getStats() });
  }

  sendJson(res, 404, { success: false, error: 'Route not found' });
});

server.listen(PORT, () => {
  console.log(`📱 Vibe Study Timer Mobile API running on http://localhost:${PORT}`);
});
