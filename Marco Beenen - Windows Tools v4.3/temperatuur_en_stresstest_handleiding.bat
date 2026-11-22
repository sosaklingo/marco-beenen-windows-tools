@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Temperatuur en stresstest handleiding - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De handleiding wordt opnieuw gestart als administrator...
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
$reportPath = Join-Path $reports ("Temperatuur_en_stresstest_handleiding_{0}.txt" -f $stamp)

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = @(Get-CimInstance Win32_VideoController)
$memory = Get-CimInstance Win32_ComputerSystem
$totalGb = [Math]::Round($memory.TotalPhysicalMemory / 1GB, 1)

$lines = @(
    'Temperatuur en stresstest handleiding - Marco Beenen',
    'Gemaakt door Marco Beenen - Windows Tools v4.3',
    ('Datum/tijd      : {0}' -f (Get-Date)),
    '',
    'Gevonden hardware',
    '-----------------',
    ('CPU             : {0}' -f $cpu.Name.Trim()),
    ('RAM             : {0} GB' -f $totalGb),
    'GPU:',
    (($gpu | ForEach-Object { ' - ' + $_.Name }) -join [Environment]::NewLine),
    '',
    'Waarom deze test?',
    '-----------------',
    'De normale diagnose controleert of onderdelen zichtbaar zijn en geen directe fout melden.',
    'Een stresstest controleert of de computer stabiel blijft onder zware belasting.',
    '',
    'Aanbevolen gratis hulpmiddelen',
    '------------------------------',
    '1. HWiNFO64 of HWMonitor voor temperaturen, ventilatoren en spanningen.',
    '2. Cinebench of OCCT voor CPU-belasting.',
    '3. 3DMark, Unigine Heaven/Superposition of OCCT voor GPU-belasting.',
    '4. MemTest86 voor een grondige RAM-test vanaf USB-stick.',
    '',
    'Veilige testvolgorde',
    '--------------------',
    '1. Sluit belangrijke bestanden en programma''s.',
    '2. Start HWiNFO64 of HWMonitor en kijk naar CPU- en GPU-temperaturen.',
    '3. Laat de computer 5 minuten niets doen en noteer de temperaturen.',
    '4. Start een CPU-test van 10 tot 15 minuten.',
    '5. Stop direct bij vastlopen, rare geluiden, brandlucht of temperaturen rond 95 C of hoger.',
    '6. Start daarna pas een GPU-test van 10 tot 15 minuten.',
    '7. Test CPU en GPU tegelijk alleen als de koeling en voeding betrouwbaar zijn.',
    '',
    'Richtwaarden',
    '------------',
    'CPU idle       : vaak 30 tot 55 C.',
    'CPU belasting  : vaak 60 tot 90 C.',
    'GPU idle       : vaak 30 tot 60 C.',
    'GPU belasting  : vaak 60 tot 85 C.',
    'Boven 90 C     : opletten.',
    'Rond 95-100 C  : test stoppen en koeling controleren.',
    '',
    'Let op',
    '------',
    'Deze batch start bewust geen zware stresstest automatisch.',
    'Dat is veiliger, omdat sommige computers door hitte of zwakke voeding kunnen uitvallen.',
    '',
    'Wat noteren bij problemen?',
    '--------------------------',
    '- Welke test draaide er?',
    '- Na hoeveel minuten ging het mis?',
    '- Hoogste CPU-temperatuur.',
    '- Hoogste GPU-temperatuur.',
    '- Foutmelding of blauw scherm-code.',
    '- Maakte de computer veel lawaai of viel hij ineens uit?',
    '',
    ('Rapport opgeslagen op: {0}' -f $reportPath)
)

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Clear-Host
$lines | ForEach-Object { Write-Host $_ }
Start-Process notepad.exe $reportPath
