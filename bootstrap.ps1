# ===== WinOptimizer Bootstrap =====

$ErrorActionPreference = "Continue"

Write-Host "Inicializando WinOptimizer XDR..." -ForegroundColor Cyan

# Verificar admin
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$p  = New-Object Security.Principal.WindowsPrincipal($id)

if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-ejecutando como administrador..." -ForegroundColor Yellow

    Start-Process powershell `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"iwr -useb 'https://raw.githubusercontent.com/Neyder19/winoptimizerxdr/main/WinOptimizerXDR_v5.ps1' | iex`"" `
        -Verb RunAs
    exit
}

# Descargar script principal
$scriptUrl = "https://raw.githubusercontent.com/Neyder19/winoptimizerxdr/main/WinOptimizerXDR_v5.ps1"

Write-Host "Descargando motor principal..." -ForegroundColor Cyan
$code = Invoke-WebRequest -UseBasicParsing $scriptUrl

Write-Host "Ejecutando..." -ForegroundColor Green
Invoke-Expression $code.Content