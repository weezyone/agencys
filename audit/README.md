# AgencyOS Archive Audit

Every zip in the repository root is a prior iteration of the Paul Weezy Design agency app.
This directory is the result of extracting all 26 of them, scoring each one, wiring the
viable ones to NVIDIA NIM + MongoDB, and actually running them.

Open `report.html` for the interactive version (filter by verdict, search, live links to
each running app, expandable LLM/DB wiring detail per project).

```
node audit/serve-report.js     # then open http://localhost:8099
```

## Three findings that matter

**1. `openai/gpt-oss-120b` is retired on NVIDIA NIM.**
The endpoint returns `410 Gone`: "reached its end of life on 2026-09-03". Every project here
defaults to the live `openai/gpt-oss-20b` instead. For a 120B-class model use
`nvidia/nemotron-3-super-120b-a12b`. It is one line in `secrets.env`.

**2. The old Atlas cluster is gone.**
`cluster0.wtadcgr.mongodb.net` fails SRV lookup (NXDOMAIN). `mongo.js` stands up a local
MongoDB on `127.0.0.1:27017` as a stand-in. Paste a real Atlas URI into `secrets.env` and
every project picks it up.

**3. Two archives contain live-looking credentials. Rotate them.**
- `mastra-design-agent-main/.env.example` - OpenRouter key, Penpot token
- `workspace-codex-long-horizon-tasks-master/agency-os/.env` - Telegram bot token, Linear API key, Mongo URI

None of these were committed to git, but treat all of them as compromised.

## Setup

These scripts drive the extracted copies at `C:\Users\weezy\agencyos-audit\` (the extraction
target, deliberately outside git so 26 sets of `node_modules` never land in the repo). The
paths are hardcoded at the top of each `.ps1`; change `$root` if you extract elsewhere.

All 26 projects read from one file. Copy the example and fill it in:

```
cp audit/secrets.env.example audit/secrets.env
```

```
NVIDIA_API_KEY=nvapi-...
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net
NIM_MODEL=openai/gpt-oss-20b
```

Then render it into every project and start everything:

```
powershell -File audit/apply-runtime-fixes.ps1
powershell -File audit/apply-secrets.ps1
powershell -File audit/start-all.ps1
powershell -File audit/health.ps1
```

`apply-secrets.ps1` expands `{{NVIDIA_API_KEY}}`, `{{NIM_MODEL}}` and `{{MONGO:dbName}}`
inside each project's `.env.audit-template` (11 of them, listed in `templates.txt`).
Leave `MONGODB_URI` blank to keep using the local MongoDB.

## Results

15 processes across 9 projects come up green (HTTP 200).

| Project | Maturity | Verdict | Tier | Runs at | LOC |
| --- | --- | --- | --- | --- | --- |
| agency-pm (Atlas PM) | 88 | KEEP | core | http://localhost:4107 | 7,110 |
| digital-agency (cloud-first platform) | 86 | KEEP | core | - | 41,988 |
| ai-agency-mastra (workflows + RAG) | 84 | KEEP | core | http://localhost:5104 | 3,421 |
| AgencyOS v1 (8 agents) | 79 | KEEP | core | http://localhost:3102 | 6,667 |
| PaulWeezy MVP (client-facing) | 78 | KEEP | core | http://localhost:5105 | 8,668 |
| fabel | 78 | KEEP | core | http://localhost:3103 | 8,881 |
| codex-agency-2 (monorepo) | 78 | KEEP | core | http://localhost:3110 | 3,997 |
| agency-os-newerest | 72 | KEEP | core | http://localhost:3101 | 19,604 |
| mastra-design-agent | 72 | KEEP | specialist | http://localhost:3106 | 2,074 |
| agency-agent-platform (claude) | 72 | SALVAGE PARTS | salvage | http://localhost:5108 | 2,975 |
| workspace-codex-long-horizon (Telegram PM bot) | 70 | SALVAGE PARTS | salvage | - | 7,050 |
| DevKnowledge Base | 68 | SALVAGE PARTS | salvage | - | 3,340 |
| new-weezy-trea (agent cockpit) | 65 | SALVAGE PARTS | salvage | - | 9,780 |
| digital-agency (devin) | 64 | SALVAGE PARTS | salvage | - | 7,701 |
| agency-again (Maestro) | 62 | SALVAGE PARTS | salvage | http://localhost:5109 | 3,165 |
| mastra-ai-agency | 52 | SALVAGE PARTS | salvage | - | 537 |
| agencyos-unified (Spark) | 48 | SALVAGE PARTS | ui | - | 12,048 |
| agency-platform (sonnet) | 48 | SALVAGE PARTS | salvage | - | 1,702 |
| v0-ai-agency (v0.app) | 45 | SALVAGE PARTS | ui | - | 7,918 |
| agency-main (AgencyOS 0.1.0) | 43 | SALVAGE PARTS | salvage | - | 899 |
| agency-gpt-oss-ci-tests | 35 | SALVAGE PARTS | salvage | - | 872 |
| paulweezydesign-agency | 28 | SALVAGE PARTS | ui | - | 3,300 |
| agency-os-part-dux | 27 | SALVAGE PARTS | ui | - | 440 |
| long-horizon-tasks-repo | 20 | DISCARD | discard | - | 54 |
| digital-agency-codex-newest | 18 | DISCARD | discard | - | 27,533 |
| codex-long-horizon-template | 3 | DISCARD | discard | - | 0 |

### Why the three discards

- **codex-long-horizon-template** - zero application code, scaffolding only.
- **digital-agency-codex-newest** - 27k LOC, but `package.json` is missing every dependency the
  code imports. Broken by construction; it has never run.
- **long-horizon-tasks-repo** - documentation only, no implementation.

## Recommended synthesis

No single iteration is the winner. The strongest path is to assemble one:

- **codex-agency-2** - monorepo skeleton and architecture
- **fabel** - `ai-client-factory` as the LLM provider layer
- **agency-pm** - the PM brain (task graphs, dependency validation, 55 tests)
- **agency-os-v1** - the 8-agent roster
- **agency-os-newerest** - commercial domain logic (SOW, deposits, UAT)
- **paulweezy** - client-facing UI
- **agencyos-unified** - UI and information architecture spec
- **agency-main** - RBAC and tenancy
- **mastra-design-agent** - designer toolset

## Files

| File | Purpose |
| --- | --- |
| `report.html` | The interactive dashboard (self-contained, data inlined) |
| `report.template.html` + `gen-report.js` | Regenerate `report.html` from `report-data.json` + `health.json` |
| `report-data.json` | Curated audit of all 26 projects: purpose, stack, maturity, verdict, wiring, keep-list |
| `inv.py` + `_inventory.json` | Raw automated inventory (file counts, LOC, scripts, deps) |
| `installs.json` + `health.json` | Dependency install results and the last health probe |
| `secrets.env.example` | Template for your NVIDIA key / Atlas URI / model |
| `apply-secrets.ps1` + `templates.txt` | Render secrets into all 11 project env files |
| `apply-runtime-fixes.ps1` | Reapply verified dependency and auth compatibility fixes after extraction |
| `start-all.ps1` / `stop-all.ps1` / `health.ps1` | Start, stop and probe the 15 app processes |
| `mongo.js` | Local MongoDB stand-in with persistent storage |
| `probe-mastra.mjs` | NIM connectivity probe (how the 410 was found) |

## Notes for whoever runs this next

- Verification trick: with a placeholder key, a correctly wired app gets **403** from
  `https://integrate.api.nvidia.com/v1/chat/completions`. That proves routing reaches NVIDIA.
  A **410** means the model is dead.
- Mastra >= 1.41 ships a built-in `nvidia` provider, so Mastra projects switch with a model
  string like `nvidia/openai/gpt-oss-20b` and no code change at all.
- Five projects needed real code to reach NIM: new adapters in `agency-again`, `claude-main`
  and `agency-os-v1`, plus patches to `codex-agency-2` and `paulweezy`.
- `apply-runtime-fixes.ps1` also pins `@composio/core` to `0.19.0` for
  `@composio/mastra` compatibility and keeps Better Auth on the Codex app's same origin.
- `digital-agency-new-from-server` scores 86 but needs Postgres + Redis via Docker, which is
  not installed here. It is the highest-scoring project that has not actually been run.
- `agency-os-v1` and `dev-knowlege` have an empty `pnpm-workspace.yaml`, so pnpm fails with
  "packages field missing or empty". Use npm for those two.
- `ai-agency-mastra` needs an `OPENAI_API_KEY` present at boot even when chat goes to NIM,
  because Mastra memory constructs an embedding model eagerly.
