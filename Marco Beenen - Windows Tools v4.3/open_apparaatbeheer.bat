@echo off
setlocal EnableExtensions
title Apparaatbeheer openen - Marco Beenen
set "MMC=%SystemRoot%\System32\mmc.exe"
set "MSC=%SystemRoot%\System32\devmgmt.msc"
if not exist "%MMC%" goto ontbreekt
if not exist "%MSC%" goto ontbreekt
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Apparaatbeheer wordt geopend...
start "" "%MMC%" "%MSC%"
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo FOUT: Apparaatbeheer is niet gevonden op deze Windows-installatie.
pause
exit /b 1

:mislukt
echo FOUT: Apparaatbeheer kon niet worden geopend.
pause
exit /b 1
