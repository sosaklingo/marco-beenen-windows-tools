@echo off
title Resource Monitor openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Resource Monitor wordt geopend...
if not exist "%SystemRoot%\System32\resmon.exe" goto ontbreekt
start "" "%SystemRoot%\System32\resmon.exe"
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo FOUT: Broncontrole is niet gevonden.
pause
exit /b 1

:mislukt
echo FOUT: Broncontrole kon niet worden geopend.
pause
exit /b 1
