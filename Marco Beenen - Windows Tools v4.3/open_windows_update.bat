@echo off
setlocal EnableExtensions
title Windows Update openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Windows Update wordt geopend...
start "" "ms-settings:windowsupdate"
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Windows Update kon niet worden geopend.
pause
exit /b 1
