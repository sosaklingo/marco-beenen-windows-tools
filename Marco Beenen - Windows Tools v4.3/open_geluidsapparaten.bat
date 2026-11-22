@echo off
setlocal EnableExtensions
title Geluidsapparaten openen - Marco Beenen

rem Open het klassieke Windows-venster Geluid direct op het tabblad Afspelen.
if not exist "%SystemRoot%\System32\control.exe" goto sound_missing
if not exist "%SystemRoot%\System32\mmsys.cpl" goto sound_missing

start "" "%SystemRoot%\System32\control.exe" mmsys.cpl,,0
if errorlevel 1 goto sound_error
exit /b 0

:sound_missing
echo FOUT: het klassieke Windows-geluidsmenu is niet gevonden.
echo Open Instellingen en ga naar Systeem ^> Geluid.
echo.
pause
exit /b 1

:sound_error
echo FOUT: het klassieke Windows-geluidsmenu kon niet worden geopend.
echo Open Instellingen en ga naar Systeem ^> Geluid.
echo.
pause
exit /b 1
