@echo off
title Local Security Policy openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
if not exist "%SystemRoot%\System32\secpol.msc" goto ontbreekt
echo Local Security Policy wordt geopend...
start "" secpol.msc
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo Lokaal beveiligingsbeleid is niet beschikbaar.
echo Dit is normaal bij Windows Home.
pause
exit /b 1

:mislukt
echo FOUT: Lokaal beveiligingsbeleid kon niet worden geopend.
pause
exit /b 1
