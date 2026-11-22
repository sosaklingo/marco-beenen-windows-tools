@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Uitgebreide schijfcontrole - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De schijfcontrole wordt opnieuw gestart als administrator...
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
$reportPath = Join-Path $reports ("Uitgebreide_schijfcontrole_{0}.txt" -f $stamp)
$results = @()

function Write-Line([string]$text = '') {
    Write-Host $text
    Add-Content -LiteralPath $reportPath -Value $text
}

function Add-Result([string]$part, [string]$status, [string]$details) {
    $script:results += [PSCustomObject]@{ Part = $part; Status = $status; Details = $details }
    Write-Line ("[{0}] {1}: {2}" -f $status, $part, $details)
}

New-Item -ItemType File -Path $reportPath -Force | Out-Null
Clear-Host
Write-Line 'UITGEBREIDE SCHIJFCONTROLE'
Write-Line 'Gemaakt door Marco Beenen - Windows Tools v4.3'
Write-Line ("Datum/tijd: {0}" -f (Get-Date))
Write-Line 'Deze controle leest gegevens uit en voert alleen CHKDSK /scan uit.'
Write-Line ''

try {
    $physicalDisks = @(Get-PhysicalDisk)
    if ($physicalDisks.Count -eq 0) { throw 'Windows gaf geen fysieke schijven terug.' }
    $bad = @()
    $unknown = @()

    foreach ($disk in $physicalDisks) {
        Write-Line ('-' * 68)
        Write-Line ("Schijf            : {0}" -f $disk.FriendlyName)
        Write-Line ("Type/bus          : {0} / {1}" -f $disk.MediaType, $disk.BusType)
        Write-Line ("Grootte           : {0:N1} GB" -f ($disk.Size / 1GB))
        Write-Line ("Gezondheid        : {0}" -f $disk.HealthStatus)
        Write-Line ("Operationeel      : {0}" -f (@($disk.OperationalStatus) -join ', '))

        try {
            $rel = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction Stop
            foreach ($item in @(
                @('Temperatuur', 'Temperature', ' C'),
                @('Slijtagewaarde', 'Wear', ''),
                @('Bedrijfsuren', 'PowerOnHours', ' uur'),
                @('Leesfouten totaal', 'ReadErrorsTotal', ''),
                @('Schrijffouten totaal', 'WriteErrorsTotal', '')
            )) {
                $value = $rel.($item[1])
                if ($null -ne $value) { Write-Line ("{0,-17}: {1}{2}" -f $item[0], $value, $item[2]) }
            }
        }
        catch {
            Write-Line 'Extra SMART-waarden: niet beschikbaar via Windows.'
        }

        $operational = @($disk.OperationalStatus) -join ', '
        if (($disk.HealthStatus -notin @('Healthy', 'Unknown')) -or ($operational -match 'Error|Failure|Lost Communication')) {
            $bad += $disk.FriendlyName
        }
        elseif ($disk.HealthStatus -eq 'Unknown') {
            $unknown += $disk.FriendlyName
        }
    }

    if ($bad.Count -gt 0) {
        Add-Result 'Fysieke schijven' 'PROBLEEM' ("Mogelijk defect: {0}. Maak direct een back-up." -f ($bad -join ', '))
    }
    elseif ($unknown.Count -gt 0) {
        Add-Result 'Fysieke schijven' 'AANDACHT' ("Gezondheid onbekend voor: {0}." -f ($unknown -join ', '))
    }
    else {
        Add-Result 'Fysieke schijven' 'GOED' 'Alle gevonden schijven melden Healthy.'
    }
}
catch {
    Add-Result 'Fysieke schijven' 'AANDACHT' $_.Exception.Message
}

Write-Line ''
Write-Line 'VOLUMES EN VRIJE RUIMTE'
try {
    $low = @()
    foreach ($volume in @(Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 })) {
        $freePercent = [Math]::Round(($volume.SizeRemaining / $volume.Size) * 100, 0)
        Write-Line ("Station {0}: {1:N1} GB vrij van {2:N1} GB ({3} procent), status {4}" -f $volume.DriveLetter, ($volume.SizeRemaining / 1GB), ($volume.Size / 1GB), $freePercent, $volume.HealthStatus)
        if ($freePercent -lt 15) { $low += ("{0}:" -f $volume.DriveLetter) }
    }
    if ($low.Count -gt 0) {
        Add-Result 'Vrije ruimte' 'AANDACHT' ("Minder dan 15 procent vrij op {0}." -f ($low -join ', '))
    }
    else {
        Add-Result 'Vrije ruimte' 'GOED' 'Alle gevonden volumes hebben minstens 15 procent vrije ruimte.'
    }
}
catch {
    Add-Result 'Vrije ruimte' 'AANDACHT' $_.Exception.Message
}

Write-Line ''
Write-Line 'BESTANDSSYSTEEMCONTROLE'
try {
    & chkdsk.exe $env:SystemDrive /scan | ForEach-Object { Write-Line $_ }
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        Add-Result 'CHKDSK' 'GOED' 'Geen bestandssysteemproblemen gemeld.'
    }
    elseif ($code -eq 1) {
        Add-Result 'CHKDSK' 'AANDACHT' 'Er is een bestandssysteemprobleem gevonden.'
    }
    else {
        Add-Result 'CHKDSK' 'PROBLEEM' ("Controle eindigde met foutcode {0}." -f $code)
    }
}
catch {
    Add-Result 'CHKDSK' 'PROBLEEM' $_.Exception.Message
}

Write-Line ''
Write-Line 'ADVIES'
Write-Line 'Maak onmiddellijk een back-up bij Predictive Failure, fouten of een ongezonde schijf.'
Write-Line 'SMART is een waarschuwing, geen garantie: een schijf kan ook zonder waarschuwing defect raken.'
Write-Line 'Gebruik voor de nauwkeurigste controle ook het diagnoseprogramma van de schijffabrikant.'
Write-Line ''
Write-Line ("Rapport: {0}" -f $reportPath)
Start-Process notepad.exe $reportPath
