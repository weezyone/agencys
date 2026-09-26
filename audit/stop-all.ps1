# Stops node processes started from the AgencyOS audit folder only.
Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" | ForEach-Object {
  $cl = $_.CommandLine
  if ($cl -and ($cl -match 'agencyos-audit')) {
    Write-Host "stopping PID $($_.ProcessId)"
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
}
