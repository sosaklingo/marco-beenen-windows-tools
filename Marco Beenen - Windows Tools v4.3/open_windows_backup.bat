@echo off
setlocal EnableExtensions
title Windows Back-up openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo De Windows-instellingen voor back-up worden geopend...
start "" "ms-settings:backup"
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Windows Back-up kon niet worden geopend.
pause
exit /b 1
