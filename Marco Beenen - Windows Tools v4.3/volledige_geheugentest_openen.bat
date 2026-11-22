@echo off
setlocal
title Windows Geheugendiagnose - Gemaakt door Marco Beenen
echo ================================================================
echo WINDOWS GEHEUGENDIAGNOSE
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo ================================================================
echo.
echo Deze grondige RAM-test werkt pas nadat de computer opnieuw is gestart.
echo Sla eerst al uw werk op. Windows laat zelf kiezen of u nu of later herstart.
echo.
choice /c JN /n /m "Windows Geheugendiagnose openen? (J/N): "
if errorlevel 2 exit /b
start "" mdsched.exe
exit /b
