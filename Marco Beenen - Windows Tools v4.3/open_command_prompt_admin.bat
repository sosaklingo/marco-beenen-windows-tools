@echo off
title Command Prompt als administrator openen - Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Command Prompt wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -Verb RunAs"
    exit /b
)

echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Command Prompt is gestart met administratorrechten.
cmd
