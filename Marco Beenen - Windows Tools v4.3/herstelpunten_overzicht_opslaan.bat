@echo off
setlocal EnableExtensions
title Herstelpuntenoverzicht opslaan - Marco Beenen

fltmc >nul 2>&1
if errorlevel 1 (
    echo Het herstelpuntenoverzicht wordt opnieuw gestart als administrator...
    set "WT_SCRIPT=%~f0"
    set "WT_ROOT=%~dp0"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:WT_SCRIPT -WorkingDirectory $env:WT_ROOT -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo Starten als administrator is geannuleerd of mislukt.
        pause
        exit /b 1
    )
    exit /b 0
)

set "WT_SELF=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw=Get-Content -LiteralPath $env:WT_SELF -Raw; $marker=':'+'POWERSHELL_PAYLOAD'; $start=$raw.LastIndexOf($marker); if($start -lt 0){throw 'Rapportcode niet gevonden.'}; Invoke-Expression ($raw.Substring($start+$marker.Length))"
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
$reportPath = Join-Path $reports ("Herstelpunten_overzicht_{0}.txt" -f $stamp)
$points = @(Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object SequenceNumber -Descending)
$lines = [System.Collections.Generic.List[string]]::new()
[void]$lines.Add('HERSTELPUNTENOVERZICHT - MARCO BEENEN')
[void]$lines.Add('Gemaakt door Marco Beenen - Windows Tools v4.3')
[void]$lines.Add(('Datum: {0}' -f (Get-Date)))
[void]$lines.Add(('Aantal gevonden herstelpunten: {0}' -f $points.Count))
[void]$lines.Add('')
foreach ($point in $points) {
    try {
        $created = if ($point.CreationTime -is [datetime]) { $point.CreationTime } else { [Management.ManagementDateTimeConverter]::ToDateTime([string]$point.CreationTime) }
    }
    catch { $created = [string]$point.CreationTime }
    [void]$lines.Add(('Nummer      : {0}' -f $point.SequenceNumber))
    [void]$lines.Add(('Datum/tijd  : {0}' -f $created))
    [void]$lines.Add(('Naam        : {0}' -f $point.Description))
    [void]$lines.Add(('Type        : {0}' -f $point.RestorePointType))
    [void]$lines.Add('')
}
if ($points.Count -eq 0) {
    [void]$lines.Add('Er zijn geen herstelpunten gevonden.')
}
[void]$lines.Add('Dit is alleen een overzicht. Herstelpunten zelf kunnen niet als los bestand worden geexporteerd.')
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
$lines | ForEach-Object { Write-Host $_ }
Write-Host ("Rapport: {0}" -f $reportPath) -ForegroundColor Green
Start-Process notepad.exe -ArgumentList $reportPath
