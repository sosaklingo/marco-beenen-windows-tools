@echo off
setlocal EnableExtensions
title Windows-beveiliging openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Windows-beveiliging wordt geopend...
start "" "windowsdefender:"
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Windows-beveiliging kon niet worden geopend.
pause
exit /b 1
