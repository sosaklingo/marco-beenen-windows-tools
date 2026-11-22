@echo off
setlocal EnableExtensions
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Beveiligingsstatus controleren - Marco Beenen

rem Alleen-lezen controle; administratorrechten geven toegang tot Secure Boot.
fltmc >nul 2>&1
if errorlevel 1 (
    echo De beveiligingscontrole wordt opnieuw gestart als administrator...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:WT_SELF -WorkingDirectory $env:WT_ROOT -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo Starten als administrator is geannuleerd of mislukt.
        pause
        exit /b 1
    )
    exit /b 0
)

cls
echo ================================================================
echo       TPM, SECURE BOOT EN BITLOCKER - MARCO BEENEN
echo ================================================================
echo.
echo Deze controle leest alleen de beveiligingsstatus.
echo Er wordt niets ingeschakeld, uitgeschakeld of gewijzigd.
echo.

for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "RAPPORTMAP=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%RAPPORTMAP%" mkdir "%RAPPORTMAP%"
for /f %%D in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "RAPPORT=%RAPPORTMAP%\Beveiligingsstatus_%DATUM%.txt"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$out=[System.Collections.Generic.List[string]]::new();" ^
  "function Add([string]$s=''){[void]$out.Add($s)};" ^
  "Add 'BEVEILIGINGSSTATUS - MARCO BEENEN'; Add ('Datum: '+(Get-Date)); Add '';" ^
  "Add 'TPM'; Add '---';" ^
  "try { $t=Get-Tpm; if($null -eq $t){ Add 'TPM-informatie kon niet worden gelezen.' } else { Add ('Aanwezig: '+$t.TpmPresent); Add ('Gereed: '+$t.TpmReady); Add ('Ingeschakeld: '+$t.TpmEnabled); Add ('Geactiveerd: '+$t.TpmActivated); Add ('Geblokkeerd: '+$t.LockedOut); Add ('Fabrikant: '+$t.ManufacturerIdTxt); Add ('Versie: '+$t.ManufacturerVersionFull20) } } catch { Add ('Niet beschikbaar: '+$_.Exception.Message) }; Add '';" ^
  "Add 'SECURE BOOT'; Add '-----------';" ^
  "try { $s=Confirm-SecureBootUEFI; Add ('Ingeschakeld: '+$s) } catch { Add ('Niet beschikbaar of niet ondersteund: '+$_.Exception.Message) }; Add '';" ^
  "Add 'BITLOCKER / APPARAATVERSLEUTELING'; Add '----------------------------------';" ^
  "try { $b=& ($env:SystemRoot+'\System32\manage-bde.exe') -status 2^>^&1 | Out-String -Width 240; Add $b.TrimEnd() } catch { Add ('Niet beschikbaar: '+$_.Exception.Message) };" ^
  "$out | Set-Content -LiteralPath $env:RAPPORT -Encoding utf8"
set "STATUS_CODE=%errorlevel%"

echo.
if "%STATUS_CODE%"=="0" (
    echo De beveiligingsstatus is opgeslagen.
    echo Rapport: %RAPPORT%
    start "" notepad.exe "%RAPPORT%"
) else (
    echo Het rapport kon niet volledig worden gemaakt. Foutcode: %STATUS_CODE%
)
echo.
pause
exit /b %STATUS_CODE%
