const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const root = path.resolve(__dirname, '..');
const runtime = path.join(__dirname, 'runtime');

function readSecrets(file = path.join(__dirname, 'secrets.env')) {
  const result = {};
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const match = line.match(/^\s*([A-Z_][A-Z0-9_]*)=(.*)$/);
    if (match) result[match[1]] = match[2].trim().replace(/^(['"])(.*)\1$/, '$2');
  }
  return result;
}

function mongoFor(uri, database) {
  if (!/^[a-zA-Z0-9_-]+$/.test(database)) throw new Error('Invalid database name');
  if (!uri || !/^mongodb(?:\+srv)?:\/\/[^/]+/.test(uri)) throw new Error('MONGODB_URI is required');
  const query = uri.indexOf('?');
  const base = query === -1 ? uri : uri.slice(0, query);
  const authority = base.match(/^(mongodb(?:\+srv)?:\/\/[^/]+)/)[1];
  return `${authority}/${database}${query === -1 ? '' : uri.slice(query)}`;
}

function renderTemplate(template, secrets, authSecret) {
  const target = template.match(/^#TARGET=(.+)$/m)?.[1].trim();
  if (!target || !/^\.env(?:\.[a-zA-Z0-9_-]+)?$/.test(target)) throw new Error('Invalid template target');
  const values = { ...secrets, AUTH_SECRET: authSecret };
  const text = template.replace(/^#TARGET=.*\r?\n/m, '').replace(/\{\{([A-Z_]+)(?::([\w-]+))?\}\}/g, (_, key, db) => {
    if (key === 'MONGO') return mongoFor(secrets.MONGODB_URI, db);
    if (!values[key]) throw new Error(`Missing configuration: ${key}`);
    if (/[\r\n]/.test(values[key])) throw new Error(`Invalid multiline configuration: ${key}`);
    return values[key];
  });
  if (/\{\{.*\}\}/.test(text)) throw new Error('Unresolved template placeholder');
  return { target, text };
}

function safePath(relative) {
  const result = path.resolve(root, relative);
  if (!result.startsWith(root + path.sep)) throw new Error('Path must stay within this workspace');
  return result;
}

function loadGroups() {
  return fs.readdirSync(__dirname).filter(name => /^group-[\w-]+\.json$/.test(name))
    .flatMap(name => JSON.parse(fs.readFileSync(path.join(__dirname, name), 'utf8')));
}

function getAuthSecret() {
  fs.mkdirSync(runtime, { recursive: true });
  const file = path.join(runtime, 'auth-secret');
  if (!fs.existsSync(file)) fs.writeFileSync(file, crypto.randomBytes(32).toString('hex'), { mode: 0o600, flag: 'wx' });
  return fs.readFileSync(file, 'utf8').trim();
}

module.exports = { root, runtime, readSecrets, mongoFor, renderTemplate, safePath, loadGroups, getAuthSecret };
