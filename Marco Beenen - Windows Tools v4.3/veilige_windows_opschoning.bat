@echo off
setlocal
title Veilige Windows-opschoning - Marco Beenen

cls
echo ================================================================
echo           VEILIGE WINDOWS-OPSCHONING - MARCO BEENEN
echo ================================================================
echo.
echo Deze tool verwijdert uitsluitend bestanden ouder dan 7 dagen uit uw
echo persoonlijke tijdelijke Windows-map.
echo.
echo Downloads, Documenten, Afbeeldingen, browsergegevens en de Prullenbak
echo worden niet verwijderd. Bestanden die in gebruik zijn worden overgeslagen.
echo.
choice /c JN /n /m "Tijdelijke bestanden nu opruimen? [J/N]: "
if errorlevel 2 exit /b 0

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$grens=(Get-Date).AddDays(-7);$bestanden=@(Get-ChildItem -LiteralPath $env:TEMP -File -Recurse -Force -ErrorAction SilentlyContinue | Where-Object LastWriteTime -lt $grens);$voor=($bestanden|Measure-Object Length -Sum).Sum;$verwijderd=0;$aantal=0;foreach($bestand in $bestanden){try{$lengte=$bestand.Length;Remove-Item -LiteralPath $bestand.FullName -Force -ErrorAction Stop;$verwijderd+=$lengte;$aantal++}catch{}};Write-Host ('{0} tijdelijke bestanden verwijderd; {1:N1} MB vrijgemaakt.' -f $aantal,($verwijderd/1MB)) -ForegroundColor Green;Write-Host ('Niet verwijderd of niet van toepassing: {0:N1} MB.' -f (($voor-$verwijderd)/1MB)) -ForegroundColor Gray"
set "CLEAN_CODE=%errorlevel%"

echo.
choice /c JN /n /m "Windows Opslaginstellingen openen voor verdere controle? [J/N]: "
if errorlevel 2 goto cleanup_done
start "" ms-settings:storagesense

:cleanup_done
echo.
echo Opschoning voltooid.
pause
exit /b %CLEAN_CODE%
