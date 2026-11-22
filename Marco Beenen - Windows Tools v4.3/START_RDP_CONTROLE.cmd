@echo off
setlocal EnableExtensions
chcp 65001 >nul
title RDP Wrapper-diagnose - Marco Beenen
cd /d "%~dp0"
cls
echo ================================================================
echo          RDP WRAPPER-DIAGNOSE - WINDOWS 11 - MARCO BEENEN
echo ================================================================
echo.
echo Deze controle leest alleen informatie en verandert niets aan Windows.
echo Het rapport komt in de centrale map Computerdiagnose rapporten.
echo.
if not exist "%~dp0RDP_Diagnose_Windows11.ps1" (
    echo FOUT: RDP_Diagnose_Windows11.ps1 ontbreekt.
    echo Pak het volledige Windows Tools-pakket opnieuw uit.
    echo.
    pause
    exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0RDP_Diagnose_Windows11.ps1" -ExtraPath "%~1"
set "TOOL_CODE=%errorlevel%"
echo.
if not "%TOOL_CODE%"=="0" (
    echo De RDP-diagnose is niet volledig afgerond. Foutcode: %TOOL_CODE%
) else (
    echo Controle gereed. Bewaar het RDP_Rapport-tekstbestand.
)
pause
exit /b %TOOL_CODE%
