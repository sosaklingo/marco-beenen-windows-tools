@echo off
setlocal EnableExtensions
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Windows-herstelpunt maken - Marco Beenen

rem Controleer beheerdersrechten zonder afhankelijk te zijn van de Server-service.
powershell -NoProfile -Command "if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if not "%errorlevel%"=="0" (
    echo Herstelpunt maken wordt opnieuw gestart als administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:WT_SELF -WorkingDirectory $env:WT_ROOT -Verb RunAs -ErrorAction Stop } catch { Write-Host ('Starten als administrator is mislukt: ' + $_.Exception.Message) -ForegroundColor Red; exit 1 }"
    if not "%errorlevel%"=="0" (
        echo.
        echo Bevestig de Windows-beveiligingsvraag om een herstelpunt te maken.
        pause
        exit /b 1
    )
    exit /b 0
)

cls
echo ================================================================
echo          WINDOWS-HERSTELPUNT MAKEN - MARCO BEENEN
echo ================================================================
echo.
echo Er wordt een nieuw herstelpunt gemaakt met de naam:
echo Marco Beenen - Windows Tools
echo.
echo Systeembeveiliging voor de Windows-schijf wordt zo nodig ingeschakeld.
echo De normale limiet van een herstelpunt per 24 uur wordt alleen tijdens
echo deze actie tijdelijk uitgeschakeld en daarna volledig teruggezet.
echo.
choice /c JN /n /m "Herstelpunt nu maken? [J/N]: "
if errorlevel 2 exit /b 0

echo.
echo Systeembeveiliging controleren en herstelpunt maken...
echo Dit kan enkele minuten duren.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$drive=$env:SystemDrive + '\';" ^
  "$reg='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore';" ^
  "$prop='SystemRestorePointCreationFrequency';" ^
  "$hadOld=$false; $oldValue=$null;" ^
  "try { $old=Get-ItemProperty -LiteralPath $reg -Name $prop -ErrorAction Stop; $oldValue=$old.$prop; $hadOld=$true } catch { }" ^
  "try {" ^
  "  Enable-ComputerRestore -Drive $drive -ErrorAction Stop;" ^
  "  New-Item -Path $reg -Force | Out-Null;" ^
  "  Set-ItemProperty -LiteralPath $reg -Name $prop -Type DWord -Value 0 -Force;" ^
  "  $before=@(Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Sort-Object SequenceNumber -Descending);" ^
  "  Checkpoint-Computer -Description 'Marco Beenen - Windows Tools' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop;" ^
  "  Start-Sleep -Seconds 2;" ^
  "  $after=Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object SequenceNumber -Descending | Select-Object -First 1;" ^
  "  if ($null -eq $after) { throw 'Windows heeft na de opdracht geen herstelpunt gerapporteerd.' }" ^
  "  if ($before.Count -gt 0 -and $after.SequenceNumber -eq $before[0].SequenceNumber) { throw 'Windows heeft geen nieuw herstelpunt toegevoegd.' }" ^
  "  Write-Host ('Herstelpunt gemaakt. Nummer: {0}' -f $after.SequenceNumber) -ForegroundColor Green;" ^
  "  Write-Host ('Naam: {0}' -f $after.Description) -ForegroundColor Green;" ^
  "} catch {" ^
  "  Write-Host ('FOUT: ' + $_.Exception.Message) -ForegroundColor Red;" ^
  "  Write-Host 'Open Systeembeveiliging met: SystemPropertiesProtection.exe' -ForegroundColor Yellow;" ^
  "  exit 1;" ^
  "} finally {" ^
  "  if ($hadOld) { Set-ItemProperty -LiteralPath $reg -Name $prop -Type DWord -Value $oldValue -Force -ErrorAction SilentlyContinue } else { Remove-ItemProperty -LiteralPath $reg -Name $prop -ErrorAction SilentlyContinue }" ^
  "}"
set "PUNT_CODE=%errorlevel%"

echo.
if not "%PUNT_CODE%"=="0" (
    echo Het herstelpunt kon niet worden gemaakt. Foutcode: %PUNT_CODE%
    echo Controleer vrije schijfruimte en Systeembeveiliging voor de Windows-schijf.
) else (
    echo Het nieuwe herstelpunt is gecontroleerd en staat in de Windows-lijst.
)
echo.
pause
exit /b %PUNT_CODE%
