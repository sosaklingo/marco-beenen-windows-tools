@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Netwerkstabiliteitstest - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De netwerkstabiliteitstest wordt opnieuw gestart als administrator...
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
$reportPath = Join-Path $reports ("Netwerk_stabiliteitstest_{0}.txt" -f $stamp)

function Write-Line([string]$text = '') {
    Write-Host $text
    Add-Content -LiteralPath $reportPath -Value $text
}

function Test-Target([string]$name, [string]$target, [int]$count) {
    Write-Line ''
    Write-Line ("Test: {0} ({1})" -f $name, $target)
    Write-Line ('-' * 60)

    $replies = @(Test-Connection -ComputerName $target -Count $count -ErrorAction SilentlyContinue)
    $received = $replies.Count
    $lost = $count - $received
    $loss = [Math]::Round(($lost / $count) * 100, 1)

    Write-Line ("Verzonden       : {0}" -f $count)
    Write-Line ("Ontvangen       : {0}" -f $received)
    Write-Line ("Verloren        : {0} ({1} procent)" -f $lost, $loss)

    if ($received -gt 0) {
        $avg = [Math]::Round(($replies | Measure-Object ResponseTime -Average).Average, 1)
        $min = ($replies | Measure-Object ResponseTime -Minimum).Minimum
        $max = ($replies | Measure-Object ResponseTime -Maximum).Maximum
        Write-Line ("Ping gemiddeld  : {0} ms" -f $avg)
        Write-Line ("Ping min/max    : {0} / {1} ms" -f $min, $max)
    }

    if ($loss -eq 0) {
        Write-Line 'Uitslag         : GOED - geen pakketverlies gemeten.'
    }
    elseif ($loss -le 5) {
        Write-Line 'Uitslag         : AANDACHT - klein pakketverlies gemeten.'
    }
    else {
        Write-Line 'Uitslag         : PROBLEEM - duidelijk pakketverlies gemeten.'
    }
}

Clear-Host
New-Item -ItemType File -Path $reportPath -Force | Out-Null

Write-Line 'Netwerkstabiliteitstest - Marco Beenen'
Write-Line 'Gemaakt door Marco Beenen - Windows Tools v4.3'
Write-Line ("Datum/tijd      : {0}" -f (Get-Date))
Write-Line 'Deze test controleert router, DNS en internet met meerdere pings.'
Write-Line 'Er wordt niets aangepast aan de computer.'
Write-Line ''

$adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
if ($null -ne $adapter) {
    Write-Line ("Actieve adapter : {0}" -f $adapter.Name)
    Write-Line ("Verbindingssnelheid: {0}" -f $adapter.LinkSpeed)
}
else {
    Write-Line 'PROBLEEM: er is geen actieve netwerkadapter gevonden.'
}

$config = Get-NetIPConfiguration | Where-Object IPv4DefaultGateway | Select-Object -First 1
if ($null -ne $config) {
    $gateway = $config.IPv4DefaultGateway.NextHop
    Write-Line ("Gateway/router  : {0}" -f $gateway)
    Test-Target 'Router/gateway' $gateway 40
}
else {
    Write-Line 'AANDACHT: er is geen standaardgateway gevonden.'
}

try {
    Resolve-DnsName www.microsoft.com -ErrorAction Stop | Out-Null
    Write-Line ''
    Write-Line 'DNS-test        : GOED - www.microsoft.com is opgelost.'
}
catch {
    Write-Line ''
    Write-Line ("DNS-test        : PROBLEEM - {0}" -f $_.Exception.Message)
}

Test-Target 'Internet Microsoft' 'www.microsoft.com' 40
Test-Target 'Internet Cloudflare DNS' '1.1.1.1' 40
Test-Target 'Internet Google DNS' '8.8.8.8' 40

Write-Line ''
Write-Line ('=' * 60)
Write-Line 'Advies'
Write-Line ('=' * 60)
Write-Line '0 procent pakketverlies is goed.'
Write-Line 'Meer dan 5 procent pakketverlies wijst vaak op wifi-, kabel-, router- of providerproblemen.'
Write-Line 'Hoge pingpieken kunnen zorgen voor haperingen bij videobellen, gamen of streamen.'
Write-Line ''
Write-Line ("Rapport opgeslagen op: {0}" -f $reportPath)

Start-Process notepad.exe $reportPath
