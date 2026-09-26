# Renders every <app>\.env.audit-template -> target env file, substituting:
#   {{NVIDIA_API_KEY}}  {{NIM_MODEL}}  {{MONGO:<dbName>}}
$root = "C:\Users\weezy\agencyos-audit"
$s = @{}; Get-Content "$PSScriptRoot\secrets.env" | ? { $_ -match '^\s*([A-Z_]+)=(.*)$' } | % { $s[$matches[1]] = $matches[2].Trim().Trim('"') }
$key = if ($s.NVIDIA_API_KEY) { $s.NVIDIA_API_KEY } else { 'REPLACE_WITH_NVIDIA_KEY' }
$model = if ($s.NIM_MODEL) { $s.NIM_MODEL } else { 'openai/gpt-oss-20b' }
function MongoFor($db) {
  if (-not $s.MONGODB_URI) { return "mongodb://127.0.0.1:27017/$db" }
  $u = $s.MONGODB_URI; $q = ''; if ($u -match '^([^?]*)\?(.*)$') { $u = $matches[1]; $q = '?' + $matches[2] }
  if ($u -match '^(mongodb(\+srv)?://[^/]+)') { $u = $matches[1] }
  return "$u/$db$q"
}
Get-Content "$PSScriptRoot\templates.txt" | ? { $_ -and (Test-Path $_) } | % { Get-Item $_ } | % {
  $lines = Get-Content $_.FullName
  $target = ($lines | ? { $_ -match '^#TARGET=' }) -replace '^#TARGET=', ''
  $out = $lines | ? { $_ -notmatch '^#TARGET=' } | % {
    $l = $_.Replace('{{NVIDIA_API_KEY}}', $key).Replace('{{NIM_MODEL}}', $model)
    [regex]::Replace($l, '\{\{MONGO:([A-Za-z0-9_\-]+)\}\}', { param($m) MongoFor $m.Groups[1].Value })
  }
  $dest = Join-Path $_.DirectoryName $target
  $out | Set-Content $dest -Encoding ascii
  "wrote $dest"
}

