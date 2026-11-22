@echo off
setlocal EnableExtensions
title Windows Tools v4.3 - Gemaakt door Marco Beenen

:menu
cls
echo ================================================================
echo                      MARCO BEENEN - WINDOWS TOOLS
echo             Compleet test-, diagnose- en onderhoudspakket v4.3
echo ================================================================
echo.
echo   [1] Diagnose en tests
echo   [2] Onderhoud en beveiliging
echo   [3] Windows-hulpmiddelen en apparaten
echo   [4] Rapporten en informatie
echo   [5] Overig en energie
echo   [6] Geavanceerd - gegevensverlies mogelijk
echo   [0] Afsluiten
echo.
choice /c 1234560 /n /m "Kies een onderdeel [1-6/0]: "
if errorlevel 7 exit /b 0
if errorlevel 6 goto menu_advanced
if errorlevel 5 goto menu_other
if errorlevel 4 goto rpt
if errorlevel 3 goto menu_windows
if errorlevel 2 goto menu_maintenance
goto menu_diagnostics

:menu_diagnostics
cls
echo ================================================================
echo                        DIAGNOSE EN TESTS
echo ================================================================
echo.
echo   [1] Volledige computerdiagnose
echo   [2] Snelle hardwarecontrole
echo   [3] Uitgebreide schijfcontrole
echo   [4] Schijfgezondheid snel controleren
echo   [5] Volledige geheugentest openen
echo   [6] Netwerkstabiliteitstest
echo   [7] Wifi-rapport maken
echo   [8] Laptopaccu en energie controleren
echo   [9] Temperatuur- en stresstesthandleiding
echo   [A] Handmatige hardwarechecklist
echo   [B] Opstartprogramma's controleren
echo   [C] Windows-prestatierapport
echo   [D] RDP Wrapper-diagnose ^(alleen lezen^)
echo   [0] Terug naar hoofdmenu
echo.
choice /c 123456789ABCD0 /n /m "Maak een keuze [1-9/A-D/0]: "
if errorlevel 14 goto menu
if errorlevel 13 (
    call "%~dp0START_RDP_CONTROLE.cmd"
    goto menu_diagnostics
)
if errorlevel 12 (
    call "%~dp0windows_prestatierapport_openen.bat"
    goto menu_diagnostics
)
if errorlevel 11 (
    call "%~dp0opstartprogrammas_controle.bat"
    goto menu_diagnostics
)
if errorlevel 10 (
    call "%~dp0handmatige_hardware_checklist.bat"
    goto menu_diagnostics
)
if errorlevel 9 (
    call "%~dp0temperatuur_en_stresstest_handleiding.bat"
    goto menu_diagnostics
)
if errorlevel 8 (
    call "%~dp0laptop_accu_en_energiecontrole.bat"
    goto menu_diagnostics
)
if errorlevel 7 (
    call "%~dp0wifi_rapport_maken.bat"
    goto menu_diagnostics
)
if errorlevel 6 (
    call "%~dp0netwerk_stabiliteitstest.bat"
    goto menu_diagnostics
)
if errorlevel 5 (
    call "%~dp0volledige_geheugentest_openen.bat"
    goto menu_diagnostics
)
if errorlevel 4 (
    call "%~dp0schijfgezondheid_controleren.bat"
    goto menu_diagnostics
)
if errorlevel 3 (
    call "%~dp0uitgebreide_schijfcontrole.bat"
    goto menu_diagnostics
)
if errorlevel 2 (
    call "%~dp0test_cpu_gpu_geheugen_schijf.bat"
    goto menu_diagnostics
)
call "%~dp0Volledige Computerdiagnose - Marco Beenen.bat"
goto menu_diagnostics

:menu_maintenance
cls
echo ================================================================
echo                   ONDERHOUD EN BEVEILIGING
echo ================================================================
echo.
echo   [1] Apps automatisch updaten
echo   [2] Windows repareren met DISM en SFC
echo   [3] Microsoft Defender-scan
echo   [4] Windows-herstelpunten en back-up
echo   [5] Veilige Windows-opschoning
echo   [6] Windows Update inschakelen
echo   [7] Windows Update uitschakelen
echo   [8] TPM, Secure Boot en BitLocker controleren
echo   [9] Back-up van externe drivers maken
echo   [0] Terug naar hoofdmenu
echo.
choice /c 1234567890 /n /m "Maak een keuze [1-9/0]: "
if errorlevel 10 goto menu
if errorlevel 9 (
    call "%~dp0drivers_backup_maken.bat"
    goto menu_maintenance
)
if errorlevel 8 (
    call "%~dp0beveiligingsstatus_controleren.bat"
    goto menu_maintenance
)
if errorlevel 7 (
    call "%~dp0Windows_Updates_UIT.bat"
    goto menu_maintenance
)
if errorlevel 6 (
    call "%~dp0Windows_Updates_AAN.bat"
    goto menu_maintenance
)
if errorlevel 5 (
    call "%~dp0veilige_windows_opschoning.bat"
    goto menu_maintenance
)
if errorlevel 4 goto herstel
if errorlevel 3 (
    call "%~dp0windows_defender_scan.bat"
    goto menu_maintenance
)
if errorlevel 2 (
    call "%~dp0windows_repareren.bat"
    goto menu_maintenance
)
call "%~dp0apps_automatisch_updaten.bat"
goto menu_maintenance

:herstel
title Windows-herstel - Marco Beenen
cls
echo ================================================================
echo                         WINDOWS-HERSTEL
echo ================================================================
echo.
echo   [1] Windows-herstelpunt maken
echo   [2] Windows-herstelpunt openen
echo   [3] Herstelpuntenoverzicht opslaan
echo   [4] Windows Back-up openen
echo   [0] Terug naar Onderhoud en beveiliging
echo.
echo Via Systeembeveiliging kunt u herstelpunten beheren en
echo met de knop Systeemherstel een bestaand herstelpunt kiezen.
echo.
choice /c 12340 /n /m "Maak een keuze [1-4/0]: "
if errorlevel 5 goto menu_maintenance
if errorlevel 4 (
    call "%~dp0open_windows_backup.bat"
    goto herstel
)
if errorlevel 3 (
    call "%~dp0herstelpunten_overzicht_opslaan.bat"
    goto herstel
)
if errorlevel 2 (
    call "%~dp0open_systeembeveiliging.bat"
    goto herstel
)
call "%~dp0herstelpunt_maken.bat"
goto herstel

:menu_windows
cls
echo ================================================================
echo              WINDOWS-HULPMIDDELEN EN APPARATEN
echo ================================================================
echo.
echo   [1] Betrouwbaarheidsgeschiedenis
echo   [2] Windows-logboeken
echo   [3] Broncontrole
echo   [4] Computerbeheer
echo   [5] Systeembeheer
echo   [6] Lokaal beveiligingsbeleid
echo   [7] Opdrachtprompt als administrator
echo   [8] Herstelstation maken
echo   [9] Klassiek geluidsmenu - tabblad Afspelen
echo   [A] Apparaatbeheer direct openen
echo   [B] Windows Update openen
echo   [C] Opstart-apps openen
echo   [D] Windows-probleemoplossers openen
echo   [E] Taakbeheer openen
echo   [F] Windows-beveiliging openen
echo   [G] Netwerkverbindingen openen
echo   [0] Terug naar hoofdmenu
echo.
choice /c 123456789ABCDEFG0 /n /m "Maak een keuze [1-9/A-G/0]: "
if errorlevel 17 goto menu
if errorlevel 16 (
    call "%~dp0open_netwerkverbindingen.bat"
    goto menu_windows
)
if errorlevel 15 (
    call "%~dp0open_windows_beveiliging.bat"
    goto menu_windows
)
if errorlevel 14 (
    call "%~dp0open_taakbeheer.bat"
    goto menu_windows
)
if errorlevel 13 (
    call "%~dp0open_probleemoplossers.bat"
    goto menu_windows
)
if errorlevel 12 (
    call "%~dp0open_opstartapps.bat"
    goto menu_windows
)
if errorlevel 11 (
    call "%~dp0open_windows_update.bat"
    goto menu_windows
)
if errorlevel 10 (
    call "%~dp0open_apparaatbeheer.bat"
    goto menu_windows
)
if errorlevel 9 (
    call "%~dp0open_geluidsapparaten.bat"
    goto menu_windows
)
if errorlevel 8 (
    call "%~dp0open_recovery_drive.bat"
    goto menu_windows
)
if errorlevel 7 (
    call "%~dp0open_command_prompt_admin.bat"
    goto menu_windows
)
if errorlevel 6 (
    call "%~dp0open_local_security_policy.bat"
    goto menu_windows
)
if errorlevel 5 (
    call "%~dp0open_systeembeheer.bat"
    goto menu_windows
)
if errorlevel 4 (
    call "%~dp0open_computer_management.bat"
    goto menu_windows
)
if errorlevel 3 (
    call "%~dp0open_resource_monitor.bat"
    goto menu_windows
)
if errorlevel 2 (
    call "%~dp0open_logboeken.bat"
    goto menu_windows
)
call "%~dp0open_betrouwbaarheidsgeschiedenis.bat"
goto menu_windows

:rpt
cls
echo ================================================================
echo                    RAPPORTEN EN INFORMATIE
echo ================================================================
echo.
echo   [1] Centrale rapportenmap openen
echo   [2] PDF-handleiding openen
echo   [3] Systeeminformatie opslaan
echo   [4] Crash- en blauwschermrapport maken
echo   [5] Windows Tools zelftest uitvoeren
echo   [0] Terug naar hoofdmenu
echo.
choice /c 123450 /n /m "Maak een keuze [1-5/0]: "
if errorlevel 6 goto menu
if errorlevel 5 (
    call "%~dp0pakket_zelftest.bat"
    goto rpt
)
if errorlevel 4 (
    call "%~dp0crash_en_blauwschermrapport_maken.bat"
    goto rpt
)
if errorlevel 3 (
    call "%~dp0systeeminformatie_opslaan.bat"
    goto rpt
)
if errorlevel 2 (
    start "" "%~dp0Handleiding computer testen - Marco Beenen.pdf"
    goto rpt
)
call "%~dp0open_rapportenmap.bat"
goto rpt

:menu_other
cls
echo ================================================================
echo                       OVERIG EN ENERGIE
echo ================================================================
echo.
echo   [1] Computer uitschakelen na 10 minuten
echo   [2] Zelf instellen na hoeveel minuten uitschakelen
echo   [3] Geplande uitschakeling annuleren
echo   [0] Terug naar hoofdmenu
echo.
choice /c 1230 /n /m "Maak een keuze [1/2/3/0]: "
if errorlevel 4 goto menu
if errorlevel 3 (
    call "%~dp0annuleer_uitschakelen.bat"
    goto menu_other
)
if errorlevel 2 (
    call "%~dp0uitschakelen_na_eigen_aantal_minuten.bat"
    goto menu_other
)
call "%~dp0uitschakelen_na_10_minuten.bat"
goto menu_other

:menu_advanced
cls
echo ================================================================
echo                  GEAVANCEERD - EXTRA VOORZICHTIG
echo ================================================================
echo.
echo   [1] Fysieke Disk 2 formatteren ^(WIST ALLE DATA^)
echo   [0] Terug naar hoofdmenu
echo.
choice /c 10 /n /m "Maak een keuze [1/0]: "
if errorlevel 2 goto menu

echo.
echo ================================================================
echo GEBRUIK format-disk-2.bat NIET ZOMAAR.
echo Alleen gebruiken als u ervaring hebt met DiskPart en precies weet
echo welke fysieke schijf Windows als Disk 2 aanduidt.
echo Disk 2 is NIET hetzelfde als stationsletter D:.
echo ALLE partities en bestanden op Disk 2 worden verwijderd.
echo Niet volledig zeker? Kies N en ga niet verder.
echo ================================================================
echo.
choice /c JN /n /m "Begrijpt u dit en wilt u de veiligheidscontrole openen? [J/N]: "
if errorlevel 2 goto menu_advanced
call "%~dp0format-disk-2.bat"
goto menu_advanced
