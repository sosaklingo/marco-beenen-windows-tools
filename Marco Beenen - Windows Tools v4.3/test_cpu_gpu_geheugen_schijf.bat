@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Hardwarecontrole - CPU, GPU, geheugen en schijf - Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De hardwarecontrole wordt opnieuw gestart als administrator...
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
$results = [ordered]@{}
$desktop = [Environment]::GetFolderPath('Desktop')
$reports = Join-Path $desktop 'Computerdiagnose rapporten'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$reportPath = Join-Path $reports ("Snelle_hardwarecontrole_{0}.txt" -f $stamp)
$transcriptStarted = $false

function Show-Section([string]$title) {
    Write-Host ''
    Write-Host ('=' * 62) -ForegroundColor DarkGray
    Write-Host $title -ForegroundColor Cyan
    Write-Host ('=' * 62) -ForegroundColor DarkGray
}

function Save-Result([string]$part, [string]$status, [string]$details) {
    $script:results[$part] = [PSCustomObject]@{
        Status  = $status
        Details = $details
    }

    $color = switch ($status) {
        'GOED'     { 'Green' }
        'AANDACHT' { 'Yellow' }
        default    { 'Red' }
    }
    Write-Host ("[{0}] {1}" -f $status, $details) -ForegroundColor $color
}

Clear-Host
try {
    Start-Transcript -LiteralPath $reportPath -Force | Out-Null
    $transcriptStarted = $true
}
catch {}
Write-Host 'HARDWARECONTROLE' -ForegroundColor White
Write-Host 'Gemaakt door Marco Beenen - Windows Tools v4.3' -ForegroundColor Gray
Write-Host 'Veilige basiscontrole voor CPU, geheugen, schijf en GPU.' -ForegroundColor Gray
Write-Host 'De controle kan enkele minuten duren.' -ForegroundColor Gray

Show-Section '1/4 - CPU'
try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    if ($null -eq $cpu) { throw 'Windows kon geen processor vinden.' }

    Write-Host ("Processor : {0}" -f $cpu.Name.Trim())
    Write-Host ("Kernen    : {0} fysiek, {1} logisch" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)

    [double]$sum = 0
    $iterations = 500000
    $timer = [Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $iterations; $i++) {
        $term = 1.0 / (2.0 * $i + 1.0)
        if (($i % 2) -eq 0) { $sum += $term } else { $sum -= $term }
    }
    $timer.Stop()
    $calculatedPi = 4.0 * $sum
    if ([Math]::Abs($calculatedPi - [Math]::PI) -gt 0.00001) {
        throw 'De rekencontrole gaf een onverwacht resultaat.'
    }

    Save-Result 'CPU' 'GOED' ("Rekencontrole voltooid in {0:N2} seconden." -f $timer.Elapsed.TotalSeconds)
}
catch {
    Save-Result 'CPU' 'PROBLEEM' $_.Exception.Message
}

Show-Section '2/4 - Geheugen (RAM)'
try {
    $computer = Get-CimInstance Win32_ComputerSystem
    $modules = @(Get-CimInstance Win32_PhysicalMemory)
    $totalGb = [Math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
    Write-Host ("Totaal     : {0} GB" -f $totalGb)
    Write-Host ("Modules    : {0}" -f $modules.Count)

    $testSize = 128MB
    $buffer = [byte[]]::new($testSize)
    for ($i = 0; $i -lt $testSize; $i += 4096) {
        $buffer[$i] = 165
    }
    for ($i = 0; $i -lt $testSize; $i += 4096) {
        if ($buffer[$i] -ne 165) { throw "Geheugenfout gevonden bij positie $i." }
    }
    Remove-Variable buffer
    [GC]::Collect()

    Save-Result 'Geheugen' 'GOED' '128 MB is beschreven en foutloos teruggelezen.'
}
catch {
    Save-Result 'Geheugen' 'PROBLEEM' $_.Exception.Message
}

Show-Section '3/4 - Schijf'
try {
    $driveLetter = $env:SystemDrive.Substring(0, 1)
    $volume = Get-Volume -DriveLetter $driveLetter
    $freeGb = [Math]::Round($volume.SizeRemaining / 1GB, 1)
    $sizeGb = [Math]::Round($volume.Size / 1GB, 1)
    Write-Host ("Systeemschijf : {0}" -f $env:SystemDrive)
    Write-Host ("Vrije ruimte  : {0} GB van {1} GB" -f $freeGb, $sizeGb)
    Write-Host ("Volumestatus  : {0}" -f $volume.HealthStatus)
    Write-Host ''
    Write-Host 'Windows controleert nu het bestandssysteem...' -ForegroundColor Gray

    & chkdsk.exe $env:SystemDrive /scan
    $chkdskCode = $LASTEXITCODE

    if ($chkdskCode -eq 0) {
        Save-Result 'Schijf' 'GOED' 'CHKDSK heeft geen problemen gemeld.'
    }
    elseif ($chkdskCode -eq 1) {
        Save-Result 'Schijf' 'AANDACHT' 'CHKDSK heeft een probleem gevonden; bekijk de tekst hierboven.'
    }
    else {
        Save-Result 'Schijf' 'PROBLEEM' ("CHKDSK kon de controle niet goed afronden (code {0})." -f $chkdskCode)
    }
}
catch {
    Save-Result 'Schijf' 'PROBLEEM' $_.Exception.Message
}

Show-Section '4/4 - GPU'
try {
    $gpus = @(Get-CimInstance Win32_VideoController)
    if ($gpus.Count -eq 0) { throw 'Windows kon geen videokaart vinden.' }

    $gpuProblems = @()
    foreach ($gpu in $gpus) {
        Write-Host ("Videokaart : {0}" -f $gpu.Name)
        Write-Host ("Driver     : {0}" -f $gpu.DriverVersion)
        Write-Host ("Status     : {0}" -f $gpu.Status)
        Write-Host ''

        if (($null -ne $gpu.ConfigManagerErrorCode) -and ($gpu.ConfigManagerErrorCode -ne 0)) {
            $gpuProblems += ("{0}: Windows-foutcode {1}" -f $gpu.Name, $gpu.ConfigManagerErrorCode)
        }
    }

    if ($gpuProblems.Count -gt 0) {
        throw ($gpuProblems -join '; ')
    }
    Save-Result 'GPU' 'GOED' 'Windows ziet de videokaart en meldt geen apparaatfout.'
}
catch {
    Save-Result 'GPU' 'PROBLEEM' $_.Exception.Message
}

Show-Section 'SAMENVATTING'
foreach ($part in $results.Keys) {
    $result = $results[$part]
    $color = switch ($result.Status) {
        'GOED'     { 'Green' }
        'AANDACHT' { 'Yellow' }
        default    { 'Red' }
    }
    Write-Host ("{0,-10} {1,-9} {2}" -f $part, $result.Status, $result.Details) -ForegroundColor $color
}

Write-Host ''
if (@($results.Values | Where-Object Status -eq 'PROBLEEM').Count -gt 0) {
    Write-Host 'Er is minstens een mogelijk probleem gevonden.' -ForegroundColor Red
}
elseif (@($results.Values | Where-Object Status -eq 'AANDACHT').Count -gt 0) {
    Write-Host 'De basiscontrole is klaar, maar een onderdeel vraagt aandacht.' -ForegroundColor Yellow
}
else {
    Write-Host 'Alle vier de onderdelen zijn door de basiscontrole gekomen.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Let op: dit is geen langdurige stresstest. Een volledige RAM-test' -ForegroundColor Gray
Write-Host 'kan met Windows Geheugendiagnose en vereist daarna een herstart.' -ForegroundColor Gray
Write-Host ("Rapport: {0}" -f $reportPath) -ForegroundColor White
if ($transcriptStarted) {
    Stop-Transcript | Out-Null
}
$answer = Read-Host 'Windows Geheugendiagnose openen? (J/N)'
if ($answer -match '^[JjYy]') {
    Start-Process mdsched.exe
}
