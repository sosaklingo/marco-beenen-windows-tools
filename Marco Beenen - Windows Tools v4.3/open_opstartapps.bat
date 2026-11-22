@echo off
setlocal EnableExtensions
title Opstart-apps openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo De Windows-instellingen voor Opstart-apps worden geopend...
start "" "ms-settings:startupapps"
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Opstart-apps kon niet worden geopend.
pause
exit /b 1
