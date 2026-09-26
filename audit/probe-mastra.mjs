import { Agent } from "@mastra/core/agent";
const a = new Agent({ id:"probe", name: "probe", instructions: "Reply with OK", model: process.env.MASTRA_MODEL || "nvidia/openai/gpt-oss-120b" });
try { const r = await a.generate("Say OK"); console.log("LLM OK:", r.text); }
catch (e) { console.log("LLM ERR:", e?.statusCode ?? "", e?.url ?? "", String(e?.message).slice(0,200)); }
