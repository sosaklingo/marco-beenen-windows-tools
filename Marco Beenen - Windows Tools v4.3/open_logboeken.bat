@echo off
title Windows-logboeken openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Windows-logboeken worden geopend...
start "" eventvwr.msc
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Windows-logboeken konden niet worden geopend.
pause
exit /b 1
