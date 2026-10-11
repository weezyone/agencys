const test = require('node:test');
const assert = require('node:assert/strict');
const { mongoFor, renderTemplate, safePath } = require('./runtime-config');

test('Mongo database isolation preserves authentication and query options', () => {
  assert.equal(mongoFor('mongodb+srv://user:pass@cluster.test/old?retryWrites=true&w=majority', 'audit_app'), 'mongodb+srv://user:pass@cluster.test/audit_app?retryWrites=true&w=majority');
  assert.equal(mongoFor('mongodb://localhost:27017/', 'audit_app'), 'mongodb://localhost:27017/audit_app');
  assert.throws(() => mongoFor('', 'audit_app'), /required/);
  assert.throws(() => mongoFor('mongodb://localhost', '../bad'), /Invalid/);
});

test('Templates require explicit credentials and cannot escape their directory', () => {
  const template = '#TARGET=.env.local\nMODEL={{NIM_MODEL}}\nDB={{MONGO:agency_test}}\nKEY={{NVIDIA_API_KEY}}\nSECRET={{AUTH_SECRET}}\n';
  const secrets = { NIM_MODEL: 'z-ai/glm-5.3-flash', MONGODB_URI: 'mongodb://localhost', NVIDIA_API_KEY: 'test-placeholder' };
  const rendered = renderTemplate(template, secrets, 'test-auth');
  assert.equal(rendered.target, '.env.local');
  assert.match(rendered.text, /MODEL=z-ai\/glm-5.3-flash/);
  assert.match(rendered.text, /DB=mongodb:\/\/localhost\/agency_test/);
  assert.doesNotMatch(rendered.text, /\{\{|#TARGET/);
  assert.throws(() => renderTemplate(template, {}, 'test'), /Missing configuration/);
  assert.throws(() => renderTemplate('#TARGET=..\\secrets\n', secrets, 'test'), /Invalid template/);
  assert.throws(() => safePath('..\\outside'), /within this workspace/);
});
