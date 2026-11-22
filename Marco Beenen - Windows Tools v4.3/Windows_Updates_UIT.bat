@echo off
setlocal EnableExtensions
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Windows Update uitschakelen - Marco Beenen

echo.
echo LET OP: automatische Windows- en beveiligingsupdates worden uitgeschakeld.
echo Hierdoor kan de computer belangrijke beveiligingsupdates missen.
choice /c JN /n /m "Weet u zeker dat u wilt doorgaan? [J/N]: "
if errorlevel 2 (
    echo.
    echo Geen wijzigingen aangebracht.
    pause
    exit /b 0
)

:: Vraag automatisch om administratorrechten.
fltmc >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Administratorrechten zijn nodig. Er verschijnt nu een melding van Windows.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

echo.
echo Automatische Windows Update wordt uitgeschakeld...
echo.

:: Schakel automatische updates uit via lokaal Windows-beleid.
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
if errorlevel 1 goto fout

:: Stop en deactiveer de services die updates downloaden en installeren.
sc.exe stop UsoSvc >nul 2>&1
sc.exe config UsoSvc start= disabled >nul 2>&1
if errorlevel 1 goto fout
sc.exe stop wuauserv >nul 2>&1
sc.exe config wuauserv start= disabled >nul 2>&1
if errorlevel 1 goto fout

echo Windows Update is uitgeschakeld.
echo Start Windows opnieuw op om de wijziging volledig toe te passen.
echo.
echo Bewaar ook "Windows_Updates_AAN.bat" zodat je updates later weer kunt inschakelen.
echo.
pause
exit /b 0

:fout
echo.
echo FOUT: niet alle instellingen konden worden gewijzigd.
echo Controleer of dit bestand als administrator draait en probeer het opnieuw.
echo Gebruik daarna Windows_Updates_AAN.bat om de standaardinstellingen te herstellen.
echo.
pause
exit /b 1
