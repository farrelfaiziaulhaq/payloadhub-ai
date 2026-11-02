# PayloadHub-AI — setup cepat (Windows PowerShell)
# Jalankan dari root repository: .\setup.ps1
$ErrorActionPreference = "Stop"

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "Python 3.10+ belum terpasang." -ForegroundColor Red
    Write-Host "Install dari https://www.python.org/downloads/ lalu buka PowerShell baru."
    exit 1
}

& $python.Source "$PSScriptRoot\scripts\payloadhub.py" setup @args
exit $LASTEXITCODE
