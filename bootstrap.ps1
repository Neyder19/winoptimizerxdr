# ===== WinOptimizer Bootstrap =====

$ErrorActionPreference = "SilentlyContinue"

Write-Host "Inicializando WinOptimizer XDR..." -ForegroundColor Cyan

# Verificar admin
$id=[Security.Principal.WindowsIdentity]::GetCurrent()
$p=New-Object Security.Principal.WindowsPrincipal($id)

if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Re-ejecutando como administrador..."
    Start-Process powershell `
        -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"iwr -useb 'URL_DE_TU_SCRIPT_GRANDE' | iex`"" `
        -Verb RunAs
    exit
}

# Descargar script principal
$scriptUrl = "URL_DE_TU_SCRIPT_GRANDE"

Write-Host "Descargando motor principal..."
$code = Invoke-WebRequest -UseBasicParsing $scriptUrl

Write-Host "Ejecutando..."
Invoke-Expression $code.Content