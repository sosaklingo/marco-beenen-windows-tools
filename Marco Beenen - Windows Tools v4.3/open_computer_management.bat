@echo off
title Computer Management openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Computer Management wordt geopend...
start "" compmgmt.msc
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Computerbeheer kon niet worden geopend.
pause
exit /b 1
