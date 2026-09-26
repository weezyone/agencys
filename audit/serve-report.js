const http = require('http');
const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, 'report.html');
http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(fs.readFileSync(file));
}).listen(8099, '127.0.0.1', () => console.log('report on http://localhost:8099'));
