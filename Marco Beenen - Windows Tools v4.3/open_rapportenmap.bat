@echo off
setlocal
title Rapportenmap openen - Gemaakt door Marco Beenen
for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "REPORTS=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%REPORTS%" mkdir "%REPORTS%"
if not exist "%REPORTS%" (
    echo FOUT: de rapportenmap kon niet worden gemaakt.
    pause
    exit /b 1
)
echo Gemaakt door Marco Beenen - Windows Tools v4.3
echo Rapportenmap wordt geopend...
start "" explorer.exe "%REPORTS%"
exit /b 0
