@echo off
title Automatisch uitschakelen annuleren - Marco Beenen
echo Gemaakt door Marco Beenen - Windows Tools v4.3
shutdown.exe /a >nul 2>&1
set "SHUTDOWN_CODE=%errorlevel%"
if "%SHUTDOWN_CODE%"=="0" (
    echo De geplande automatische uitschakeling is geannuleerd.
) else (
    echo Er stond geen automatische uitschakeling gepland.
)
pause
exit /b 0
