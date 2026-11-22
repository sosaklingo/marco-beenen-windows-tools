@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Microsoft Defender-scan - Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De Defender-scan wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

cls
echo ================================================================
echo           MICROSOFT DEFENDER-SCAN - MARCO BEENEN
echo ================================================================
echo.
echo   [1] Snelle scan
echo   [2] Volledige scan - kan meerdere uren duren
echo   [0] Annuleren
echo.
choice /c 120 /n /m "Maak een keuze: "
if errorlevel 3 exit /b 0
if errorlevel 2 set "SCANTYPE=FullScan"
if errorlevel 2 set "SCANTEKST=Volledige scan"
if errorlevel 1 if not defined SCANTYPE set "SCANTYPE=QuickScan"
if errorlevel 1 if not defined SCANTEKST set "SCANTEKST=Snelle scan"

echo.
echo %SCANTEKST% geselecteerd. Sla open documenten op.
choice /c JN /n /m "Scan starten? [J/N]: "
if errorlevel 2 exit /b 0

for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "RAPPORTMAP=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%RAPPORTMAP%" mkdir "%RAPPORTMAP%"
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "RAPPORT=%RAPPORTMAP%\Defender_scan_%DATUM%.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "if (-not (Get-Command Start-MpScan -ErrorAction SilentlyContinue)) { throw 'Microsoft Defender is niet beschikbaar. Mogelijk gebruikt deze computer andere antivirussoftware.' };" ^
  "('Microsoft Defender - ' + $env:SCANTEKST) | Out-File -LiteralPath $env:RAPPORT -Encoding utf8;" ^
  "Get-MpComputerStatus | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated,QuickScanAge,FullScanAge | Format-List | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;" ^
  "Write-Host 'Defender-definities worden bijgewerkt...' -ForegroundColor Cyan; Update-MpSignature;" ^
  "Write-Host '%SCANTEKST% wordt uitgevoerd...' -ForegroundColor Cyan; Start-MpScan -ScanType %SCANTYPE%;" ^
  "Get-MpThreatDetection | Select-Object -First 20 InitialDetectionTime,ThreatName,ActionSuccess,Resources | Format-List | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8"
set "SCAN_CODE=%errorlevel%"

echo.
if "%SCAN_CODE%"=="0" (echo Scan voltooid.) else (echo De scan kon niet volledig worden uitgevoerd. Foutcode: %SCAN_CODE%)
echo Rapport: %RAPPORT%
pause
exit /b %SCAN_CODE%
