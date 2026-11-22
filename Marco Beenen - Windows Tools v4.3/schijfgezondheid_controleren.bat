@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Schijfgezondheid controleren - Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo De schijfcontrole wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

cls
echo ================================================================
echo          SCHIJFGEZONDHEID CONTROLEREN - MARCO BEENEN
echo ================================================================
echo.
echo Deze snelle controle leest schijfstatus, SMART-gegevens en vrije ruimte.
echo Er wordt niets op de schijven gewijzigd.
echo.

for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "RAPPORTMAP=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%RAPPORTMAP%" mkdir "%RAPPORTMAP%"
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "RAPPORT=%RAPPORTMAP%\Schijfgezondheid_%DATUM%.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$regels=@('SCHIJFGEZONDHEID - MARCO BEENEN',('Datum: '+(Get-Date)),'');" ^
  "$schijven=@(Get-PhysicalDisk);" ^
  "foreach($s in $schijven){$regels+=('Schijf: {0}' -f $s.FriendlyName);$regels+=('Type: {0}  Grootte: {1:N1} GB' -f $s.MediaType,($s.Size/1GB));$regels+=('Gezondheid: {0}  Bedrijfsstatus: {1}' -f $s.HealthStatus,(@($s.OperationalStatus)-join ', '));try{$r=Get-StorageReliabilityCounter -PhysicalDisk $s;$regels+=('Temperatuur: {0} C  Slijtage: {1}  Bedrijfsuren: {2}' -f $r.Temperature,$r.Wear,$r.PowerOnHours);$regels+=('Leesfouten: {0}  Schrijffouten: {1}' -f $r.ReadErrorsTotal,$r.WriteErrorsTotal)}catch{$regels+='Extra SMART-waarden niet beschikbaar.'};$regels+=''};" ^
  "$regels+='VRIJE RUIMTE';" ^
  "Get-Volume | Where-Object {$_.DriveLetter -and $_.Size -gt 0} | ForEach-Object {$regels+=('Station {0}: {1:N1} GB vrij van {2:N1} GB ({3:N0} procent)' -f $_.DriveLetter,($_.SizeRemaining/1GB),($_.Size/1GB),(100*$_.SizeRemaining/$_.Size))};" ^
  "$regels | Tee-Object -FilePath $env:RAPPORT | Out-Host"
set "SCHIJF_CODE=%errorlevel%"

echo.
echo Rapport: %RAPPORT%
echo Gebruik bij een waarschuwing ook de uitgebreide schijfcontrole.
pause
exit /b %SCHIJF_CODE%
