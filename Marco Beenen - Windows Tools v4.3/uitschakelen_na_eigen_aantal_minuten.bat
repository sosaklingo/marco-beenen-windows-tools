@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Computer uitschakelen na zelfgekozen tijd - Marco Beenen

echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo.
echo Hiermee plant u het volledig uitschakelen van deze computer.
echo Sla eerst al uw werk op. Niet-opgeslagen werk kan verloren gaan.
echo.

set "minuten="
set /p "minuten=Na hoeveel hele minuten moet de computer uitschakelen? "

if not defined minuten goto ongeldig
echo(!minuten!| "%SystemRoot%\System32\findstr.exe" /r /x "[0-9][0-9]*" >nul
if errorlevel 1 goto ongeldig

set "WT_MINUTES=!minuten!"
set "seconden="
for /f "usebackq delims=" %%S in (`powershell.exe -NoProfile -Command "$n=0; if (-not [int]::TryParse($env:WT_MINUTES,[ref]$n)) { exit 1 }; if ($n -lt 1 -or $n -gt 5256000) { exit 1 }; [Console]::Write($n * 60)"`) do set "seconden=%%S"
if not defined seconden goto buiten_bereik

echo.
echo De computer wordt na !minuten! minuten volledig uitgeschakeld.
echo U kunt de timer later annuleren met annuleer_uitschakelen.bat.
echo.
choice /c JN /n /m "Wilt u deze uitschakeling nu plannen? [J/N]: "
if errorlevel 2 goto geannuleerd

shutdown.exe /s /t !seconden! /c "Automatisch afsluiten over !minuten! minuten."
if errorlevel 1 goto mislukt

echo.
echo De uitschakeling is gepland voor over !minuten! minuten.
echo Open annuleer_uitschakelen.bat als u de timer wilt stoppen.
pause
exit /b 0

:ongeldig
echo.
echo Ongeldige invoer. Gebruik alleen een heel getal, bijvoorbeeld 30.
pause
exit /b 1

:buiten_bereik
echo.
echo Kies minimaal 1 en maximaal 5256000 minuten.
pause
exit /b 1

:geannuleerd
echo.
echo Er is geen uitschakeling gepland.
pause
exit /b 0

:mislukt
echo.
echo De uitschakeling kon niet worden gepland.
echo Mogelijk staat er al een timer aan. Annuleer die eerst en probeer opnieuw.
pause
exit /b 1
