# ===== WinOptimizer Bootstrap PRO =====

$ErrorActionPreference = "Stop"

Write-Host "Inicializando WinOptimizer XDR..." -ForegroundColor Cyan

# =========================================================
# VERIFICAR ADMIN
# =========================================================
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$p  = New-Object Security.Principal.WindowsPrincipal($id)

if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-ejecutando como administrador..." -ForegroundColor Yellow

    Start-Process powershell `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"iwr -useb 'https://raw.githubusercontent.com/Neyder19/winoptimizerxdr/main/bootstrap.ps1' | iex`"" `
        -Verb RunAs

    exit
}

# =========================================================
# DESCARGAR MOTOR
# =========================================================
$scriptUrl = "https://raw.githubusercontent.com/Neyder19/winoptimizerxdr/main/WinOptimizerXDR_v5.ps1"

Write-Host "Descargando motor principal..." -ForegroundColor Cyan

try {
    $code = Invoke-WebRequest -UseBasicParsing $scriptUrl
}
catch {
    Write-Host "ERROR descargando el motor." -ForegroundColor Red
    exit
}

# =========================================================
# EJECUTAR MOTOR (IMPORTANTE)
# =========================================================
Write-Host "Ejecutando WinOptimizer..." -ForegroundColor Green

# Ejecutar en el scope global para que el menú funcione
# limpiar BOM si existe
$clean = $code.Content -replace "^\uFEFF", ""
Invoke-Expression $clean

Write-Host "`nBootstrap finalizado." -ForegroundColor DarkGray