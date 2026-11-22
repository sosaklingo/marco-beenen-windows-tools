@echo off
title Computer uitschakelen na 10 minuten - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Je computer wordt over 10 minuten automatisch afgesloten.
echo Sla eerst al je werk op. Niet-opgeslagen werk kan verloren gaan.
echo.
echo Wil je dit annuleren? Open dan: annuleer_uitschakelen.bat
echo.
choice /c JN /n /m "Uitschakeling nu plannen? [J/N]: "
if errorlevel 2 exit /b 0
shutdown.exe /s /t 600 /c "Automatisch afsluiten over 10 minuten."
set "SHUTDOWN_CODE=%errorlevel%"
if not "%SHUTDOWN_CODE%"=="0" (
    echo.
    echo De uitschakeling kon niet worden gepland. Mogelijk staat al een timer aan.
)
pause
exit /b %SHUTDOWN_CODE%
