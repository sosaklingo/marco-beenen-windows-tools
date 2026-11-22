@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Wifi-rapport maken - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Het wifi-rapport wordt opnieuw gestart als administrator...
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
$summaryPath = Join-Path $reports ("Wifi_samenvatting_{0}.txt" -f $stamp)
$htmlPath = Join-Path $reports ("Wifi_rapport_{0}.html" -f $stamp)
$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line([string]$text = '') { $lines.Add($text); Write-Host $text }

Clear-Host
Add-Line 'WIFI-RAPPORT'
Add-Line 'Gemaakt door Marco Beenen - Windows Tools v4.3'
Add-Line ("Datum/tijd: {0}" -f (Get-Date))
Add-Line ''

Add-Line 'HUIDIGE WIFI-VERBINDING'
Add-Line ('-' * 68)
(& netsh.exe wlan show interfaces) | ForEach-Object { Add-Line $_ }

Add-Line ''
Add-Line 'WIFI-DRIVER'
Add-Line ('-' * 68)
(& netsh.exe wlan show drivers) | ForEach-Object { Add-Line $_ }

try {
    $since = (Get-Date).AddDays(-7)
    $events = @(Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-WLAN-AutoConfig/Operational'; StartTime = $since; Level = 1, 2, 3 } -MaxEvents 100 -ErrorAction Stop)
    Add-Line ''
    Add-Line ("Wifi-waarschuwingen/fouten laatste 7 dagen: {0}" -f $events.Count)
    foreach ($event in ($events | Select-Object -First 10)) {
        Add-Line ("{0} - ID {1} - {2}" -f $event.TimeCreated, $event.Id, (($event.Message -replace '\r?\n', ' ') -replace '\s+', ' '))
    }
}
catch {
    Add-Line ''
    Add-Line ("Wifi-logboek kon niet worden gelezen: {0}" -f $_.Exception.Message)
}

Add-Line ''
Add-Line 'Windows maakt nu een visueel wifi-rapport over de afgelopen 7 dagen...'
& netsh.exe wlan show wlanreport duration=7 | ForEach-Object { Add-Line $_ }
$defaultReport = Join-Path $env:ProgramData 'Microsoft\Windows\WlanReport\wlan-report-latest.html'
if (Test-Path -LiteralPath $defaultReport) {
    Copy-Item -LiteralPath $defaultReport -Destination $htmlPath -Force
    Add-Line ("HTML-rapport: {0}" -f $htmlPath)
}
else {
    Add-Line 'AANDACHT: Windows heeft geen HTML-rapport gevonden. Mogelijk heeft deze computer geen wifi-adapter.'
}

Add-Line ''
Add-Line 'ADVIES'
Add-Line 'Veel verbrekingen wijzen vaak op bereik, storing, energiebesparing, een driver of de router.'
Add-Line 'Vergelijk de verbinding dicht bij de router en, indien mogelijk, met een netwerkkabel.'
Add-Line ("Tekstsamenvatting: {0}" -f $summaryPath)
$lines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

if (Test-Path -LiteralPath $htmlPath) {
    Start-Process $htmlPath
}
else {
    Start-Process notepad.exe $summaryPath
}
