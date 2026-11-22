@echo off
setlocal EnableExtensions
title Windows Tools zelftest - Marco Beenen
set "WT_ROOT=%~dp0"
set "WT_SELF=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$raw=Get-Content -LiteralPath $env:WT_SELF -Raw; $marker=':'+'POWERSHELL_PAYLOAD'; $start=$raw.LastIndexOf($marker); if($start -lt 0){throw 'Zelftestcode niet gevonden.'}; Invoke-Expression ($raw.Substring($start+$marker.Length))"
set "TOOL_CODE=%errorlevel%"
echo.
pause
exit /b %TOOL_CODE%

:POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $env:WT_ROOT).Path
$desktop = [Environment]::GetFolderPath('Desktop')
$reports = Join-Path $desktop 'Computerdiagnose rapporten'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$reportPath = Join-Path $reports ("Windows_Tools_zelftest_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
$lines = @()
$problems = @()
$attention = @()
function Add([string]$text='') { $script:lines += $text; Write-Host $text }
function Problem([string]$text) { $script:problems += $text; Add ("PROBLEEM: {0}" -f $text) }
function Attention([string]$text) { $script:attention += $text; Add ("AANDACHT: {0}" -f $text) }

Clear-Host
Add 'WINDOWS TOOLS ZELFTEST - MARCO BEENEN'
Add 'Gemaakt door Marco Beenen - Windows Tools v4.3'
Add ("Datum: {0}" -f (Get-Date))
Add ("Map: {0}" -f $root)
Add ''

$menuPath = Join-Path $root 'START - Windows Tools.bat'
if (-not (Test-Path -LiteralPath $menuPath)) { Problem 'Het hoofdmenu ontbreekt.' }
else {
    $menuText = Get-Content -LiteralPath $menuPath -Raw
    if ($menuText -notmatch 'Windows Tools v4\.3') { Problem 'Het hoofdmenu heeft niet versie 4.3.' }
    $targets = @([regex]::Matches($menuText, 'call\s+"%~dp0([^"\r\n]+\.(?:bat|cmd))"', 'IgnoreCase') | ForEach-Object { $_.Groups[1].Value })
    foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $target))) { Problem ("Menuverwijzing ontbreekt: {0}" -f $target) }
    }
    foreach ($duplicate in @($targets | Group-Object | Where-Object Count -gt 1)) { Problem ("Dubbele menuverwijzing: {0}" -f $duplicate.Name) }
    $tools = @(Get-ChildItem -LiteralPath $root -Filter '*.bat' -File | Where-Object Name -ne 'START - Windows Tools.bat')
    foreach ($tool in $tools) { if ($tool.Name -notin $targets) { Problem ("BAT-bestand staat niet in het menu: {0}" -f $tool.Name) } }
    $cmdTools = @(Get-ChildItem -LiteralPath $root -Filter '*.cmd' -File)
    foreach ($tool in $cmdTools) { if ($tool.Name -notin $targets) { Problem ("CMD-startbestand staat niet in het menu: {0}" -f $tool.Name) } }
    Add ("Menuverwijzingen: {0}; BAT-bestanden: {1}; CMD-startbestanden: {2}" -f $targets.Count, ($tools.Count + 1), $cmdTools.Count)
}

foreach ($name in @('Handleiding computer testen - Marco Beenen.pdf','LEES MIJ - Handleiding computer testen.txt','LEESMIJ_RDP.txt','RDP_Diagnose_Windows11.ps1')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $name))) { Problem ("Bestand ontbreekt: {0}" -f $name) }
}

$rdpScript = Join-Path $root 'RDP_Diagnose_Windows11.ps1'
if (Test-Path -LiteralPath $rdpScript) {
    if ($ExecutionContext.SessionState.LanguageMode -eq 'FullLanguage') {
        $tokens = $null
        $parseErrors = $null
        [Management.Automation.Language.Parser]::ParseFile($rdpScript, [ref]$tokens, [ref]$parseErrors) | Out-Null
        foreach ($parseError in @($parseErrors)) { Problem ("PowerShell-fout in RDP-diagnose: {0}" -f $parseError.Message) }
    } else {
        Attention 'Uitgebreide PowerShell-syntaxiscontrole overgeslagen door de beperkte Windows-taalmodus.'
    }
}

Add ''
Add 'WINDOWS-ONDERDELEN'
foreach ($command in @('powershell.exe','choice.exe','shutdown.exe','diskpart.exe','dism.exe','sfc.exe','chkdsk.exe','pnputil.exe','powercfg.exe','netsh.exe','perfmon.exe','eventvwr.exe','mmc.exe')) {
    if (Get-Command $command -ErrorAction SilentlyContinue) { Add ("GOED: {0}" -f $command) } else { Problem ("Windows-onderdeel niet gevonden: {0}" -f $command) }
}
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) { Attention 'Winget ontbreekt; alleen Apps automatisch updaten werkt dan niet.' }
if (-not (Test-Path -LiteralPath (Join-Path $env:SystemRoot 'System32\secpol.msc'))) { Attention 'Lokaal beveiligingsbeleid is niet beschikbaar; dit is normaal bij Windows Home.' }

Add ''
if ($problems.Count -eq 0) { Add 'EINDRESULTAAT: GOED - het pakket is compleet en alle menuverwijzingen bestaan.' }
else { Add ("EINDRESULTAAT: PROBLEEM - {0} probleem/problemen gevonden." -f $problems.Count) }
if ($attention.Count -gt 0) { Add ("Aanvullende aandachtspunten: {0}" -f $attention.Count) }
Add ("Rapport: {0}" -f $reportPath)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
Start-Process notepad.exe -ArgumentList $reportPath
if ($problems.Count -gt 0) { exit 1 }
