# PowerShell Wrapper for Buildserver Install
# This script detects Git Bash or WSL, falls back if needed

$ErrorActionPreference = "Stop"

Write-Host "🔍 Checking for Git Bash..."
$gitBash = "${env:ProgramFiles}\Git\bin\bash.exe"

if (Test-Path $gitBash) {
    Write-Host "✅ Git Bash found. Running install-script.sh..."
    & "$gitBash" -c "curl -fsSL https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh | bash -s -- --download-repo"
    exit 0
}

Write-Host "🔍 Checking for WSL..."
if (Get-Command "wsl.exe" -ErrorAction SilentlyContinue) {
    Write-Host "✅ WSL found. Running install-script.sh..."
    wsl curl -fsSL https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh | wsl bashbash -s -- --download-repo
    exit 0
}

Write-Host "❌ ERROR: Neither Git Bash nor WSL found."
Write-Host "Please install Git for Windows (https://gitforwindows.org/) or WSL."
exit 1
