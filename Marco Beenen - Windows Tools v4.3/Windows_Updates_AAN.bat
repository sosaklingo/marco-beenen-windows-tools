@echo off
setlocal EnableExtensions
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Windows Update inschakelen - Marco Beenen

:: Vraag automatisch om administratorrechten.
fltmc >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Administratorrechten zijn nodig. Er verschijnt nu een melding van Windows.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

echo.
echo Windows Update wordt weer ingeschakeld...
echo.

:: Verwijder alleen het beleid dat door het UIT-bestand is toegevoegd.
reg.exe query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate >nul 2>&1
if not errorlevel 1 (
    reg.exe delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1
    if errorlevel 1 goto fout
)

:: Herstel de gebruikelijke Windows-opstartinstellingen voor de updateservices.
sc.exe config wuauserv start= demand >nul 2>&1
if errorlevel 1 goto fout
sc.exe config UsoSvc start= delayed-auto >nul 2>&1
if errorlevel 1 goto fout
sc.exe start UsoSvc >nul 2>&1
sc.exe start wuauserv >nul 2>&1

echo Windows Update is weer ingeschakeld.
echo Start Windows opnieuw op en controleer daarna via Instellingen ^> Windows Update.
echo.
pause
exit /b 0

:fout
echo.
echo FOUT: niet alle Windows Update-instellingen konden worden hersteld.
echo Controleer of dit bestand als administrator draait en probeer het opnieuw.
echo Open daarna Instellingen ^> Windows Update en controleer de status.
echo.
pause
exit /b 1
