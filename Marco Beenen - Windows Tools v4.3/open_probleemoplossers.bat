@echo off
setlocal EnableExtensions
title Windows-probleemoplossers openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Windows-probleemoplossers worden geopend...
start "" "ms-settings:troubleshoot"
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Windows-probleemoplossers konden niet worden geopend.
pause
exit /b 1
