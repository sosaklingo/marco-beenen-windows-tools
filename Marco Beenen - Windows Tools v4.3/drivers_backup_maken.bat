@echo off
setlocal EnableExtensions
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Back-up van drivers maken - Marco Beenen

fltmc >nul 2>&1
if errorlevel 1 (
    echo De driverback-up wordt opnieuw gestart als administrator...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:WT_SELF -WorkingDirectory $env:WT_ROOT -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo Starten als administrator is geannuleerd of mislukt.
        pause
        exit /b 1
    )
    exit /b 0
)

cls
echo ================================================================
echo            DRIVERBACK-UP MAKEN - MARCO BEENEN
echo ================================================================
echo.
echo Alle externe driverpakketten uit het Windows-driverarchief worden
echo gekopieerd. Er worden geen drivers verwijderd of toegevoegd.
echo De back-up kan honderden megabytes of meer groot worden.
echo.
choice /c JN /n /m "Driverback-up nu maken? [J/N]: "
if errorlevel 2 exit /b 0

for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
for /f %%D in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "BACKUPMAP=%BUREAUBLAD%\Driverback-up_%DATUM%"
mkdir "%BACKUPMAP%" >nul 2>&1
if errorlevel 1 (
    echo FOUT: de back-upmap kon niet worden gemaakt.
    pause
    exit /b 1
)
set "LOG=%BACKUPMAP%\Driverback-up_log.txt"

echo.
echo Drivers exporteren. Dit kan enkele minuten duren...
"%SystemRoot%\System32\pnputil.exe" /export-driver * "%BACKUPMAP%" >"%LOG%" 2>&1
set "BACKUP_CODE=%errorlevel%"

for /f %%C in ('powershell.exe -NoProfile -Command "@(Get-ChildItem -LiteralPath $env:BACKUPMAP -Recurse -Filter '*.inf' -File -ErrorAction SilentlyContinue).Count"') do set "AANTAL=%%C"
if not defined AANTAL set "AANTAL=0"

echo.>>"%LOG%"
echo Aantal geexporteerde INF-bestanden: %AANTAL%>>"%LOG%"

echo.
if "%BACKUP_CODE%"=="0" (
    echo Driverback-up voltooid. Geexporteerde INF-bestanden: %AANTAL%
    echo Map: %BACKUPMAP%
    start "" explorer.exe "%BACKUPMAP%"
) else (
    echo De driverback-up is niet volledig voltooid. Foutcode: %BACKUP_CODE%
    echo Bekijk: %LOG%
)
echo.
pause
exit /b %BACKUP_CODE%
