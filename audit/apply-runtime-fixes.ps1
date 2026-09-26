param(
  [string]$Root = 'C:\Users\weezy\agencyos-audit'
)

$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Text([string]$Path) {
  if (-not (Test-Path $Path)) {
    throw "Required file is missing: $Path"
  }
  return [System.IO.File]::ReadAllText($Path)
}

function Write-Text([string]$Path, [string]$Content) {
  [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Replace-Once(
  [string]$Path,
  [string]$OldValue,
  [string]$NewValue,
  [string]$AlreadyFixedValue
) {
  $content = Read-Text $Path
  if ($content.Contains($OldValue)) {
    Write-Text $Path ($content.Replace($OldValue, $NewValue))
    return $true
  }
  if (($NewValue -and $content.Contains($NewValue)) -or
      ($AlreadyFixedValue -and $content.Contains($AlreadyFixedValue))) {
    return $false
  }
  throw "Expected original or fixed text was not found in $Path"
}

# @composio/mastra 0.10.x imports omitNullToolArguments, which is absent from
# @composio/core 0.13.1. Pin the core version used to build the provider.
$v1 = Join-Path $Root 'agency-os-v1-main\agency-os-v1-main'
$v1Package = Join-Path $v1 'package.json'
$packageChanged = Replace-Once `
  $v1Package `
  '"@composio/core": "^0.13.1"' `
  '"@composio/core": "0.19.0"' `
  '"@composio/core": "0.19.0"'

$packageContent = Read-Text $v1Package
if (-not $packageContent.Contains('"test:composio"')) {
  $packageContent = $packageContent.Replace(
    '"test": "tsx --test tests/**/*.test.ts",',
    '"test": "tsx --test tests/**/*.test.ts",' + [Environment]::NewLine +
      '    "test:composio": "node --test tests/composio-import.test.mjs",'
  )
  Write-Text $v1Package $packageContent
}

$composioTest = @'
import assert from "node:assert/strict";
import test from "node:test";

test("@composio/mastra loads with the installed @composio/core", async () => {
  const composioMastra = await import("@composio/mastra");

  assert.equal(typeof composioMastra.MastraProvider, "function");
});
'@
$testPath = Join-Path $v1 'tests\composio-import.test.mjs'
Write-Text $testPath ($composioTest + [Environment]::NewLine)

$installedCore = Join-Path $v1 'node_modules\@composio\core\package.json'
$installedVersion = ''
if (Test-Path $installedCore) {
  $installedVersion = (Get-Content $installedCore -Raw | ConvertFrom-Json).version
}
if ($packageChanged -or $installedVersion -ne '0.19.0') {
  Push-Location $v1
  try {
    & npx.cmd -y pnpm@10 install --ignore-workspace --no-frozen-lockfile
    if ($LASTEXITCODE -ne 0) {
      throw "pnpm install failed with exit code $LASTEXITCODE"
    }
  } finally {
    Pop-Location
  }
}

# Better Auth runs in the same Next.js app. Leaving baseURL unset makes the
# browser client use the page origin instead of sending port 3110 traffic to 3000.
$web = Join-Path $Root 'codex-agency-2-master\codex-agency-2-master\apps\web'
$authClient = Join-Path $web 'lib\auth-client.ts'
Replace-Once `
  $authClient `
  '  baseURL: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000",' `
  '' `
  'export const authClient = createAuthClient({' | Out-Null

$authConfig = Join-Path $web 'lib\auth-config.ts'
$oldOrigins = 'export const trustedOrigins = [process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000"];'
$newOrigins = @'
export const trustedOrigins = [
  process.env.NEXT_PUBLIC_APP_URL ??
    process.env.BETTER_AUTH_URL ??
    "http://localhost:3000",
];
'@
Replace-Once $authConfig $oldOrigins $newOrigins 'process.env.BETTER_AUTH_URL ??' | Out-Null

Write-Host 'Runtime compatibility fixes applied.'
