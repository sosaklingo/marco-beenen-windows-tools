@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Volledige Computerdiagnose - Gemaakt door Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De computer test wordt opnieuw gestart als administrator...
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
$ProgressPreference = 'SilentlyContinue'
$results = @()
$desktop = [Environment]::GetFolderPath('Desktop')
$reports = Join-Path $desktop 'Computerdiagnose rapporten'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$reportPath = Join-Path $reports ("Computer_test_{0}.txt" -f $stamp)
$transcriptStarted = $false

function Show-Section([string]$title) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor DarkGray
    Write-Host $title -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor DarkGray
}

function Add-Result([string]$part, [string]$status, [string]$details) {
    $script:results += [PSCustomObject]@{
        Part    = $part
        Status  = $status
        Details = $details
    }

    $color = switch ($status) {
        'GOED'     { 'Green' }
        'AANDACHT' { 'Yellow' }
        'INFO'     { 'Cyan' }
        default    { 'Red' }
    }
    Write-Host ("[{0}] {1}" -f $status, $details) -ForegroundColor $color
}

Clear-Host
try {
    Start-Transcript -LiteralPath $reportPath -Force | Out-Null
    $transcriptStarted = $true
}
catch {
    Write-Host 'Het tekstrapport kon niet worden gestart; de test gaat wel door.' -ForegroundColor Yellow
}

Write-Host 'Volledige Computerdiagnose - Gemaakt door Marco Beenen' -ForegroundColor White
Write-Host 'Windows Tools v4.3' -ForegroundColor Gray
Write-Host 'De controles kunnen 10 tot 30 minuten duren.' -ForegroundColor Gray
Write-Host 'Er wordt niets gerepareerd, verwijderd of gewijzigd.' -ForegroundColor Gray

Show-Section '1/15 - Computer en Windows'
try {
    $computer = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $bios = Get-CimInstance Win32_BIOS
    $uptime = (Get-Date) - $os.LastBootUpTime

    Write-Host ("Computer       : {0} {1}" -f $computer.Manufacturer, $computer.Model)
    Write-Host ("Windows        : {0}" -f $os.Caption)
    Write-Host ("Versie/build   : {0} / {1}" -f $os.Version, $os.BuildNumber)
    Write-Host ("BIOS-versie    : {0}" -f $bios.SMBIOSBIOSVersion)
    Write-Host ("Actief sinds   : {0:N1} dagen" -f $uptime.TotalDays)
    Add-Result 'Windows' 'GOED' 'Windows en de basisgegevens zijn leesbaar.'
}
catch {
    Add-Result 'Windows' 'PROBLEEM' $_.Exception.Message
}

Show-Section '2/15 - CPU'
try {
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    if ($null -eq $cpu) { throw 'Windows kon geen processor vinden.' }
    Write-Host ("Processor       : {0}" -f $cpu.Name.Trim())
    Write-Host ("Kernen          : {0} fysiek, {1} logisch" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)

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
        throw 'De CPU-rekencontrole gaf een onverwacht resultaat.'
    }
    Add-Result 'CPU' 'GOED' ("Rekencontrole voltooid in {0:N2} seconden." -f $timer.Elapsed.TotalSeconds)
}
catch {
    Add-Result 'CPU' 'PROBLEEM' $_.Exception.Message
}

Show-Section '3/15 - Geheugen (RAM)'
try {
    $memoryComputer = Get-CimInstance Win32_ComputerSystem
    $modules = @(Get-CimInstance Win32_PhysicalMemory)
    $totalGb = [Math]::Round($memoryComputer.TotalPhysicalMemory / 1GB, 1)
    Write-Host ("Totaal          : {0} GB" -f $totalGb)
    Write-Host ("RAM-modules     : {0}" -f $modules.Count)

    $testSize = 256MB
    $buffer = [byte[]]::new($testSize)
    for ($i = 0; $i -lt $testSize; $i += 4096) { $buffer[$i] = 165 }
    for ($i = 0; $i -lt $testSize; $i += 4096) {
        if ($buffer[$i] -ne 165) { throw "Geheugenfout gevonden bij positie $i." }
    }
    Remove-Variable buffer
    [GC]::Collect()
    Add-Result 'Geheugen' 'GOED' '256 MB is beschreven en foutloos teruggelezen.'
}
catch {
    Add-Result 'Geheugen' 'PROBLEEM' $_.Exception.Message
}

Show-Section '4/15 - SSD/HDD, SMART en vrije ruimte'
try {
    $physicalDisks = @(Get-PhysicalDisk)
    if ($physicalDisks.Count -eq 0) { throw 'Windows heeft geen fysieke schijfgegevens teruggegeven.' }

    $badDisks = @()
    $unknownDisks = @()
    foreach ($disk in $physicalDisks) {
        $sizeGb = [Math]::Round($disk.Size / 1GB, 1)
        $operational = @($disk.OperationalStatus) -join ', '
        Write-Host ("Schijf          : {0}" -f $disk.FriendlyName)
        Write-Host ("Type/grootte    : {0}, {1} GB" -f $disk.MediaType, $sizeGb)
        Write-Host ("Gezondheid      : {0}, {1}" -f $disk.HealthStatus, $operational)

        try {
            $reliability = Get-StorageReliabilityCounter -PhysicalDisk $disk
            if ($null -ne $reliability.Temperature) {
                Write-Host ("Temperatuur     : {0} C" -f $reliability.Temperature)
            }
            if ($null -ne $reliability.Wear) {
                Write-Host ("Slijtagewaarde  : {0}" -f $reliability.Wear)
            }
            if ($null -ne $reliability.ReadErrorsTotal) {
                Write-Host ("Leesfouten      : {0}" -f $reliability.ReadErrorsTotal)
            }
            if ($null -ne $reliability.WriteErrorsTotal) {
                Write-Host ("Schrijffouten   : {0}" -f $reliability.WriteErrorsTotal)
            }
        }
        catch {
            Write-Host 'Extra SMART-waarden zijn voor deze schijf niet beschikbaar.' -ForegroundColor DarkGray
        }
        Write-Host ''

        if (($disk.HealthStatus -notin @('Healthy', 'Unknown')) -or ($operational -match 'Lost Communication|Predictive Failure|Error')) {
            $badDisks += $disk.FriendlyName
        }
        elseif ($disk.HealthStatus -eq 'Unknown') {
            $unknownDisks += $disk.FriendlyName
        }
    }

    if ($badDisks.Count -gt 0) {
        Add-Result 'Schijfgezondheid' 'PROBLEEM' ("Mogelijk probleem met: {0}" -f ($badDisks -join ', '))
    }
    elseif ($unknownDisks.Count -gt 0) {
        Add-Result 'Schijfgezondheid' 'AANDACHT' ("Gezondheid onbekend voor: {0}" -f ($unknownDisks -join ', '))
    }
    else {
        Add-Result 'Schijfgezondheid' 'GOED' 'Alle gevonden fysieke schijven melden Healthy.'
    }
}
catch {
    Add-Result 'Schijfgezondheid' 'AANDACHT' $_.Exception.Message
}

try {
    $lowVolumes = @()
    $volumes = @(Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 })
    foreach ($volume in $volumes) {
        $freeGb = [Math]::Round($volume.SizeRemaining / 1GB, 1)
        $sizeGb = [Math]::Round($volume.Size / 1GB, 1)
        $freePercent = [Math]::Round(($volume.SizeRemaining / $volume.Size) * 100, 0)
        Write-Host ("Station {0}:     {1} GB vrij van {2} GB ({3} procent)" -f $volume.DriveLetter, $freeGb, $sizeGb, $freePercent)
        if ($freePercent -lt 15) { $lowVolumes += ("{0}:" -f $volume.DriveLetter) }
    }
    if ($lowVolumes.Count -gt 0) {
        Add-Result 'Opslagruimte' 'AANDACHT' ("Minder dan 15 procent vrij op: {0}" -f ($lowVolumes -join ', '))
    }
    else {
        Add-Result 'Opslagruimte' 'GOED' 'Er is voldoende vrije ruimte op de gevonden volumes.'
    }
}
catch {
    Add-Result 'Opslagruimte' 'AANDACHT' $_.Exception.Message
}

Show-Section '5/15 - Bestandssysteem (CHKDSK)'
try {
    Write-Host ("Online controle van {0}; er wordt niets gerepareerd..." -f $env:SystemDrive) -ForegroundColor Gray
    & chkdsk.exe $env:SystemDrive /scan
    $chkdskCode = $LASTEXITCODE
    if ($chkdskCode -eq 0) {
        Add-Result 'CHKDSK' 'GOED' 'Geen bestandssysteemproblemen gemeld.'
    }
    elseif ($chkdskCode -eq 1) {
        Add-Result 'CHKDSK' 'AANDACHT' 'CHKDSK heeft een probleem gemeld; bekijk het rapport.'
    }
    else {
        Add-Result 'CHKDSK' 'PROBLEEM' ("De controle eindigde met foutcode {0}." -f $chkdskCode)
    }
}
catch {
    Add-Result 'CHKDSK' 'PROBLEEM' $_.Exception.Message
}

Show-Section '6/15 - GPU en DirectX'
try {
    $gpus = @(Get-CimInstance Win32_VideoController)
    if ($gpus.Count -eq 0) { throw 'Windows kon geen videokaart vinden.' }
    $gpuProblems = @()
    foreach ($gpu in $gpus) {
        Write-Host ("Videokaart      : {0}" -f $gpu.Name)
        Write-Host ("Driver          : {0}" -f $gpu.DriverVersion)
        Write-Host ("Windows-status  : {0}" -f $gpu.Status)
        if (($null -ne $gpu.ConfigManagerErrorCode) -and ($gpu.ConfigManagerErrorCode -ne 0)) {
            $gpuProblems += ("{0}: foutcode {1}" -f $gpu.Name, $gpu.ConfigManagerErrorCode)
        }
    }

    $dxdiagPath = Join-Path $reports ("DirectX_rapport_{0}.txt" -f $stamp)
    $dxArguments = "/whql:off /t `"$dxdiagPath`""
    $dxProcess = Start-Process -FilePath dxdiag.exe -ArgumentList $dxArguments -Wait -PassThru
    if ((-not (Test-Path -LiteralPath $dxdiagPath)) -or ((Get-Item -LiteralPath $dxdiagPath).Length -lt 100)) {
        throw 'DirectX kon geen geldig diagnoserapport maken.'
    }
    Write-Host ("DirectX-rapport : {0}" -f $dxdiagPath)

    if ($gpuProblems.Count -gt 0) { throw ($gpuProblems -join '; ') }
    Add-Result 'GPU/DirectX' 'GOED' 'Videokaart gevonden, geen apparaatfout en DirectX-rapport gemaakt.'
}
catch {
    Add-Result 'GPU/DirectX' 'PROBLEEM' $_.Exception.Message
}

Show-Section '7/15 - Drivers en apparaten'
try {
    $devices = @(Get-CimInstance Win32_PnPEntity)
    $badDevices = @($devices | Where-Object {
        ($null -ne $_.ConfigManagerErrorCode) -and ($_.ConfigManagerErrorCode -ne 0)
    })
    if ($badDevices.Count -gt 0) {
        Write-Host 'Apparaten met een Windows-foutcode:' -ForegroundColor Yellow
        $badDevices | Select-Object Name, PNPClass, ConfigManagerErrorCode | Format-Table -AutoSize
        Add-Result 'Drivers' 'AANDACHT' ("{0} apparaat/apparaten melden een fout of zijn uitgeschakeld." -f $badDevices.Count)
    }
    else {
        Add-Result 'Drivers' 'GOED' 'Geen apparaten met een Windows-foutcode gevonden.'
    }

    $usbDevices = @($devices | Where-Object { $_.PNPDeviceID -like 'USB*' })
    $badUsb = @($usbDevices | Where-Object {
        ($null -ne $_.ConfigManagerErrorCode) -and ($_.ConfigManagerErrorCode -ne 0)
    })
    Write-Host ("USB-apparaten    : {0} gevonden" -f $usbDevices.Count)
    if ($badUsb.Count -gt 0) {
        Add-Result 'USB' 'AANDACHT' ("{0} USB-apparaat/apparaten melden een fout." -f $badUsb.Count)
    }
    else {
        Add-Result 'USB' 'GOED' 'Geen foutcodes bij de gevonden USB-apparaten.'
    }
}
catch {
    Add-Result 'Drivers/USB' 'PROBLEEM' $_.Exception.Message
}

Show-Section '8/15 - Netwerk en internet'
try {
    $upAdapters = @(Get-NetAdapter | Where-Object Status -eq 'Up')
    if ($upAdapters.Count -eq 0) { throw 'Er is geen actieve netwerkadapter.' }
    $upAdapters | Select-Object Name, InterfaceDescription, LinkSpeed | Format-Table -AutoSize

    $ipConfig = Get-NetIPConfiguration | Where-Object IPv4DefaultGateway | Select-Object -First 1
    $gatewayOk = $false
    if ($null -ne $ipConfig) {
        $gateway = $ipConfig.IPv4DefaultGateway.NextHop
        $gatewayOk = Test-Connection -ComputerName $gateway -Count 1 -Quiet
        Write-Host ("Router/gateway  : {0}, bereikbaar: {1}" -f $gateway, $gatewayOk)
    }

    $dnsOk = $false
    try {
        [void](Resolve-DnsName www.microsoft.com -ErrorAction Stop)
        $dnsOk = $true
    }
    catch {}
    Write-Host ("DNS-test        : {0}" -f $dnsOk)

    $internetOk = Test-NetConnection -ComputerName www.microsoft.com -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
    Write-Host ("Internet HTTPS  : {0}" -f $internetOk)

    if ($gatewayOk -and $dnsOk -and $internetOk) {
        Add-Result 'Netwerk' 'GOED' 'Netwerkadapter, router, DNS en internet reageren.'
    }
    else {
        Add-Result 'Netwerk' 'AANDACHT' 'Minstens een netwerkcontrole reageerde niet.'
    }
}
catch {
    Add-Result 'Netwerk' 'PROBLEEM' $_.Exception.Message
}

Show-Section '9/15 - Windows-installatie (DISM)'
try {
    & dism.exe /Online /Cleanup-Image /CheckHealth
    $dismCode = $LASTEXITCODE
    if ($dismCode -eq 0) {
        Add-Result 'DISM' 'GOED' 'Windows-imagecontrole is zonder foutcode voltooid.'
    }
    else {
        Add-Result 'DISM' 'AANDACHT' ("DISM eindigde met foutcode {0}." -f $dismCode)
    }
}
catch {
    Add-Result 'DISM' 'PROBLEEM' $_.Exception.Message
}

Show-Section '10/15 - Windows-systeembestanden (SFC)'
try {
    Write-Host 'SFC controleert alleen; er worden geen bestanden gerepareerd.' -ForegroundColor Gray
    & sfc.exe /verifyonly
    $sfcCode = $LASTEXITCODE
    if ($sfcCode -eq 0) {
        Add-Result 'SFC' 'GOED' 'Controle voltooid zonder foutcode.'
    }
    else {
        Add-Result 'SFC' 'AANDACHT' ("SFC eindigde met foutcode {0}; bekijk de tekst hierboven." -f $sfcCode)
    }
}
catch {
    Add-Result 'SFC' 'PROBLEEM' $_.Exception.Message
}

Show-Section '11/15 - Microsoft Defender snelle scan'
try {
    if ($null -eq (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) {
        Add-Result 'Defender' 'INFO' 'Microsoft Defender is niet beschikbaar; mogelijk gebruikt de computer andere antivirussoftware.'
    }
    else {
        $defender = Get-MpComputerStatus
        Write-Host ("Antivirus actief : {0}" -f $defender.AntivirusEnabled)
        Write-Host ("Realtime actief  : {0}" -f $defender.RealTimeProtectionEnabled)
        Write-Host ("Definities datum : {0}" -f $defender.AntivirusSignatureLastUpdated)
        if (-not $defender.AntivirusEnabled) {
            Add-Result 'Defender' 'AANDACHT' 'Microsoft Defender-antivirus is niet actief.'
        }
        else {
            Write-Host 'De snelle virusscan wordt gestart...' -ForegroundColor Gray
            Start-MpScan -ScanType QuickScan
            Add-Result 'Defender' 'GOED' 'De snelle Microsoft Defender-scan is voltooid.'
        }
    }
}
catch {
    Add-Result 'Defender' 'AANDACHT' $_.Exception.Message
}

Show-Section '12/15 - Recente Windows-fouten'
try {
    $since = (Get-Date).AddDays(-7)
    $events = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = $since } -MaxEvents 200 -ErrorAction SilentlyContinue)
    $critical = @($events | Where-Object Level -eq 1)
    $errors = @($events | Where-Object Level -eq 2)
    Write-Host ("Kritieke fouten : {0} in de laatste 7 dagen" -f $critical.Count)
    Write-Host ("Andere fouten   : {0} (maximaal 200 bekeken)" -f $errors.Count)
    if ($events.Count -gt 0) {
        Write-Host 'Nieuwste meldingen:' -ForegroundColor Gray
        $events | Select-Object -First 5 TimeCreated, ProviderName, Id, Message | Format-List
    }
    if ($critical.Count -gt 0) {
        Add-Result 'Logboeken' 'AANDACHT' ("{0} kritieke systeemmelding(en) gevonden." -f $critical.Count)
    }
    else {
        Add-Result 'Logboeken' 'GOED' 'Geen kritieke systeemmeldingen in de laatste 7 dagen.'
    }
}
catch {
    Add-Result 'Logboeken' 'AANDACHT' $_.Exception.Message
}

Show-Section '13/15 - Accu en temperaturen'
try {
    $batteries = @(Get-CimInstance Win32_Battery)
    if ($batteries.Count -eq 0) {
        Add-Result 'Accu' 'INFO' 'Geen accu gevonden; dit is normaal voor een desktopcomputer.'
    }
    else {
        foreach ($battery in $batteries) {
            Write-Host ("Acculading      : {0} procent" -f $battery.EstimatedChargeRemaining)
            Write-Host ("Accustatus      : {0}" -f $battery.Status)
        }
        $batteryPath = Join-Path $reports ("Accu_rapport_{0}.html" -f $stamp)
        & powercfg.exe /batteryreport /output $batteryPath | Out-Host
        if (Test-Path -LiteralPath $batteryPath) {
            Write-Host ("Accurapport     : {0}" -f $batteryPath)
            Add-Result 'Accu' 'GOED' 'Accu gevonden en een Windows-accurapport gemaakt.'
        }
        else {
            Add-Result 'Accu' 'AANDACHT' 'Accu gevonden, maar het accurapport kon niet worden gemaakt.'
        }
    }
}
catch {
    Add-Result 'Accu' 'AANDACHT' $_.Exception.Message
}

try {
    $thermalZones = @(Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop)
    $temperatures = @()
    foreach ($zone in $thermalZones) {
        $celsius = [Math]::Round(($zone.CurrentTemperature / 10) - 273.15, 1)
        if (($celsius -gt 0) -and ($celsius -lt 150)) {
            $temperatures += $celsius
            Write-Host ("Thermische zone : {0} C" -f $celsius)
        }
    }
    if ($temperatures.Count -eq 0) {
        Add-Result 'Temperatuur' 'INFO' 'Windows geeft geen betrouwbare temperatuursensor door.'
    }
    elseif (($temperatures | Measure-Object -Maximum).Maximum -ge 90) {
        Add-Result 'Temperatuur' 'AANDACHT' 'Minstens een gemeten temperatuur is 90 C of hoger.'
    }
    else {
        Add-Result 'Temperatuur' 'GOED' 'De beschikbare temperatuursensoren zijn lager dan 90 C.'
    }
}
catch {
    Add-Result 'Temperatuur' 'INFO' 'Temperaturen zijn via standaard Windows-middelen niet beschikbaar.'
}

Show-Section '14/15 - Geluid, camera en microfoonapparaten'
try {
    $soundDevices = @(Get-CimInstance Win32_SoundDevice)
    $cameraDevices = @(Get-CimInstance Win32_PnPEntity | Where-Object PNPClass -in @('Camera', 'Image'))
    Write-Host ("Geluidsapparaten : {0}" -f $soundDevices.Count)
    Write-Host ("Camera-apparaten : {0}" -f $cameraDevices.Count)
    $badMedia = @($soundDevices + $cameraDevices | Where-Object {
        ($null -ne $_.ConfigManagerErrorCode) -and ($_.ConfigManagerErrorCode -ne 0)
    })
    if ($soundDevices.Count -eq 0) {
        Add-Result 'Audio/camera' 'AANDACHT' 'Windows heeft geen geluidsapparaat gevonden.'
    }
    elseif ($badMedia.Count -gt 0) {
        Add-Result 'Audio/camera' 'AANDACHT' ("{0} media-apparaat/apparaten melden een fout." -f $badMedia.Count)
    }
    else {
        Add-Result 'Audio/camera' 'GOED' 'De gevonden media-apparaten melden geen Windows-foutcode.'
    }
    Write-Host 'Werkelijke opname en weergave moeten handmatig worden beluisterd/bekeken.' -ForegroundColor DarkGray
}
catch {
    Add-Result 'Audio/camera' 'AANDACHT' $_.Exception.Message
}

Show-Section '15/15 - Windows Update'
try {
    Write-Host 'Er wordt alleen naar updates gezocht; beschikbare updates worden alleen geteld.' -ForegroundColor Gray
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $updateResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
    $updateCount = $updateResult.Updates.Count
    Write-Host ("Beschikbare updates: {0}" -f $updateCount)
    if ($updateCount -eq 0) {
        Add-Result 'Windows Update' 'GOED' 'Geen ontbrekende software-updates gevonden.'
    }
    else {
        $titles = @()
        for ($i = 0; $i -lt [Math]::Min($updateCount, 10); $i++) {
            $titles += $updateResult.Updates.Item($i).Title
        }
        $titles | ForEach-Object { Write-Host ("- {0}" -f $_) }
        Add-Result 'Windows Update' 'AANDACHT' ("{0} update(s) beschikbaar; alleen geteld." -f $updateCount)
    }
}
catch {
    Add-Result 'Windows Update' 'AANDACHT' $_.Exception.Message
}

Show-Section 'SAMENVATTING'
foreach ($result in $results) {
    $color = switch ($result.Status) {
        'GOED'     { 'Green' }
        'AANDACHT' { 'Yellow' }
        'INFO'     { 'Cyan' }
        default    { 'Red' }
    }
    Write-Host ("{0,-20} {1,-9} {2}" -f $result.Part, $result.Status, $result.Details) -ForegroundColor $color
}

$problemCount = @($results | Where-Object Status -eq 'PROBLEEM').Count
$attentionCount = @($results | Where-Object Status -eq 'AANDACHT').Count
Write-Host ''
if ($problemCount -gt 0) {
    Write-Host ("Klaar: {0} mogelijk probleem en {1} aandachtspunt(en) gevonden." -f $problemCount, $attentionCount) -ForegroundColor Red
}
elseif ($attentionCount -gt 0) {
    Write-Host ("Klaar: geen directe problemen, wel {0} aandachtspunt(en)." -f $attentionCount) -ForegroundColor Yellow
}
else {
    Write-Host 'Klaar: alle automatische basiscontroles zijn goed doorlopen.' -ForegroundColor Green
}

Write-Host ''
Write-Host ("Tekstrapport: {0}" -f $reportPath) -ForegroundColor White
Write-Host 'Een uitslag GOED sluit een verborgen hardwaredefect niet volledig uit.' -ForegroundColor Gray
Write-Host 'De volledige Windows-geheugentest vereist een herstart en start nooit vanzelf.' -ForegroundColor Gray

Show-Section 'AANBEVOLEN VERVOLGSTAPPEN'
if (@($results | Where-Object { $_.Part -in @('Schijfgezondheid', 'Opslagruimte', 'CHKDSK') -and $_.Status -in @('AANDACHT', 'PROBLEEM') }).Count -gt 0) {
    Write-Host '- Maak eerst een back-up en start daarna uitgebreide_schijfcontrole.bat.' -ForegroundColor Yellow
}
if (@($results | Where-Object { $_.Part -match 'Drivers|USB|GPU' -and $_.Status -in @('AANDACHT', 'PROBLEEM') }).Count -gt 0) {
    Write-Host '- Open Computerbeheer en controleer Apparaatbeheer op waarschuwingstekens.' -ForegroundColor Yellow
}
if (@($results | Where-Object { $_.Part -eq 'Netwerk' -and $_.Status -in @('AANDACHT', 'PROBLEEM') }).Count -gt 0) {
    Write-Host '- Start netwerk_stabiliteitstest.bat en bij wifi ook wifi_rapport_maken.bat.' -ForegroundColor Yellow
}
if (@($results | Where-Object { $_.Part -in @('DISM', 'SFC') -and $_.Status -in @('AANDACHT', 'PROBLEEM') }).Count -gt 0) {
    Write-Host '- Bewaar het rapport voordat u Windows-reparatieopdrachten uitvoert.' -ForegroundColor Yellow
}
if (@($results | Where-Object { $_.Part -eq 'Temperatuur' -and $_.Status -eq 'AANDACHT' }).Count -gt 0) {
    Write-Host '- Stop zware belasting en gebruik de temperatuur- en stresstesthandleiding.' -ForegroundColor Yellow
}
if (@($results | Where-Object { $_.Part -eq 'Logboeken' -and $_.Status -eq 'AANDACHT' }).Count -gt 0) {
    Write-Host '- Open Betrouwbaarheidsgeschiedenis en vergelijk de exacte fouttijd.' -ForegroundColor Yellow
}
if (($problemCount -eq 0) -and ($attentionCount -eq 0)) {
    Write-Host '- Geen directe vervolgstap nodig. Bewaar het rapport als nulmeting.' -ForegroundColor Green
}

if ($transcriptStarted) {
    Stop-Transcript | Out-Null
}

$memoryAnswer = Read-Host 'Windows Geheugendiagnose openen voor een volledige RAM-test? (J/N)'
if ($memoryAnswer -match '^[JjYy]') {
    Start-Process mdsched.exe
}
