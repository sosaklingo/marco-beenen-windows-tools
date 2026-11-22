@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Veilige DiskPart-formatter - Disk 2 - Marco Beenen
set "WT_SELF=%~f0"
set "WT_ROOT=%~dp0"

rem ================================================================
rem  DOEL: fysieke Disk 2 volledig wissen en opnieuw partitioneren.
rem  LET OP: alle bestaande partities en bestanden op Disk 2 verdwijnen.
rem ================================================================
set "DP_TARGET_DISK=2"

rem Vraag automatisch administratorrechten.
fltmc >nul 2>&1
if errorlevel 1 (
    echo Administratorrechten zijn vereist. Bevestig het Windows UAC-venster.
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:WT_SELF -WorkingDirectory $env:WT_ROOT -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        echo Starten als administrator is mislukt of geannuleerd.
        pause
        exit /b 1
    )
    exit /b
)

setlocal EnableDelayedExpansion

echo.
echo ================================================================
echo   GEBRUIK DIT BESTAND NIET ZOMAAR.
echo   Alleen gebruiken als u ervaring hebt met DiskPart en precies weet
echo   welke fysieke schijf Windows als Disk %DP_TARGET_DISK% aanduidt.
echo   Disk %DP_TARGET_DISK% is NIET hetzelfde als stationsletter D:.
echo   ALLE partities en bestanden op Disk %DP_TARGET_DISK% worden verwijderd.
echo   Niet volledig zeker? Sluit dit venster en ga niet verder.
echo ================================================================
echo.

rem Controleer of de schijf bestaat.
powershell.exe -NoProfile -NonInteractive -Command "$d = Get-Disk -Number %DP_TARGET_DISK% -ErrorAction SilentlyContinue; if ($null -eq $d) { exit 1 }"
if errorlevel 1 (
    echo FOUT: fysieke Disk %DP_TARGET_DISK% is niet gevonden.
    goto :failure
)

rem Weiger de actieve Windows-/systeemschijf, ongeacht het schijfnummer.
powershell.exe -NoProfile -NonInteractive -Command "$d=Get-Disk -Number %DP_TARGET_DISK% -ErrorAction Stop; $letter=$env:SystemDrive.TrimEnd(':'); $windowsDisk=Get-Partition -DriveLetter $letter -ErrorAction SilentlyContinue ^| Get-Disk -ErrorAction SilentlyContinue; if ($d.IsBoot -or $d.IsSystem -or ($null -ne $windowsDisk -and $d.Number -eq $windowsDisk.Number)) { exit 10 }"
if errorlevel 10 (
    echo FOUT: Disk %DP_TARGET_DISK% is een opstart- of systeemschijf.
    echo Dit script weigert die schijf te wissen.
    goto :failure
)

rem Toon eerst de volledige DiskPart-identificatie en partities.
set "DP_INSPECT=%TEMP%\diskpart-inspect-%RANDOM%-%RANDOM%.txt"
(
    echo list disk
    echo select disk %DP_TARGET_DISK%
    echo detail disk
    echo list partition
) > "!DP_INSPECT!"

diskpart /s "!DP_INSPECT!"
del /q "!DP_INSPECT!" >nul 2>&1
echo.
echo Controleer hierboven vooral MODEL, CAPACITEIT en bestaande volumes.
echo.
choice /c JN /n /m "Is dit werkelijk de fysieke schijf die u wilt wissen? [J/N]: "
if errorlevel 2 goto :cancelled

rem Kies hoe de oude gegevens worden verwijderd.
echo.
echo Wis-methode:
echo   [1] CLEAN     - alleen partitietabel verwijderen ^(snel, aanbevolen^)
echo   [2] CLEAN ALL - hele schijf met nullen overschrijven ^(zeer langzaam^)
choice /c 12 /n /m "Kies 1 of 2: "
if errorlevel 2 (
    set "DP_CLEAN=clean all"
    set "DP_CLEAN_NAME=CLEAN ALL"
) else (
    set "DP_CLEAN=clean"
    set "DP_CLEAN_NAME=CLEAN"
)

rem Kies GPT of MBR.
echo.
echo Partitiestijl:
echo   [1] GPT - moderne standaard, aanbevolen
echo   [2] MBR - alleen voor oudere compatibiliteit
choice /c 12 /n /m "Kies 1 of 2: "
if errorlevel 2 (
    set "DP_STYLE=mbr"
    set "DP_STYLE_NAME=MBR"
) else (
    set "DP_STYLE=gpt"
    set "DP_STYLE_NAME=GPT"
)

rem Kies bestandssysteem. De ingebouwde Windows-formatteerder ondersteunt FAT32
rem voor deze volledige-schijfopzet alleen tot en met 32 GB.
:ask_filesystem
echo.
echo Bestandssysteem:
echo   [1] NTFS  - aanbevolen voor Windows
echo   [2] exFAT - geschikt voor Windows/macOS en externe schijven
echo   [3] FAT32 - oude compatibiliteit; alleen voor schijven t/m 32 GB
choice /c 123 /n /m "Kies 1, 2 of 3: "
if errorlevel 3 (
    set "DP_FS=fat32"
    set "DP_FS_NAME=FAT32"
    powershell.exe -NoProfile -NonInteractive -Command "$d=Get-Disk -Number %DP_TARGET_DISK% -ErrorAction Stop; if ($d.Size -le 32GB) { exit 0 } else { exit 1 }"
    if errorlevel 1 (
        echo.
        echo FAT32 is hier niet beschikbaar: Disk %DP_TARGET_DISK% is groter dan 32 GB.
        echo Kies NTFS of exFAT.
        goto :ask_filesystem
    )
) else if errorlevel 2 (
    set "DP_FS=exfat"
    set "DP_FS_NAME=exFAT"
) else (
    set "DP_FS=ntfs"
    set "DP_FS_NAME=NTFS"
)

rem Kies snel of volledig formatteren.
echo.
echo Format-modus:
echo   [1] QUICK - snel formatteren, aanbevolen na CLEAN
echo   [2] FULL  - sectorcontrole; kan uren duren
choice /c 12 /n /m "Kies 1 of 2: "
if errorlevel 2 (
    set "DP_FORMAT_MODE="
    set "DP_FORMAT_NAME=FULL"
) else (
    set "DP_FORMAT_MODE= quick"
    set "DP_FORMAT_NAME=QUICK"
)

rem Kies allocation-unit/clustergrootte.
echo.
echo Clustergrootte:
echo   [1] Standaard ^(aanbevolen^)
echo   [2] 4096 bytes
echo   [3] 8192 bytes
echo   [4] 16384 bytes
echo   [5] 32768 bytes
echo   [6] 65536 bytes
choice /c 123456 /n /m "Kies 1 t/m 6: "
if errorlevel 6 (
    set "DP_UNIT= unit=65536"
    set "DP_UNIT_NAME=65536 bytes"
) else if errorlevel 5 (
    set "DP_UNIT= unit=32768"
    set "DP_UNIT_NAME=32768 bytes"
) else if errorlevel 4 (
    set "DP_UNIT= unit=16384"
    set "DP_UNIT_NAME=16384 bytes"
) else if errorlevel 3 (
    set "DP_UNIT= unit=8192"
    set "DP_UNIT_NAME=8192 bytes"
) else if errorlevel 2 (
    set "DP_UNIT= unit=4096"
    set "DP_UNIT_NAME=4096 bytes"
) else (
    set "DP_UNIT="
    set "DP_UNIT_NAME=Standaard"
)

rem Volumenaam: valideer via een omgevingsvariabele, zodat invoer met speciale
rem cmd-tekens nooit als opdracht kan worden uitgevoerd.
:ask_label
echo.
set "DP_LABEL=DATA"
set /p "DP_LABEL=Volumenaam [DATA]: "
if not defined DP_LABEL set "DP_LABEL=DATA"
powershell.exe -NoProfile -NonInteractive -Command "if ($env:DP_LABEL -cmatch '^[A-Za-z0-9 _-]{1,32}$') { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Gebruik 1 t/m 32 letters, cijfers, spaties, koppeltekens of underscores.
    goto :ask_label
)

rem Kies stationsletter.
:ask_letter_mode
echo.
echo Stationsletter:
echo   [1] Automatisch de eerstvolgende vrije letter toewijzen
echo   [2] Zelf een vrije letter van D t/m Z kiezen
echo   [3] Geen stationsletter toewijzen
choice /c 123 /n /m "Kies 1, 2 of 3: "
if errorlevel 3 goto :no_drive_letter
if errorlevel 2 goto :ask_specific_letter

set "DP_ASSIGN=assign"
set "DP_ASSIGN_NAME=Automatisch"
goto :drive_letter_done

:ask_specific_letter
set "DP_LETTER="
set /p "DP_LETTER=Voer een letter van D t/m Z in: "
powershell.exe -NoProfile -NonInteractive -Command "if ($env:DP_LETTER -cmatch '^[D-Zd-z]$') { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo Ongeldige stationsletter.
    goto :ask_specific_letter
)
powershell.exe -NoProfile -NonInteractive -Command "if (Get-Volume -DriveLetter $env:DP_LETTER -ErrorAction SilentlyContinue) { exit 1 }"
if errorlevel 1 (
    echo Stationsletter !DP_LETTER!: is al in gebruik.
    goto :ask_specific_letter
)
set "DP_ASSIGN=assign letter=!DP_LETTER!"
set "DP_ASSIGN_NAME=!DP_LETTER!:"
goto :drive_letter_done

:no_drive_letter
set "DP_ASSIGN="
set "DP_ASSIGN_NAME=Geen"

:drive_letter_done

echo.
echo ================================================================
echo   LAATSTE CONTROLE - ALLE DATA OP DISK %DP_TARGET_DISK% GAAT VERLOREN
echo ================================================================
echo   Fysieke schijf : Disk %DP_TARGET_DISK%
echo   Wis-methode    : !DP_CLEAN_NAME!
echo   Partitiestijl  : !DP_STYLE_NAME!
echo   Bestandssysteem: !DP_FS_NAME!
echo   Formatteren    : !DP_FORMAT_NAME!
echo   Clustergrootte : !DP_UNIT_NAME!
echo   Volumenaam     : !DP_LABEL!
echo   Stationsletter : !DP_ASSIGN_NAME!
echo ================================================================
echo.
rem Laat PowerShell de bevestiging rechtstreeks lezen. De invoer wordt daardoor
rem nooit onderdeel van een cmd-opdrachtregel.
powershell.exe -NoProfile -Command "$answer=Read-Host 'Typ exact FORMATTEER DISK %DP_TARGET_DISK% om door te gaan'; if ($answer -ceq 'FORMATTEER DISK %DP_TARGET_DISK%') { exit 0 } else { exit 1 }"
if errorlevel 1 goto :cancelled

rem Controleer het doel nogmaals direct voor de onomkeerbare DiskPart-opdracht.
powershell.exe -NoProfile -NonInteractive -Command "$d=Get-Disk -Number %DP_TARGET_DISK% -ErrorAction SilentlyContinue; if ($null -eq $d) { exit 1 }; $letter=$env:SystemDrive.TrimEnd(':'); $windowsDisk=Get-Partition -DriveLetter $letter -ErrorAction SilentlyContinue ^| Get-Disk -ErrorAction SilentlyContinue; if ($d.IsBoot -or $d.IsSystem -or ($null -ne $windowsDisk -and $d.Number -eq $windowsDisk.Number)) { exit 10 }; exit 0"
if errorlevel 10 (
    echo.
    echo FOUT: Disk %DP_TARGET_DISK% is inmiddels een opstart-, systeem- of Windows-schijf.
    echo De bewerking is voor de veiligheid geannuleerd.
    goto :failure
)
if errorlevel 1 (
    echo.
    echo FOUT: fysieke Disk %DP_TARGET_DISK% is niet meer beschikbaar.
    goto :failure
)

rem Bouw pas na exacte bevestiging het DiskPart-script op.
set "DP_SCRIPT=%TEMP%\diskpart-format-%RANDOM%-%RANDOM%.txt"
(
    echo select disk %DP_TARGET_DISK%
    echo online disk noerr
    echo attributes disk clear readonly noerr
    echo !DP_CLEAN!
    echo convert !DP_STYLE!
    echo create partition primary
    echo format fs=!DP_FS! label="!DP_LABEL!"!DP_UNIT!!DP_FORMAT_MODE!
    if defined DP_ASSIGN echo !DP_ASSIGN!
    echo list volume
) > "!DP_SCRIPT!"

echo.
echo DiskPart wordt nu uitgevoerd. Onderbreek de computer niet.
echo CLEAN ALL en FULL kunnen zeer lang duren.
echo.
diskpart /s "!DP_SCRIPT!"
set "DP_RESULT=!ERRORLEVEL!"
del /q "!DP_SCRIPT!" >nul 2>&1

if not "!DP_RESULT!"=="0" (
    echo.
    echo DiskPart meldde een foutcode: !DP_RESULT!
    goto :failure
)

rem Controleer het werkelijke eindresultaat; vertrouw niet alleen op de
rem procescode van DiskPart.
powershell.exe -NoProfile -NonInteractive -Command "$d=Get-Disk -Number %DP_TARGET_DISK% -ErrorAction Stop; $p=Get-Partition -DiskNumber %DP_TARGET_DISK% -ErrorAction Stop ^| Where-Object Type -NotIn @('Reserved','System','Recovery') ^| Sort-Object Size -Descending ^| Select-Object -First 1; if ($null -eq $p) { throw 'Geen gegevenspartitie gevonden.' }; $v=$p ^| Get-Volume -ErrorAction Stop; if ($d.PartitionStyle.ToString() -ine $env:DP_STYLE) { throw ('Partitiestijl is ' + $d.PartitionStyle + ', verwacht ' + $env:DP_STYLE) }; if ($v.FileSystem -ine $env:DP_FS) { throw ('Bestandssysteem is ' + $v.FileSystem + ', verwacht ' + $env:DP_FS) }; if ($v.FileSystemLabel -cne $env:DP_LABEL) { throw ('Volumenaam is ' + $v.FileSystemLabel + ', verwacht ' + $env:DP_LABEL) }; Write-Host ('Gecontroleerd: ' + $d.PartitionStyle + ', ' + $v.FileSystem + ', volume ' + $v.FileSystemLabel) -ForegroundColor Green"
if errorlevel 1 (
    echo.
    echo De nacontrole kon het verwachte eindresultaat niet bevestigen.
    goto :failure
)

echo.
echo Gereed: Disk %DP_TARGET_DISK% is gewist, gepartitioneerd en geformatteerd.
pause
exit /b 0

:cancelled
echo.
echo Geannuleerd. Er is niets gewijzigd.
pause
exit /b 0

:failure
echo.
echo De bewerking is niet gestart of niet volledig voltooid.
echo Lees eventuele foutmeldingen hierboven voordat je opnieuw probeert.
pause
exit /b 1
