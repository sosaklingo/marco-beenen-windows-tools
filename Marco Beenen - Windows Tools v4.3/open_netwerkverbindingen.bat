@echo off
setlocal EnableExtensions
title Netwerkverbindingen openen - Marco Beenen
set "CONTROL=%SystemRoot%\System32\control.exe"
set "NCPA=%SystemRoot%\System32\ncpa.cpl"
if not exist "%CONTROL%" goto ontbreekt
if not exist "%NCPA%" goto ontbreekt
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Netwerkverbindingen worden geopend...
start "" "%CONTROL%" ncpa.cpl
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo FOUT: Netwerkverbindingen zijn niet beschikbaar op deze Windows-installatie.
pause
exit /b 1

:mislukt
echo FOUT: Netwerkverbindingen konden niet worden geopend.
pause
exit /b 1
