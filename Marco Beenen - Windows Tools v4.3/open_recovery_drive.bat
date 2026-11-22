@echo off
title Recovery Drive openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
if not exist "%SystemRoot%\System32\RecoveryDrive.exe" goto ontbreekt
echo Recovery Drive wordt geopend...
start "" "%SystemRoot%\System32\RecoveryDrive.exe"
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo FOUT: Herstelstation maken is niet gevonden.
pause
exit /b 1

:mislukt
echo FOUT: Herstelstation maken kon niet worden geopend.
pause
exit /b 1
