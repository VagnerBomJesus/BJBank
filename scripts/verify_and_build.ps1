# BJBank - Verificação e Build de Produção
# Corre: flutter clean, pub get, analyze, test, build appbundle release
# Uso: powershell -ExecutionPolicy Bypass -File scripts\verify_and_build.ps1

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " BJBank - Verify & Build Pipeline" -ForegroundColor Cyan
Write-Host " Pasta: $projectRoot" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

function Run-Step {
    param([string]$label, [scriptblock]$cmd)
    Write-Host ""
    Write-Host ">> $label" -ForegroundColor Yellow
    & $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FALHOU: $label (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "OK: $label" -ForegroundColor Green
}

Run-Step "Flutter version" { flutter --version }
Run-Step "Flutter clean" { flutter clean }
Run-Step "Flutter pub get" { flutter pub get }
Run-Step "Flutter analyze" { flutter analyze }
Run-Step "Flutter test" { flutter test }
Run-Step "Build AAB release" { flutter build appbundle --release }

$aab = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aab) {
    $size = [math]::Round((Get-Item $aab).Length / 1MB, 2)
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host " BUILD CONCLUIDO" -ForegroundColor Green
    Write-Host " AAB: $aab" -ForegroundColor Green
    Write-Host " Tamanho: $size MB" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "AAB nao encontrado em $aab" -ForegroundColor Red
    exit 1
}
