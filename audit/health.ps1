# Probes every AgencyOS audit endpoint and prints status. Emits JSON to _infra\health.json
$urls = [ordered]@{
  'agency-os-newerest'   = 'http://localhost:3101'
  'agency-os-v1'         = 'http://localhost:3102'
  'fabel'                = 'http://localhost:3103'
  'ai-agency-api'        = 'http://localhost:3104/health'
  'ai-agency-web'        = 'http://localhost:5104'
  'paulweezy-api'        = 'http://localhost:3105/api/agents'
  'paulweezy-web'        = 'http://localhost:5105'
  'mastra-design-agent'  = 'http://localhost:3106'
  'agency-pm-studio'     = 'http://localhost:4107/api/agents'
  'claude-api'           = 'http://localhost:4108/api/agents'
  'claude-web'           = 'http://localhost:5108'
  'agency-again-api'     = 'http://localhost:4109/api/health'
  'agency-again-web'     = 'http://localhost:5109'
  'codex-agency-2-rt'    = 'http://localhost:4110/health'
  'codex-agency-2-web'   = 'http://localhost:3110'
}
$out = @()
foreach ($k in $urls.Keys) {
  $u = $urls[$k]
  try {
    $r = Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 45
    $body = ($r.Content -replace '\s+', ' ')
    $out += [pscustomobject]@{ app = $k; url = $u; status = $r.StatusCode; ok = $true; body = $body.Substring(0, [Math]::Min(120, $body.Length)) }
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    $out += [pscustomobject]@{ app = $k; url = $u; status = $code; ok = $false; body = $_.Exception.Message }
  }
}
$out | Format-Table app, status, ok, url -AutoSize
$out | ConvertTo-Json -Depth 3 | Set-Content "$PSScriptRoot\health.json"
