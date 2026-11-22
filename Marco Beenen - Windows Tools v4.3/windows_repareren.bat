@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Windows repareren - Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Windows-reparatie wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

cls
echo ================================================================
echo              WINDOWS REPAREREN - MARCO BEENEN
echo ================================================================
echo.
echo Deze tool voert achtereenvolgens uit:
echo   1. DISM /RestoreHealth
echo   2. SFC /scannow
echo.
echo De controle kan 15 tot 60 minuten duren. Onderbreek de computer niet.
echo Sla open documenten op voordat u verdergaat.
echo.
choice /c JN /n /m "Windows nu controleren en repareren? [J/N]: "
if errorlevel 2 exit /b 0

for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "RAPPORTMAP=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%RAPPORTMAP%" mkdir "%RAPPORTMAP%"
if not exist "%RAPPORTMAP%" (
    echo FOUT: de rapportenmap kon niet worden gemaakt.
    pause
    exit /b 1
)
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "RAPPORT=%RAPPORTMAP%\Windows_reparatie_%DATUM%.txt"

echo Windows-reparatie gestart op %date% om %time% > "%RAPPORT%"
echo.>> "%RAPPORT%"
echo.
echo [1/2] Windows-image repareren met DISM...
dism.exe /Online /Cleanup-Image /RestoreHealth
set "DISM_CODE=%errorlevel%"
echo DISM-foutcode: %DISM_CODE%>> "%RAPPORT%"
dism.exe /Online /Cleanup-Image /CheckHealth >> "%RAPPORT%" 2>&1

echo.
echo [2/2] Windows-systeembestanden controleren met SFC...
sfc.exe /scannow
set "SFC_CODE=%errorlevel%"
echo SFC-foutcode: %SFC_CODE%>> "%RAPPORT%"
echo.>> "%RAPPORT%"
echo Raadpleeg voor details ook C:\Windows\Logs\CBS\CBS.log.>> "%RAPPORT%"

echo.
echo Klaar. DISM-foutcode: %DISM_CODE%, SFC-foutcode: %SFC_CODE%
echo Samenvatting: %RAPPORT%
set "REPAIR_CODE=0"
if not "%DISM_CODE%"=="0" set "REPAIR_CODE=1"
if not "%SFC_CODE%"=="0" set "REPAIR_CODE=1"
pause
exit /b %REPAIR_CODE%
