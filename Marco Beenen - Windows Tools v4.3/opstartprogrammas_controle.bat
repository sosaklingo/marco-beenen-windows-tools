@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Opstartprogramma's controleren - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De controle wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:WT_SELF -Raw; $marker = ':' + 'POWERSHELL_PAYLOAD'; $start = $raw.LastIndexOf($marker); if ($start -lt 0) { throw 'Testcode niet gevonden.' }; Invoke-Expression ($raw.Substring($start + $marker.Length))"
set "TOOL_CODE=%errorlevel%"

echo.
pause
exit /b %TOOL_CODE%
:POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$reports = Join-Path $desktop 'Computerdiagnose rapporten'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$reportPath = Join-Path $reports ("Opstartprogrammas_{0}.txt" -f $stamp)

$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line([string]$text = '') { $lines.Add($text); Write-Host $text }

Clear-Host
Add-Line 'OPSTARTPROGRAMMA''S EN ACHTERGRONDSTART'
Add-Line 'Gemaakt door Marco Beenen - Windows Tools v4.3'
Add-Line ("Datum/tijd: {0}" -f (Get-Date))
Add-Line 'Er wordt niets uitgeschakeld of gewijzigd.'
Add-Line ''

try {
    $startup = @(Get-CimInstance Win32_StartupCommand | Sort-Object Name)
    Add-Line ("Automatische opstartopdrachten: {0}" -f $startup.Count)
    Add-Line ('-' * 72)
    foreach ($item in $startup) {
        Add-Line ("Naam     : {0}" -f $item.Name)
        Add-Line ("Gebruiker: {0}" -f $item.User)
        Add-Line ("Locatie  : {0}" -f $item.Location)
        Add-Line ("Opdracht : {0}" -f $item.Command)
        Add-Line ''
    }
}
catch {
    Add-Line ("AANDACHT: opstartopdrachten konden niet worden gelezen: {0}" -f $_.Exception.Message)
}

try {
    $logonTasks = @(Get-ScheduledTask -ErrorAction Stop | Where-Object {
        @($_.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }).Count -gt 0
    } | Sort-Object TaskPath, TaskName)
    Add-Line ''
    Add-Line ("Geplande taken bij aanmelden: {0}" -f $logonTasks.Count)
    Add-Line ('-' * 72)
    foreach ($task in $logonTasks) {
        Add-Line ("{0}{1} - status {2}" -f $task.TaskPath, $task.TaskName, $task.State)
    }
}
catch {
    Add-Line ("AANDACHT: geplande aanmeldtaken konden niet worden gelezen: {0}" -f $_.Exception.Message)
}

try {
    $autoServices = @(Get-CimInstance Win32_Service | Where-Object StartMode -eq 'Auto')
    $runningAuto = @($autoServices | Where-Object State -eq 'Running')
    Add-Line ''
    Add-Line ("Automatische services: {0}, daarvan actief: {1}" -f $autoServices.Count, $runningAuto.Count)
}
catch {
    Add-Line ("AANDACHT: services konden niet worden geteld: {0}" -f $_.Exception.Message)
}

Add-Line ''
Add-Line 'ADVIES'
Add-Line 'Een hoog aantal is niet automatisch fout. Schakel alleen software uit die u herkent en niet direct nodig hebt.'
Add-Line 'Laat antivirus, touchpad-, audio-, videokaart-, back-up- en hardwarehulpprogramma''s staan bij twijfel.'
Add-Line 'U kunt opstartapps beheren via Instellingen > Apps > Opstarten.'
Add-Line ''
Add-Line ("Rapport: {0}" -f $reportPath)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
Start-Process notepad.exe $reportPath
