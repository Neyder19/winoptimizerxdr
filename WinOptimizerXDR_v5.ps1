#requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

# =========================================================
# VARIABLES GLOBALES
# =========================================================
$Global:Findings = @()
$Global:Score = 100
$Global:Report = "$env:USERPROFILE\Desktop\XDR_Report.html"

# =========================================================
# FUNCION SEGURA
# =========================================================
function Invoke-SafeAction {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    try {
        & $Action
        Write-Host "[OK] $Name" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARN] $Name" -ForegroundColor Yellow
        $Global:Findings += "[WARN] $Name"
        $Global:Score -= 2
    }
}

# =========================================================
# HARDENING
# =========================================================
function Optimize-SystemHardening {

    Write-Host "`nAplicando hardening del sistema..." -ForegroundColor Cyan

    Invoke-SafeAction "Desactivar telemetría básica" {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
        Set-ItemProperty `
            -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
            -Name AllowTelemetry -Value 0 -Type DWord
    }

    Invoke-SafeAction "Desactivar sugerencias de Windows" {
        Set-ItemProperty `
            -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
            -Name SystemPaneSuggestionsEnabled -Value 0 -Force
    }

    Invoke-SafeAction "Desactivar Consumer Features" {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
        Set-ItemProperty `
            -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" `
            -Name DisableWindowsConsumerFeatures -Value 1 -Type DWord
    }
}

# =========================================================
# DEBLOAT
# =========================================================
function Start-DebloatAggressive {

    Write-Host "`nEliminando bloatware..." -ForegroundColor Cyan

    $apps = @(
        "*Xbox*",
        "*Zune*",
        "*SkypeApp*",
        "*GetHelp*",
        "*Getstarted*",
        "*Microsoft3DViewer*",
        "*SolitaireCollection*",
        "*MixedReality*",
        "*People*",
        "*BingNews*",
        "*BingWeather*"
    )

    foreach ($app in $apps) {
        Invoke-SafeAction "Eliminar $app" {
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers
        }
    }
}

# =========================================================
# LIMPIEZA + PERFORMANCE
# =========================================================
function Optimize-SystemPerformance {

    Write-Host "`nAplicando limpieza profunda y optimización..." -ForegroundColor Cyan

    Invoke-SafeAction "Limpiar TEMP usuario" {
        Remove-Item "$env:TEMP\*" -Recurse -Force
    }

    Invoke-SafeAction "Limpiar Windows Temp" {
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force
    }

    Invoke-SafeAction "Limpiar Prefetch" {
        Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force
    }

    Invoke-SafeAction "Limpiar Windows Update" {
        Stop-Service wuauserv -Force
        Stop-Service bits -Force
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force
        Start-Service wuauserv
        Start-Service bits
    }

    Invoke-SafeAction "Limpiar miniaturas" {
        Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force
    }

    Invoke-SafeAction "Reducir animaciones" {
        Set-ItemProperty `
            -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
            -Name VisualFXSetting -Value 2 -Force
    }

    Invoke-SafeAction "Optimizar DiagTrack" {
        Stop-Service DiagTrack -Force
        Set-Service DiagTrack -StartupType Disabled
    }

    Invoke-SafeAction "Optimizar MapsBroker" {
        Stop-Service MapsBroker -Force
        Set-Service MapsBroker -StartupType Disabled
    }

    Write-Host "Optimización completada." -ForegroundColor Green
}

# =========================================================
# ANALISIS
# =========================================================
function Analyze-AttackSurface {

    Write-Host "`nAnalizando superficie de ataque..." -ForegroundColor Cyan

    if ((Get-Service DiagTrack).Status -ne "Stopped") {
        $Global:Findings += "DiagTrack activo"
        $Global:Score -= 5
    }

    if ((Get-Service MapsBroker).Status -ne "Stopped") {
        $Global:Findings += "MapsBroker activo"
        $Global:Score -= 3
    }
}

# =========================================================
# SCORE
# =========================================================
function Get-SecurityScore {
    return @{
        Score = $Global:Score
        Findings = $Global:Findings.Count
    }
}

# =========================================================
# REPORTE
# =========================================================
function Generate-Report {

    $scoreObj = Get-SecurityScore

$html = @"
<html>
<head>
<style>
body{font-family:Segoe UI;background:#020617;color:#e2e8f0;padding:20px}
h1{color:#22c55e}
.bad{color:#ef4444}
.good{color:#22c55e}
pre{background:#0f172a;padding:15px;border-radius:8px}
</style>
</head>
<body>
<h1>XDR Security Report</h1>
<h2>Security Score: $($scoreObj.Score)/100</h2>
<h3>Hallazgos: $($scoreObj.Findings)</h3>
<pre>
$($Global:Findings -join "`n")
</pre>
</body>
</html>
"@

    $html | Out-File $Global:Report -Encoding utf8
    Write-Host "Reporte generado: $Global:Report" -ForegroundColor Green
}

# =========================================================
# MENU
# =========================================================
function Show-Menu {

    Clear-Host
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "   XDR Optimizer v5" -ForegroundColor Cyan
    Write-Host "============================="
    Write-Host "1. Optimización completa"
    Write-Host "2. Solo análisis"
    Write-Host "3. Salir"
}

# =========================================================
# MAIN LOOP
# =========================================================
do {
    Show-Menu
    $opt = Read-Host "Seleccione opción"

    switch ($opt) {

        "1" {
            Optimize-SystemHardening
            Optimize-SystemPerformance
            Start-DebloatAggressive
            Analyze-AttackSurface
            Generate-Report
            Write-Host "`n¡Optimización finalizada! Recomendado reiniciar." -ForegroundColor Green
            Pause
        }

        "2" {
            Analyze-AttackSurface
            Generate-Report
            Pause
        }

        "3" {
            break
        }

        default {
            Write-Host "Opción inválida"
            Pause
        }
    }

} while ($true)

# =========================================================
# AUTO-INICIO CUANDO SE EJECUTA REMOTAMENTE
# =========================================================

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Write-Host "`nIniciando WinOptimizer XDR Pro..." -ForegroundColor Cyan
    } catch {}

    # Mostrar menú automáticamente
    do {
        Write-Host "`n[1] Ejecutar optimización completa"
        Write-Host "[2] Solo auditoría"
        Write-Host "[3] Ver score"
        Write-Host "[4] Generar reporte"
        Write-Host "[5] Salir"

        $choice = Read-Host "Seleccione opción"

        switch ($choice) {
            "1" {
                Optimize-SystemHardening
                Start-DebloatAggressive
                Analyze-AttackSurface
                Generate-Report
                Pause
            }
            "2" {
                $Global:AuditMode = $true
                Write-Host "Modo auditoría activado"
                Pause
            }
            "3" {
                Write-Host "Score: $Global:Score"
                Pause
            }
            "4" {
                Generate-Report
                Pause
            }
            "5" { break }
        }
    } while ($true)
}