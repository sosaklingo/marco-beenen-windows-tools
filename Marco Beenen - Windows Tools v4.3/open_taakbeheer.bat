@echo off
setlocal EnableExtensions
title Taakbeheer openen - Marco Beenen
set "TAAKBEHEER=%SystemRoot%\System32\Taskmgr.exe"
if not exist "%TAAKBEHEER%" goto ontbreekt
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Taakbeheer wordt geopend...
start "" "%TAAKBEHEER%"
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo FOUT: Taakbeheer is niet gevonden op deze Windows-installatie.
pause
exit /b 1

:mislukt
echo FOUT: Taakbeheer kon niet worden geopend.
pause
exit /b 1
