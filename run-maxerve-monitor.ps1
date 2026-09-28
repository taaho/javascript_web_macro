$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js 20 이상을 설치한 뒤 다시 실행하세요: https://nodejs.org/'
}

if (-not (Test-Path 'node_modules/playwright')) {
    npm install
    npx playwright install chromium
}

node .\maxerve-monitor.mjs
