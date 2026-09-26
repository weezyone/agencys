# AgencyOS audit - starts local MongoDB + every app that was verified running.
# Usage:  powershell -File C:\Users\weezy\agencyos-audit\_infra\start-all.ps1
# Stop:   powershell -File C:\Users\weezy\agencyos-audit\_infra\stop-all.ps1
$ErrorActionPreference = 'Continue'
$root = 'C:\Users\weezy\agencyos-audit'

# 1. Apply dependency/runtime compatibility fixes after a fresh extraction.
powershell -File "$root\_infra\apply-runtime-fixes.ps1"
if ($LASTEXITCODE -ne 0) { throw 'Runtime compatibility fixes failed.' }

# 2. Re-render every .env from _infra\secrets.env
powershell -File "$root\_infra\apply-secrets.ps1" | Out-Null

# 3. Local MongoDB (skipped when secrets.env supplies a real Atlas MONGODB_URI)
$useAtlas = (Get-Content "$root\_infra\secrets.env" | Where-Object { $_ -match '^MONGODB_URI=\S' }).Count -gt 0
if (-not $useAtlas) {
  $mongoUp = (Test-NetConnection 127.0.0.1 -Port 27017 -InformationLevel Quiet -WarningAction SilentlyContinue)
  if (-not $mongoUp) {
    Start-Process cmd.exe -ArgumentList "/c node mongo.js > mongo.log 2>&1" -WindowStyle Hidden -WorkingDirectory "$root\_infra"
    for ($i = 0; $i -lt 20; $i++) {
      Start-Sleep 3
      if (Test-NetConnection 127.0.0.1 -Port 27017 -InformationLevel Quiet -WarningAction SilentlyContinue) { break }
    }
    Write-Host "mongo ready: $(Test-NetConnection 127.0.0.1 -Port 27017 -InformationLevel Quiet -WarningAction SilentlyContinue)"
  }
}

function Start-App($name, $dir, $exe, $argList) {
  if (-not (Test-Path $dir)) { Write-Host "skip $name (missing)"; return }
  Start-Process -WindowStyle Hidden $exe -ArgumentList $argList -WorkingDirectory $dir
  Write-Host "started $name"
}

$npx = 'npx.cmd'
Start-App 'agency-os-newerest (3101)'   "$root\agency-os-newerest-main\agency-os-newerest-main" $npx 'next dev --turbopack -p 3101'
Start-App 'agency-os-v1 (3102)'         "$root\agency-os-v1-main\agency-os-v1-main" 'node.exe' 'node_modules\next\dist\bin\next dev -p 3102'
Start-App 'fabel (3103)'                "$root\fabel-main\fabel-main" $npx 'next dev -p 3103'
Start-App 'ai-agency api (3104)'        "$root\ai-agency-mastra-updated--2-newest-main\ai-agency-mastra-updated--2-newest-main" $npx 'tsx src/server/index.ts'
Start-App 'ai-agency web (5104)'        "$root\ai-agency-mastra-updated--2-newest-main\ai-agency-mastra-updated--2-newest-main\web" $npx 'vite --port 5104 --strictPort'
Start-App 'paulweezy api (3105)'        "$root\paulweezy-80265bf-main1\paulweezy-80265bf-main\server" 'node.exe' 'server.js'
Start-App 'paulweezy web (5105)'        "$root\paulweezy-80265bf-main1\paulweezy-80265bf-main\client" $npx 'vite --port 5105 --strictPort'
Start-App 'mastra-design-agent (3106)'  "$root\mastra-design-agent-main\mastra-design-agent-main" $npx 'next dev -p 3106'
Start-App 'agency-pm studio (4107)'     "$root\agency-pm_1-main\agency-pm_1-main\agency-pm" $npx 'mastra dev'
Start-App 'claude api (4108)'           "$root\claude-main\claude-main\server" $npx 'tsx --env-file=.env src/index.ts'
Start-App 'claude web (5108)'           "$root\claude-main\claude-main\client" $npx 'vite --strictPort'
Start-App 'agency-again api (4109)'     "$root\agency-again-main\agency-again-main\server" $npx 'tsx --env-file=.env src/index.ts'
Start-App 'agency-again web (5109)'     "$root\agency-again-main\agency-again-main\web" $npx 'vite --port 5109 --strictPort'
Start-App 'codex-agency-2 runtime (4110)' "$root\codex-agency-2-master\codex-agency-2-master\apps\runtime" $npx 'tsx --env-file=.env src/index.ts'
Start-App 'codex-agency-2 web (3110)'   "$root\codex-agency-2-master\codex-agency-2-master\apps\web" $npx 'next dev -p 3110'

Write-Host ''
Write-Host 'Apps are compiling. Give them ~60s, then run: powershell -File C:\Users\weezy\agencyos-audit\_infra\health.ps1'
