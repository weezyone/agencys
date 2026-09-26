const fs = require('fs');
const path = require('path');

const here = __dirname;
const projects = JSON.parse(fs.readFileSync(path.join(here, 'report-data.json'), 'utf8'));

let health = [];
try { health = JSON.parse(fs.readFileSync(path.join(here, 'health.json'), 'utf8')); } catch (e) {}

const payload = { projects, health, generated: new Date().toISOString() };

const tpl = fs.readFileSync(path.join(here, 'report.template.html'), 'utf8');
const out = tpl.replace('/*__DATA__*/null', JSON.stringify(payload));
fs.writeFileSync(path.join(here, 'report.html'), out);
console.log('wrote report.html (' + out.length + ' bytes, ' + projects.length + ' projects, ' + health.length + ' health rows)');
