@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Apps automatisch updaten - Marco Beenen

cls
echo ================================================================
echo                    APPS AUTOMATISCH UPDATEN
echo                         Marco Beenen
echo ================================================================
echo.
echo Deze tool werkt aanwezige apps bij via Windows Package Manager
echo ^(winget^). Sluit programma's en bewaar open documenten vooraf.
echo.

where winget.exe >nul 2>nul
if not "%errorlevel%"=="0" goto winget_missing

rem 'where' kan een kapotte app-alias vinden. Test daarom winget zelf ook.
set "winget_test=%TEMP%\marco_winget_test_%RANDOM%.txt"
winget --version >"%winget_test%" 2>&1
set "winget_code=%errorlevel%"
if not "%winget_code%"=="0" (
    echo FOUT: Windows Package Manager kan niet worden gestart.
    echo Foutcode: %winget_code%
    echo.
    type "%winget_test%"
    del /q "%winget_test%" >nul 2>nul
    echo.
    echo Herstel of update "App Installer" via Microsoft Store en probeer opnieuw.
    echo Open eventueel: Instellingen ^> Apps ^> Apps en onderdelen ^> App Installer
    echo ^> Geavanceerde opties ^> Herstellen.
    echo.
    pause
    exit /b %winget_code%
)
del /q "%winget_test%" >nul 2>nul

echo Pakketbronnen bijwerken...
winget source update --disable-interactivity
set "source_code=%errorlevel%"
if not "%source_code%"=="0" (
    echo.
    echo WAARSCHUWING: de pakketbronnen konden niet worden bijgewerkt.
    echo Winget-foutcode: %source_code%
    echo De bestaande pakketlijst wordt gebruikt.
)

echo.
echo Beschikbare updates ophalen...
echo.
winget upgrade --include-unknown --accept-source-agreements
set "list_code=%errorlevel%"
if "%list_code%"=="-1978335173" (
    echo.
    echo De Microsoft Store-bron reageert tijdelijk niet.
    echo De lijst wordt opnieuw opgehaald via de gewone winget-bron...
    echo.
    winget upgrade --source winget --include-unknown --accept-source-agreements
    set "list_code=!errorlevel!"
)
if not "%list_code%"=="0" (
    echo.
    echo FOUT: de lijst met updates kon niet worden opgehaald.
    echo Winget-foutcode: %list_code%
    echo.
    pause
    exit /b %list_code%
)

rem Niet-interactieve modus voor de automatische praktijktest.
if /i "%~1"=="/PACKAGE" (
    set "update_exit=0"
    set "package_id=%~2"
    if not defined package_id (
        echo FOUT: na /PACKAGE ontbreekt de pakket-ID.
        exit /b 2
    )
    goto run_selected_update
)

echo.
echo ================================================================
echo Let op:
echo - Sommige apps beheren hun updates zelf en worden door winget overgeslagen.
echo - Battle.net werkt zichzelf bij en wordt niet geforceerd herinstalleerd.
echo - Vastgezette apps worden bewust niet automatisch bijgewerkt.
echo - Microsoft Store-apps zonder winget-koppeling blijven via de Store lopen.
echo ================================================================
echo.
echo [K] Zelf kiezen welke apps worden bijgewerkt
echo [A] Alle normale app-updates installeren
echo [N] Annuleren
echo.
choice /c KAN /n /m "Maak een keuze [K/A/N]: "
if errorlevel 3 (
    echo.
    echo App-updates geannuleerd.
    echo.
    pause
    exit /b 0
)
if errorlevel 2 goto install_all

set "update_exit=0"
goto choose_update

:choose_update
echo.
echo Typ de pakket-ID van de app die je wilt bijwerken.
echo Voorbeeld: Microsoft.PowerToys
echo Typ L om de lijst opnieuw te tonen, of druk op Enter om te stoppen.
echo.
set "package_id="
set /p "package_id=Pakket-ID: "

set "raw_package_id=!package_id!"
set "package_id="
for /f "tokens=* delims= " %%I in ("!raw_package_id!") do set "package_id=%%I"
if not defined package_id (
    echo Geen pakket-ID ingevoerd; terug naar het hoofdmenu.
    goto updates_done
)
if /i "!package_id!"=="L" (
    echo.
    winget upgrade --include-unknown --accept-source-agreements
    goto choose_update
)

:run_selected_update
set "WT_PACKAGE_ID=!package_id!"
powershell.exe -NoProfile -NonInteractive -Command "if ($env:WT_PACKAGE_ID -cmatch '^[A-Za-z0-9._+-]+$') { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo.
    echo Ongeldige pakket-ID. Gebruik alleen letters, cijfers, punten,
    echo underscores, plustekens of koppeltekens.
    if /i "%~1"=="/PACKAGE" exit /b 2
    goto choose_update
)
echo.
echo Update starten voor: !package_id!
echo.
if /i "!package_id!"=="Blizzard.BattleNet" goto battlenet_self_update

winget upgrade --id "!package_id!" --exact --include-unknown --accept-package-agreements --accept-source-agreements
set "single_code=%errorlevel%"
if "%single_code%"=="-1978335173" (
    echo.
    echo De Microsoft Store-bron reageert niet. Opnieuw proberen via winget...
    winget upgrade --id "!package_id!" --exact --source winget --include-unknown --accept-package-agreements --accept-source-agreements
    set "single_code=!errorlevel!"
)
goto single_update_result

:battlenet_self_update
echo Battle.net registreert geen versienummer en zou door winget telkens
echo opnieuw worden geplaatst. Battle.net gebruikt daarom zijn eigen updater.
echo Start Battle.net zelf om die update te laten controleren.
set "single_code=0"

:single_update_result
if not "%single_code%"=="0" (
    set "update_exit=1"
    echo.
    echo Deze update is niet voltooid. Winget-foutcode: %single_code%
)

if /i "%~1"=="/PACKAGE" goto updates_done

echo.
choice /c JN /n /m "Nog een app kiezen? [J/N]: "
if errorlevel 2 goto updates_done
goto choose_update

:install_all
set "update_exit=0"

echo.
echo Bekende app-updates worden gestart...
echo.
rem Werk eerst de gewone winget-bron bij. Een tijdelijke Store-storing kan deze
rem ronde daardoor niet meer blokkeren.
winget upgrade --all --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
set "known_code=%errorlevel%"
if not "%known_code%"=="0" set "update_exit=1"

echo.
echo Microsoft Store-updates controleren...
winget upgrade --all --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity
set "store_code=%errorlevel%"
if not "%store_code%"=="0" (
    echo Microsoft Store-updates zijn nu niet voltooid. Winget-foutcode: %store_code%
    echo De updates uit de gewone winget-bron zijn wel afzonderlijk uitgevoerd.
    set "update_exit=1"
)

echo.
echo Battle.net wordt niet geforceerd herinstalleerd; de ingebouwde updater
echo van Battle.net verzorgt deze app afzonderlijk.

rem Discord staat in winget als 'expliciet bijwerken' en valt buiten --all.
if exist "%LOCALAPPDATA%\Discord\Update.exe" call :update_discord_auto

goto updates_done

:update_discord_auto
echo.
echo Discord afzonderlijk en expliciet bijwerken...
winget upgrade --id Discord.Discord --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
set "discord_code=%errorlevel%"
if not "%discord_code%"=="0" (
    set "update_exit=1"
    echo Discord is niet bijgewerkt. Winget-foutcode: %discord_code%
)
exit /b 0

:updates_done
echo.
echo ================================================================
if "%update_exit%"=="0" (
    echo Klaar. De gekozen app-updates zijn uitgevoerd.
) else (
    echo Klaar met meldingen. Minstens een app kon niet worden bijgewerkt.
    echo De winget-foutcode staat bij de betreffende update hierboven.
)
echo ================================================================
echo.
pause
exit /b %update_exit%

:winget_missing
echo FOUT: winget is niet gevonden op deze computer.
echo.
echo Installeer of herstel "App Installer" via de Microsoft Store en
echo probeer daarna opnieuw.
echo.
pause
exit /b 1
