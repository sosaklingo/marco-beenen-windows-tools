# RDP Wrapper / Windows 11 Pro - alleen-lezen diagnose
# Onderdeel van Marco Beenen - Windows Tools v4.3
# Gebruikt PowerShell 5.1 of nieuwer. Wijzigt geen services, register of systeembestanden.
param(
    [string]$ExtraPath = '',
    [string]$ReportRoot = ''
)

$ErrorActionPreference = 'Continue'
$script:ReportLines = New-Object 'System.Collections.Generic.List[string]'

function Show-Line {
    param([string]$Message = '', [ConsoleColor]$Color = [ConsoleColor]::Gray)
    Write-Host $Message -ForegroundColor $Color
    [void]$script:ReportLines.Add($Message)
}
function Show-Section {
    param([string]$Title)
    Show-Line ''
    Show-Line ('=== ' + $Title + ' ===') Cyan
}
function Get-RegValue {
    param([string]$RegPath, [string]$RegName)
    try { return (Get-ItemProperty -LiteralPath $RegPath -Name $RegName -ErrorAction Stop).$RegName }
    catch { return $null }
}
function Find-KnownFiles {
    param([string[]]$Directories)
    $found = @{}
    $names = @('rdpwrap.dll', 'rdpwrap.ini', 'RDPConf.exe', 'RDPWInst.exe', 'RDPCheck.exe')
    $visited = @{}
    foreach ($folder in $Directories) {
        if ([string]::IsNullOrWhiteSpace($folder)) { continue }
        $folder = [Environment]::ExpandEnvironmentVariables($folder.Trim('"'))
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        try { $fullFolder = [IO.Path]::GetFullPath($folder) } catch { continue }
        if ($visited.ContainsKey($fullFolder.ToLowerInvariant())) { continue }
        $visited[$fullFolder.ToLowerInvariant()] = $true
        foreach ($filename in $names) {
            $path = Join-Path $fullFolder $filename
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                if (-not $found.ContainsKey($filename)) { $found[$filename] = New-Object 'System.Collections.Generic.List[string]' }
                [void]$found[$filename].Add($path)
            }
        }
    }
    return $found
}
function Test-LocalTcpPort {
    param([int]$Port)
    $client = New-Object Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(1500, $false)) { return $false }
        try { $client.EndConnect($async); return $true }
        catch { return $false }
    } catch { return $false }
    finally { $client.Close() }
}

Show-Line 'RDP DIAGNOSE - WINDOWS 11 / RDP WRAPPER' White
Show-Line 'Gemaakt door Marco Beenen - Windows Tools v4.3' DarkGray
Show-Line 'Controleert alleen; voert geen installatie, reparatie of wijzigingen uit.' DarkGray
Show-Line ('Tijdstip: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Show-Line ('Computer: ' + $env:COMPUTERNAME)

Show-Section '1. Windows en systeembestand'
$winKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$product = Get-RegValue $winKey 'ProductName'
$display = Get-RegValue $winKey 'DisplayVersion'
$build = Get-RegValue $winKey 'CurrentBuild'
$ubr = Get-RegValue $winKey 'UBR'
$friendlyProduct = if ([int]$build -ge 22000 -and $product -match 'Windows 10') { $product -replace 'Windows 10','Windows 11' } else { $product }
Show-Line ('Windows: ' + $friendlyProduct + ' | versie ' + $display + ' | build ' + $build + '.' + $ubr)
$termsrv = Join-Path $env:SystemRoot 'System32\termsrv.dll'
$termsrvVersion = $null
if (Test-Path -LiteralPath $termsrv -PathType Leaf) {
    $ver = [Diagnostics.FileVersionInfo]::GetVersionInfo($termsrv)
    $termsrvVersion = @($ver.FileMajorPart, $ver.FileMinorPart, $ver.FileBuildPart, $ver.FilePrivatePart) -join '.'
    Show-Line ('termsrv.dll versie: ' + $termsrvVersion) Green
} else {
    Show-Line ('LET OP: termsrv.dll niet gevonden op ' + $termsrv) Yellow
}

Show-Section '2. Remote Desktop Services'
$service = Get-Service -Name 'TermService' -ErrorAction SilentlyContinue
if ($service) {
    $serviceColor = if ($service.Status -eq 'Running') { [ConsoleColor]::Green } else { [ConsoleColor]::Yellow }
    Show-Line ('TermService: ' + $service.Status) $serviceColor
} else { Show-Line 'LET OP: TermService kan niet worden opgevraagd.' Yellow }
$serviceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\TermService\Parameters'
$serviceDllRaw = Get-RegValue $serviceKey 'ServiceDll'
$serviceDll = if ($null -ne $serviceDllRaw) { [Environment]::ExpandEnvironmentVariables([string]$serviceDllRaw).Trim('"') } else { '' }
Show-Line ('ServiceDll: ' + $(if ($serviceDll) { $serviceDll } else { '(onbekend)' }))
$wrapperConnected = ($serviceDll -match '(?i)rdpwrap\.dll$')
if ($wrapperConnected) {
    Show-Line 'RDP Wrapper staat in het ServiceDll-registerpad.' Green
    if (-not (Test-Path -LiteralPath $serviceDll -PathType Leaf)) {
        Show-Line 'LET OP: de gekoppelde rdpwrap.dll bestaat niet op dit pad.' Yellow
    }
} else {
    Show-Line 'LET OP: TermService is niet gekoppeld aan rdpwrap.dll.' Yellow
}

Show-Section '3. RDP-instellingen en lokale poort'
$enabledValue = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections'
if ($enabledValue -eq 0) { Show-Line 'RDP-toegang Windows-instelling: ingeschakeld.' Green }
elseif ($enabledValue -eq 1) { Show-Line 'LET OP: RDP-toegang Windows-instelling: uitgeschakeld.' Yellow }
else { Show-Line 'RDP-toegang Windows-instelling: onbekend.' Yellow }
$portValue = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' 'PortNumber'
$port = if ($null -ne $portValue -and [int]$portValue -gt 0 -and [int]$portValue -le 65535) { [int]$portValue } else { 3389 }
Show-Line ('RDP-poort: ' + $port)
$canConnect = Test-LocalTcpPort $port
if ($canConnect) { Show-Line ('TCP 127.0.0.1:' + $port + ' accepteert verbindingen.') Green }
else { Show-Line ('LET OP: TCP 127.0.0.1:' + $port + ' accepteert geen verbinding.') Yellow }
$nla = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' 'UserAuthentication'
if ($null -ne $nla) { Show-Line ('Network Level Authentication (NLA): ' + $(if ($nla -eq 1) {'ingeschakeld'} else {'uitgeschakeld'})) }
try {
    $firewall = Get-NetFirewallRule -Name 'RemoteDesktop-UserMode-In-TCP' -ErrorAction Stop
    Show-Line ('Windows Firewall RDP TCP-regel: ' + $firewall.Enabled + ' | actie: ' + $firewall.Action)
} catch { Show-Line 'Firewallregel niet automatisch gevonden; controleer eventueel handmatig.' Yellow }

Show-Section '4. RDP Wrapper bestanden op gebruikelijke locaties'
$folders = New-Object 'System.Collections.Generic.List[string]'
$pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
foreach ($f in @(
    (Join-Path $env:ProgramFiles 'RDP Wrapper'),
    $(if ($pf86) { Join-Path $pf86 'RDP Wrapper' }),
    (Join-Path $env:ProgramData 'RDP Wrapper'),
    (Join-Path $env:SystemDrive 'RDPWrap'),
    (Join-Path $env:SystemDrive 'RDP Wrapper'),
    (Join-Path $env:USERPROFILE 'RDP Wrapper'),
    (Join-Path $env:USERPROFILE 'Downloads\RDP Wrapper'),
    (Join-Path $env:USERPROFILE 'Desktop\RDP Wrapper'),
    (Join-Path $env:USERPROFILE 'Downloads\rdpwrap'),
    (Join-Path $env:USERPROFILE 'Desktop\rdpwrap'),
    $ExtraPath
)) { if ($f) { [void]$folders.Add($f) } }
if ($wrapperConnected) { [void]$folders.Add((Split-Path -Path $serviceDll -Parent)) }
foreach ($base in @([Environment]::GetFolderPath('Desktop'), (Join-Path $env:USERPROFILE 'Downloads'))) {
    if (-not (Test-Path -LiteralPath $base -PathType Container)) { continue }
    foreach ($dir in @(Get-ChildItem -LiteralPath $base -Directory -ErrorAction SilentlyContinue)) {
        if ($dir.Name -match '(?i)rdp|wrapper') { [void]$folders.Add($dir.FullName) }
    }
}
$found = Find-KnownFiles -Directories $folders.ToArray()
foreach ($filename in @('rdpwrap.dll', 'rdpwrap.ini', 'RDPConf.exe', 'RDPWInst.exe', 'RDPCheck.exe')) {
    if ($found.ContainsKey($filename)) {
        foreach ($path in $found[$filename]) { Show-Line ($filename + ': ' + $path) Green }
    } else {
        Show-Line ($filename + ': niet gevonden op gebruikelijke locaties.') Yellow
    }
}

Show-Section '5. INI-controle voor exacte termsrv.dll versie'
$iniCompatible = $false
if ($termsrvVersion -and $found.ContainsKey('rdpwrap.ini')) {
    foreach ($ini in $found['rdpwrap.ini']) {
        try {
            $pattern = '^\s*\[' + [regex]::Escape($termsrvVersion) + '\]\s*$'
            $matchesIni = Select-String -LiteralPath $ini -Pattern $pattern -Quiet -ErrorAction Stop
            if ($matchesIni) { Show-Line ('INI bevat versie [' + $termsrvVersion + ']: ' + $ini) Green; $iniCompatible = $true }
            else { Show-Line ('INI bevat versie [' + $termsrvVersion + '] NIET: ' + $ini) Yellow }
        } catch { Show-Line ('INI kon niet worden gelezen: ' + $ini) Yellow }
    }
} else { Show-Line 'Geen INI op gevonden locaties om de versie te vergelijken.' Yellow }
Show-Line 'Een passende INI-sectie bewijst niet dat meerdere sessies echt werken.' DarkGray

Show-Section '6. Huidige aanmeldsessies (informatief)'
try {
    $output = & "$env:SystemRoot\System32\quser.exe" 2>&1
    foreach ($line in @($output)) { Show-Line ([string]$line) }
} catch { Show-Line 'Sessieoverzicht (quser) niet beschikbaar.' Yellow }
Show-Line 'Dit overzicht bewijst niet dat twee NIEUWE RDP-verbindingen tegelijk mogelijk zijn.' DarkGray

Show-Section '7. Eindoordeel en volgende stap'
if (-not $wrapperConnected) {
    Show-Line 'UITSLAG: Windows verwijst niet naar RDP Wrapper. Multi-session via Wrapper is niet aangetoond.' Yellow
    Show-Line 'Controleer of RDP Wrapper ooit geïnstalleerd is; download geen willekeurige DLL-patches.'
} elseif (-not (Test-Path -LiteralPath $serviceDll -PathType Leaf)) {
    Show-Line 'UITSLAG: De Wrapper-verwijzing is aanwezig, maar de DLL ontbreekt. Installatie lijkt beschadigd.' Yellow
} elseif (-not $iniCompatible) {
    Show-Line 'UITSLAG: Wrapper staat gekoppeld; INI-ondersteuning voor deze termsrv-versie is NIET bevestigd.' Yellow
} elseif ($service -and $service.Status -eq 'Running' -and $canConnect) {
    Show-Line 'UITSLAG: Wrapper en RDP luisteren. Test nog HANDMATIG met twee aparte accounts en twee verbindingen.' Green
} else {
    Show-Line 'UITSLAG: Wrapper is gekoppeld, maar service/RDP-poort moet verder worden gecontroleerd.' Yellow
}
if ($found.ContainsKey('RDPConf.exe')) {
    Show-Line ('Open RDPConf.exe voor Wrapper / Service / Listener / Fully supported: ' + $found['RDPConf.exe'][0])
}
Show-Line 'Let op: Windows 11 Pro biedt officieel geen onbeperkte gelijktijdige RDP-gebruikerssessies.'
Show-Line 'Verander niets aan termsrv.dll en stel poort 3389 niet rechtstreeks open op internet.'

$desktop = [Environment]::GetFolderPath('Desktop')
if (-not (Test-Path -LiteralPath $desktop -PathType Container)) { $desktop = $env:TEMP }
$reportFolder = if ([string]::IsNullOrWhiteSpace($ReportRoot)) {
    Join-Path $desktop 'Computerdiagnose rapporten'
} else {
    [Environment]::ExpandEnvironmentVariables($ReportRoot.Trim('"'))
}
try {
    New-Item -ItemType Directory -Path $reportFolder -Force -ErrorAction Stop | Out-Null
} catch {
    $reportFolder = $env:TEMP
    Show-Line 'LET OP: de centrale rapportenmap kon niet worden gemaakt; het rapport wordt tijdelijk opgeslagen.' Yellow
}
$reportName = 'RDP_Rapport_{0}_{1}.txt' -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss')
$reportPath = Join-Path $reportFolder $reportName
$exitCode = 0
try {
    $encoding = New-Object System.Text.UTF8Encoding($true)
    [IO.File]::WriteAllLines($reportPath, $script:ReportLines.ToArray(), $encoding)
    Show-Line ''
    Show-Line ('RAPPORT OPGESLAGEN: ' + $reportPath) Green
} catch {
    Show-Line ('Rapport opslaan mislukt: ' + $_.Exception.Message) Yellow
    $exitCode = 1
}
exit $exitCode
