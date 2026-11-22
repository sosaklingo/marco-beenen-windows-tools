@echo off
title Systeembeheer openen - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Systeembeheer wordt geopend...
control admintools
if errorlevel 1 goto mislukt
exit /b 0

:mislukt
echo FOUT: Systeembeheer kon niet worden geopend.
pause
exit /b 1
