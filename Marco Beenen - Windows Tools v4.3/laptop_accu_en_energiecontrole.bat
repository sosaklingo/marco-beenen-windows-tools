@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Laptopaccu en energiecontrole - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De energiecontrole wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:WT_SELF -Raw; $marker = ':' + 'POWERSHELL_PAYLOAD'; $start = $raw.LastIndexOf($marker); if ($start -lt 0) { throw 'Testcode niet gevonden.' }; Invoke-Expression ($raw.Substring($start + $marker.Length))"
set "TOOL_CODE=%errorlevel%"

echo.
pause
exit /b %TOOL_CODE%
:POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Continue'
$desktop = [Environment]::GetFolderPath('Desktop')
$reports = Join-Path $desktop 'Computerdiagnose rapporten'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$summaryPath = Join-Path $reports ("Laptop_accu_energie_{0}.txt" -f $stamp)
$batteryPath = Join-Path $reports ("Accu_rapport_{0}.html" -f $stamp)
$energyPath = Join-Path $reports ("Energie_rapport_{0}.html" -f $stamp)
$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line([string]$text = '') { $lines.Add($text); Write-Host $text }

Clear-Host
Add-Line 'LAPTOPACCU EN ENERGIECONTROLE'
Add-Line 'Gemaakt door Marco Beenen - Windows Tools v4.3'
Add-Line ("Datum/tijd: {0}" -f (Get-Date))
Add-Line ''

$batteries = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
if ($batteries.Count -eq 0) {
    Add-Line 'INFO: geen accu gevonden. Dit is normaal voor een desktopcomputer.'
}
else {
    foreach ($battery in $batteries) {
        Add-Line ("Acculading       : {0} procent" -f $battery.EstimatedChargeRemaining)
        Add-Line ("Status           : {0}" -f $battery.Status)
        Add-Line ("Geschatte tijd   : {0}" -f $battery.EstimatedRunTime)
    }

    try {
        $design = Get-CimInstance -Namespace root/wmi -ClassName BatteryStaticData -ErrorAction Stop | Select-Object -First 1
        $full = Get-CimInstance -Namespace root/wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop | Select-Object -First 1
        if (($design.DesignedCapacity -gt 0) -and ($full.FullChargedCapacity -gt 0)) {
            $health = [Math]::Round(($full.FullChargedCapacity / $design.DesignedCapacity) * 100, 0)
            Add-Line ("Ontwerpcapaciteit: {0} mWh" -f $design.DesignedCapacity)
            Add-Line ("Volle capaciteit : {0} mWh" -f $full.FullChargedCapacity)
            Add-Line ("Accugezondheid   : ongeveer {0} procent" -f $health)
            if ($health -lt 60) { Add-Line 'AANDACHT: de accu heeft minder dan ongeveer 60 procent van de oorspronkelijke capaciteit.' }
        }
    }
    catch {
        Add-Line 'INFO: Windows gaf geen betrouwbare capaciteitswaarden via WMI.'
    }
}

Add-Line ''
Add-Line 'Beschikbare slaapstanden:'
(& powercfg.exe /a) | ForEach-Object { Add-Line $_ }

Add-Line ''
Add-Line 'Windows maakt een accurapport...'
& powercfg.exe /batteryreport /output $batteryPath | ForEach-Object { Add-Line $_ }

Add-Line ''
Add-Line 'Windows meet nu 30 seconden het energiegebruik. Laat de computer even met rust...'
& powercfg.exe /energy /duration 30 /output $energyPath | ForEach-Object { Add-Line $_ }

Add-Line ''
Add-Line 'ADVIES'
Add-Line 'Een accugezondheid van ongeveer 80 procent of hoger is meestal nog goed bruikbaar.'
Add-Line 'Onder ongeveer 60 procent is vervanging vaak merkbaar aan de gebruiksduur.'
Add-Line 'Bekijk in het energierapport vooral fouten die meerdere keren terugkomen.'
Add-Line ("Samenvatting: {0}" -f $summaryPath)
Add-Line ("Accurapport : {0}" -f $batteryPath)
Add-Line ("Energierapport: {0}" -f $energyPath)
$lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

if (Test-Path -LiteralPath $batteryPath) {
    Start-Process $batteryPath
}
else {
    Start-Process notepad.exe $summaryPath
}
