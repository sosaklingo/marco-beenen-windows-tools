@echo off
setlocal EnableExtensions
title Windows-prestatierapport openen - Marco Beenen

rem Performance Monitor heeft voor een volledig systeemrapport beheerrechten nodig.
fltmc >nul 2>&1
if errorlevel 1 (
    echo Het prestatierapport wordt als administrator geopend...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath ($env:SystemRoot+'\System32\perfmon.exe') -ArgumentList '/report' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo Starten als administrator is geannuleerd of mislukt.
        pause
        exit /b 1
    )
    exit /b 0
)

cls
echo ================================================================
echo        WINDOWS-PRESTATIERAPPORT - MARCO BEENEN
echo ================================================================
echo.
echo Windows verzamelt ongeveer 60 seconden systeemgegevens en toont daarna
echo een rapport over prestaties, hardware, services en systeemreacties.
echo Er worden geen instellingen gewijzigd.
echo.
start "" "%SystemRoot%\System32\perfmon.exe" /report
if errorlevel 1 (
    echo Het prestatierapport kon niet worden geopend.
    pause
    exit /b 1
)
exit /b 0
