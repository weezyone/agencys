const fs = require('node:fs');
const path = require('node:path');
const { readSecrets, runtime } = require('./runtime-config');

async function main() {
  const secrets = readSecrets();
  const evidence = { checkedAt: new Date().toISOString(), model: secrets.NIM_MODEL };
  try {
    const response = await fetch(`${secrets.NIM_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${secrets.NVIDIA_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: secrets.NIM_MODEL, messages: [{ role: 'user', content: 'Reply with only OK.' }], max_tokens: 128, stream: false, chat_template_kwargs: { enable_thinking: false } }),
      signal: AbortSignal.timeout(180000),
    });
    evidence.nim = { status: response.status, ok: false };
    if (response.ok) {
      const body = await response.json();
      evidence.nim.ok = Boolean(body.choices?.[0]?.message?.content?.trim());
      evidence.nim.returnedModel = body.model;
      evidence.nim.hasContent = evidence.nim.ok;
    }
  } catch (error) { evidence.nim = { ok: false, errorType: error.name }; }
  let client;
  try {
    const { MongoClient } = require('mongodb');
    client = new MongoClient(secrets.MONGODB_URI, { serverSelectionTimeoutMS: 15000, connectTimeoutMS: 15000 });
    await client.connect();
    await client.db('admin').command({ ping: 1 });
    evidence.mongodb = { ok: true, test: 'authenticated ping (no data written)' };
  } catch (error) { evidence.mongodb = { ok: false, errorType: error.name, code: error.code }; }
  finally { if (client) await client.close(); }
  fs.mkdirSync(runtime, { recursive: true });
  fs.writeFileSync(path.join(runtime, 'connections.json'), JSON.stringify(evidence, null, 2));
  console.log(JSON.stringify(evidence, null, 2));
  if (!evidence.nim.ok || !evidence.mongodb.ok) process.exitCode = 1;
}
main().catch(error => { console.error(error.name); process.exitCode = 1; });
