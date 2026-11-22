@echo off
setlocal EnableExtensions
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"
title Crash- en blauwschermrapport maken - Marco Beenen

rem Alleen-lezen inventarisatie; beheerrechten geven toegang tot systeemlogs.
fltmc >nul 2>&1
if errorlevel 1 (
    echo Het crashrapport wordt opnieuw gestart als administrator...
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
echo       CRASH- EN BLAUWSCHERMRAPPORT - MARCO BEENEN
echo ================================================================
echo.
echo Recente crashmeldingen, onverwachte herstarts en aanwezige dumpbestanden
echo worden geinventariseerd. Dumpbestanden worden niet geopend of gekopieerd.
echo Er worden geen Windows-instellingen gewijzigd.
echo.

for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "BUREAUBLAD=%%D"
set "RAPPORTMAP=%BUREAUBLAD%\Computerdiagnose rapporten"
if not exist "%RAPPORTMAP%" mkdir "%RAPPORTMAP%"
for /f %%D in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "DATUM=%%D"
set "RAPPORT=%RAPPORTMAP%\Crash_en_blauwscherm_%DATUM%.txt"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Continue'; $start=(Get-Date).AddDays(-30);" ^
  "$out=[System.Collections.Generic.List[string]]::new(); function Add([string]$s=''){[void]$out.Add($s)};" ^
  "Add 'CRASH- EN BLAUWSCHERMRAPPORT - MARCO BEENEN'; Add ('Datum: '+(Get-Date)); Add 'Periode: laatste 30 dagen'; Add '';" ^
  "Add 'AANWEZIGE DUMPBESTANDEN'; Add '-----------------------';" ^
  "$paths=@(($env:SystemRoot+'\Minidump\*.dmp'),($env:SystemRoot+'\MEMORY.DMP'),($env:LOCALAPPDATA+'\CrashDumps\*.dmp')); $dumps=@(Get-ChildItem -Path $paths -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending); if($dumps.Count){ Add (($dumps | Select-Object FullName,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 240).TrimEnd()) } else { Add 'Geen dumpbestanden gevonden.' }; Add '';" ^
  "Add 'SYSTEEM: CRASHES EN ONVERWACHTE HERSTARTS'; Add '----------------------------------------';" ^
  "try { $e=@(Get-WinEvent -FilterHashtable @{LogName='System';StartTime=$start;Id=41,1001,6008} -ErrorAction Stop | Select-Object -First 100); if($e.Count){ Add (($e | Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message | Format-List | Out-String -Width 240).TrimEnd()) } else { Add 'Geen passende systeemmeldingen gevonden.' } } catch { Add ('Kon systeemlog niet lezen: '+$_.Exception.Message) }; Add '';" ^
  "Add 'TOEPASSINGEN: FOUTEN EN VASTLOPERS'; Add '----------------------------------';" ^
  "try { $a=@(Get-WinEvent -FilterHashtable @{LogName='Application';StartTime=$start;Id=1000,1001,1002} -ErrorAction Stop | Select-Object -First 100); if($a.Count){ Add (($a | Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message | Format-List | Out-String -Width 240).TrimEnd()) } else { Add 'Geen passende toepassingsmeldingen gevonden.' } } catch { Add ('Kon toepassingslog niet lezen: '+$_.Exception.Message) };" ^
  "$out | Set-Content -LiteralPath $env:RAPPORT -Encoding utf8"
set "CRASH_CODE=%errorlevel%"

echo.
if "%CRASH_CODE%"=="0" (
    echo Crash- en blauwschermrapport opgeslagen.
    echo Rapport: %RAPPORT%
    start "" notepad.exe "%RAPPORT%"
) else (
    echo Het rapport kon niet worden gemaakt. Foutcode: %CRASH_CODE%
)
echo.
pause
exit /b %CRASH_CODE%
