const fs = require('node:fs');
const path = require('node:path');
const { root, readSecrets, renderTemplate, getAuthSecret } = require('./runtime-config');

function findTemplates(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    if (entry.name.startsWith('node_modules') || ['.git', '.next', '.mastra', 'dist', 'build', 'coverage'].includes(entry.name)) return [];
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) return findTemplates(file);
    return entry.name === '.env.audit-template' ? [file] : [];
  });
}

if (require.main === module) {
  const secrets = readSecrets();
  const auth = getAuthSecret();
  const rendered = findTemplates(path.join(root, 'apps')).map(file => {
    const { target, text } = renderTemplate(fs.readFileSync(file, 'utf8'), secrets, auth);
    return { file: path.join(path.dirname(file), target), text };
  });
  if (!rendered.length) throw new Error('No runtime templates found. Extract apps and apply patches first.');
  for (const { file, text } of rendered) fs.writeFileSync(file, text, { mode: 0o600 });
  console.log(`Rendered ${rendered.length} local environment files; credentials were not printed.`);
}

module.exports = { findTemplates };
