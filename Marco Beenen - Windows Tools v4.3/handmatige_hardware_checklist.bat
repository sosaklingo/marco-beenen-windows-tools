@echo off
setlocal
title Handmatige hardwarechecklist - Gemaakt door Marco Beenen

set "WT_SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:WT_SELF -Raw; $marker = ':' + 'POWERSHELL_PAYLOAD'; $start = $raw.LastIndexOf($marker); if ($start -lt 0) { throw 'Testcode niet gevonden.' }; Invoke-Expression ($raw.Substring($start + $marker.Length))"
set "TOOL_CODE=%errorlevel%"

echo.
pause
exit /b %TOOL_CODE%
:POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$reports = Join-Path $desktop 'Computerdiagnose rapporten'
New-Item -ItemType Directory -Path $reports -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$reportPath = Join-Path $reports ("Handmatige_hardwarechecklist_{0}.txt" -f $stamp)

$tests = @(
    [PSCustomObject]@{ Name = 'Beeldscherm'; Instruction = 'Controleer op flikkeren, strepen, verkeerde kleuren en dode pixels.' },
    [PSCustomObject]@{ Name = 'Speakers en hoofdtelefoon'; Instruction = 'Speel geluid links en rechts af en luister naar kraak of vervorming.' },
    [PSCustomObject]@{ Name = 'Microfoon'; Instruction = 'Maak een korte opname en luister deze terug.' },
    [PSCustomObject]@{ Name = 'Camera'; Instruction = 'Open de Camera-app en controleer beeld, scherpstelling en lampje.' },
    [PSCustomObject]@{ Name = 'Toetsenbord'; Instruction = 'Test letters, cijfers, functietoetsen, Shift, Ctrl, Alt en pijltjestoetsen.' },
    [PSCustomObject]@{ Name = 'Muis of touchpad'; Instruction = 'Test bewegen, links/rechts klikken, scrollen en slepen.' },
    [PSCustomObject]@{ Name = 'USB-poorten'; Instruction = 'Test dezelfde betrouwbare USB-stick in iedere USB-poort.' },
    [PSCustomObject]@{ Name = 'Wifi'; Instruction = 'Test internet dichtbij en verder van de router.' },
    [PSCustomObject]@{ Name = 'Bluetooth'; Instruction = 'Koppel een bekend apparaat en controleer of de verbinding stabiel blijft.' },
    [PSCustomObject]@{ Name = 'Ventilatoren en geluid'; Instruction = 'Luister naar tikken, schuren, ratelen of plotseling extreem lawaai.' }
)

$results = @()
Clear-Host
Write-Host 'HANDMATIGE HARDWARECHECKLIST' -ForegroundColor Cyan
Write-Host 'Gemaakt door Marco Beenen - Windows Tools v4.3' -ForegroundColor Gray
Write-Host 'Voer iedere controle uit en kies G, P of O.' -ForegroundColor Gray

for ($index = 0; $index -lt $tests.Count; $index++) {
    $test = $tests[$index]
    Write-Host ''
    Write-Host ("[{0}/{1}] {2}" -f ($index + 1), $tests.Count, $test.Name) -ForegroundColor White
    Write-Host $test.Instruction
    do {
        $answer = (Read-Host 'Uitslag: G=goed, P=probleem, O=overgeslagen').Trim().ToUpperInvariant()
    } while ($answer -notin @('G', 'P', 'O'))

    $status = switch ($answer) { 'G' { 'GOED' } 'P' { 'PROBLEEM' } default { 'OVERGESLAGEN' } }
    $note = ''
    if ($status -eq 'PROBLEEM') { $note = Read-Host 'Korte omschrijving van het probleem' }
    $results += [PSCustomObject]@{ Onderdeel = $test.Name; Uitslag = $status; Opmerking = $note }
}

$problemCount = @($results | Where-Object Uitslag -eq 'PROBLEEM').Count
$skipCount = @($results | Where-Object Uitslag -eq 'OVERGESLAGEN').Count
$lines = @(
    'HANDMATIGE HARDWARECHECKLIST',
    'Gemaakt door Marco Beenen - Windows Tools v4.3',
    ("Datum/tijd: {0}" -f (Get-Date)),
    ''
)
foreach ($result in $results) {
    $detail = if ($result.Opmerking) { " - $($result.Opmerking)" } else { '' }
    $lines += ("{0,-28} {1}{2}" -f $result.Onderdeel, $result.Uitslag, $detail)
}
$lines += ''
$lines += ("Problemen: {0}" -f $problemCount)
$lines += ("Overgeslagen: {0}" -f $skipCount)
if ($problemCount -gt 0) {
    $lines += 'Advies: onderzoek de onderdelen met PROBLEEM afzonderlijk en bewaar dit rapport.'
}
else {
    $lines += 'Uitslag: bij de uitgevoerde handmatige controles zijn geen problemen gemeld.'
}
$lines += ("Rapport: {0}" -f $reportPath)
$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Clear-Host
$lines | ForEach-Object { Write-Host $_ }
Start-Process notepad.exe $reportPath
