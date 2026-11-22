@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Windows Systeembeveiliging openen - Marco Beenen
rem Gebruik ook vanuit een 32-bits opdrachtprompt het Windows-systeemprogramma.
set "HERSTEL_EXE=%SystemRoot%\System32\SystemPropertiesProtection.exe"
if exist "%SystemRoot%\Sysnative\SystemPropertiesProtection.exe" set "HERSTEL_EXE=%SystemRoot%\Sysnative\SystemPropertiesProtection.exe"
if not exist "%HERSTEL_EXE%" goto ontbreekt

echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Windows Systeembeveiliging wordt geopend.
echo Klik daar op Systeemherstel om een bestaand herstelpunt te kiezen.
start "" "%HERSTEL_EXE%"
if errorlevel 1 goto mislukt
exit /b 0

:ontbreekt
echo Het venster Systeembeveiliging is niet beschikbaar op deze Windows-installatie.
pause
exit /b 1

:mislukt
echo Windows Systeembeveiliging kon niet worden geopend.
echo Probeer opnieuw en bevestig een eventuele Windows-beveiligingsvraag.
pause
exit /b 1
