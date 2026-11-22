@echo off
title Betrouwbaarheidsgeschiedenis openen - Marco Beenen

echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Betrouwbaarheidsgeschiedenis wordt geopend...
echo.
echo Hier ziet u in een tijdlijn wanneer Windows, drivers of programma's zijn vastgelopen.
echo Let vooral op rode kruisen en terugkerende meldingen op dezelfde dag.
echo.

if not exist "%SystemRoot%\System32\perfmon.exe" goto ontbreekt
start "" "%SystemRoot%\System32\perfmon.exe" /rel
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo FOUT: Betrouwbaarheidsgeschiedenis is niet gevonden.
pause
exit /b 1

:mislukt
echo FOUT: Betrouwbaarheidsgeschiedenis kon niet worden geopend.
pause
exit /b 1
