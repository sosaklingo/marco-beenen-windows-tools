@echo off
setlocal
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Systeeminformatie opslaan - Marco Beenen

powershell.exe -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Systeeminformatie wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath $env:WT_SELF -Verb RunAs"
    exit /b
)

cls
echo ================================================================
echo           SYSTEEMINFORMATIE OPSLAAN - MARCO BEENEN
echo ================================================================
echo.
echo Hardware-, Windows-, BIOS-, netwerk- en drivergegevens worden verzameld.
echo Er worden geen instellingen gewijzigd.
echo.

for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "RAPPORTMAP=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%RAPPORTMAP%" mkdir "%RAPPORTMAP%"
for /f %%D in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "RAPPORT=%RAPPORTMAP%\Systeeminformatie_%DATUM%.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$o=Get-CimInstance Win32_OperatingSystem;$c=Get-CimInstance Win32_ComputerSystem;$b=Get-CimInstance Win32_BIOS;$cpu=Get-CimInstance Win32_Processor;$gpu=Get-CimInstance Win32_VideoController;" ^
  "'SYSTEEMINFORMATIE - MARCO BEENEN',('Datum: '+(Get-Date)),'','COMPUTER',('Fabrikant/model: {0} {1}' -f $c.Manufacturer,$c.Model),('Windows: {0}' -f $o.Caption),('Versie/build: {0} / {1}' -f $o.Version,$o.BuildNumber),('BIOS: {0} - {1}' -f $b.Manufacturer,$b.SMBIOSBIOSVersion),('Processor: {0}' -f (($cpu|Select-Object -First 1).Name)),('Geheugen: {0:N1} GB' -f ($c.TotalPhysicalMemory/1GB)),'','VIDEOKAART' | Out-File -LiteralPath $env:RAPPORT -Encoding utf8;" ^
  "$gpu | Select-Object Name,DriverVersion,AdapterRAM | Format-List | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;" ^
  "'SCHIJVEN' | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;Get-Disk | Select-Object Number,FriendlyName,BusType,PartitionStyle,@{N='GrootteGB';E={[math]::Round($_.Size/1GB,1)}},OperationalStatus | Format-Table -AutoSize | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;" ^
  "'NETWERK' | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;Get-NetAdapter | Select-Object Name,InterfaceDescription,Status,LinkSpeed,MacAddress | Format-Table -AutoSize | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;" ^
  "'DRIVERS' | Out-File -LiteralPath $env:RAPPORT -Append -Encoding utf8;Get-CimInstance Win32_PnPSignedDriver | Sort-Object DeviceName | Select-Object DeviceName,Manufacturer,DriverVersion,DriverDate | Format-Table -AutoSize | Out-File -LiteralPath $env:RAPPORT -Append -Width 240 -Encoding utf8"
set "INFO_CODE=%errorlevel%"

echo.
if "%INFO_CODE%"=="0" (echo Systeeminformatie is opgeslagen.) else (echo Niet alle informatie kon worden gelezen.)
echo Rapport: %RAPPORT%
pause
exit /b %INFO_CODE%
