# Marco Beenen - Windows Tools

Een compleet Nederlandstalig diagnose-, onderhouds- en hulppakket voor Windows, gemaakt door **Marco Beenen**.

De tools zijn samengebracht in één overzichtelijk menu. Het pakket bevat controles voor hardware, opslag, netwerk, Windows, beveiliging, energie, rapportage en een alleen-lezen RDP Wrapper-diagnose.

## Download

De nieuwste versie is **Windows Tools v4.3**.

**[Windows Tools v4.3 als ZIP downloaden](https://raw.githubusercontent.com/sosaklingo/marco-beenen-windows-tools/main/Marco%20Beenen%20-%20Windows%20Tools%20v4.3.zip)**

Download bij voorkeur het ZIP-bestand, pak het volledig uit en start daarna:

```text
START - Windows Tools.bat
```

Voer bestanden niet rechtstreeks vanuit de ZIP uit. Verschillende onderdelen gebruiken andere bestanden uit dezelfde pakketmap.

## Snel beginnen

1. Download het ZIP-bestand.
2. Pak de volledige ZIP uit naar een gewone map op de computer of USB-stick.
3. Open eerst de TXT- of PDF-handleiding.
4. Dubbelklik op `START - Windows Tools.bat`.
5. Kies het gewenste onderdeel in het hoofdmenu.
6. Bewaar gemaakte rapporten voordat u instellingen wijzigt of reparaties uitvoert.

Sommige onderdelen vragen om administratorrechten. Bevestig dit alleen wanneer u de gekozen functie begrijpt en bewust wilt uitvoeren.

## Hoofdmenu

| Onderdeel | Voorbeelden |
|---|---|
| Diagnose en tests | Computerdiagnose, hardwarecontrole, schijfcontrole, geheugentest, netwerkstabiliteit, wifi-rapport en RDP-diagnose |
| Onderhoud en beveiliging | Apps bijwerken, DISM/SFC, Microsoft Defender, herstelpunten, veilige opschoning, Windows Update en driverback-up |
| Windows-hulpmiddelen en apparaten | Logboeken, Broncontrole, Computerbeheer, Apparaatbeheer, Taakbeheer, geluidsmenu en netwerkverbindingen |
| Rapporten en informatie | Centrale rapportenmap, systeeminformatie, crashrapport, PDF-handleiding en pakket-zelftest |
| Overig en energie | Uitschakeltimer instellen of annuleren |
| Geavanceerd | Formatteren van fysieke Disk 2 — uitsluitend voor ervaren gebruikers |

## Belangrijkste functies

### Diagnose en rapportage

- Volledige computerdiagnose
- Snelle hardwarecontrole
- Uitgebreide en snelle schijfcontrole
- Windows Geheugendiagnose openen
- Netwerkstabiliteitstest
- Wifi-rapport met verbindingsinformatie
- Laptopaccu- en energiecontrole
- Temperatuur- en stresstesthandleiding
- Handmatige hardwarechecklist
- Opstartprogramma's controleren
- Betrouwbaarheidsgeschiedenis en Windows-logboeken openen
- Systeeminformatie opslaan
- Crash- en blauwschermrapport maken
- Windows-prestatierapport openen

### Onderhoud en beveiliging

- Apps bijwerken via Windows Package Manager (`winget`)
- Windows controleren en repareren met DISM en SFC
- Snelle of volledige Microsoft Defender-scan
- Windows-herstelpunt maken
- Systeembeveiliging en Systeemherstel openen
- Herstelpuntenoverzicht als tekstbestand opslaan
- Windows Back-up openen
- Tijdelijke bestanden ouder dan zeven dagen veilig opruimen
- Windows Update bewust in- of uitschakelen
- TPM, Secure Boot en BitLocker-status controleren
- Externe Windows-drivers exporteren als extra back-up

### Windows-hulpmiddelen

Het pakket bevat directe snelkoppelingen naar onder andere:

- Apparaatbeheer
- Computerbeheer en Systeembeheer
- Broncontrole en Taakbeheer
- Windows-logboeken
- Windows Update en Windows-beveiliging
- Opstart-apps en probleemoplossers
- Klassiek geluidsmenu
- Netwerkverbindingen
- Herstelstation maken
- Opdrachtprompt als administrator

## Rapporten

De meeste diagnosefuncties bewaren hun resultaten in:

```text
Bureaublad\Computerdiagnose rapporten
```

Rapportnamen bevatten meestal datum en tijd, zodat verschillende metingen naast elkaar bewaard kunnen worden. Deel rapporten alleen nadat u hebt gecontroleerd of ze computernaam, gebruikersnaam, netwerkgegevens, hardwaregegevens of andere persoonlijke informatie bevatten.

## RDP Wrapper-diagnose

De meegeleverde RDP-diagnose:

- leest de status van Remote Desktop Services;
- controleert de `ServiceDll`-verwijzing;
- leest de versie van `termsrv.dll`;
- controleert RDP-poort en Network Level Authentication;
- zoekt bekende RDP Wrapper-bestanden;
- controleert of een passende `rdpwrap.ini`-sectie aanwezig is;
- maakt een tekstueel rapport;
- installeert, downloadt, start, stopt of wijzigt niets.

De diagnose bewijst niet dat meerdere gelijktijdige RDP-sessies werkelijk functioneren. RDP Wrapper is geen officieel ondersteunde meergebruikersoplossing voor Windows 11 Pro. Zet RDP-poort 3389 nooit rechtstreeks open naar het internet; gebruik een veilige VPN of een beheerde toegangsmethode.

## Zeer belangrijke DiskPart-waarschuwing

> **Gebruik `format-disk-2.bat` niet zomaar.**

Gebruik dit bestand alleen wanneer u:

- ervaring hebt met DiskPart;
- de risico's volledig begrijpt;
- precies weet welke fysieke schijf Windows als **Disk 2** aanduidt;
- model, capaciteit, volumes en partities zorgvuldig hebt gecontroleerd;
- vooraf een back-up hebt gemaakt;
- andere externe schijven bij voorkeur tijdelijk hebt losgekoppeld.

**Disk 2 is niet hetzelfde als stationsletter D:.** Alle partities en bestanden op de gekozen fysieke Disk 2 kunnen permanent worden verwijderd. Bent u niet volledig zeker, sluit het programma dan en ga niet verder.

Het script bevat meerdere waarschuwingen, weigert de actieve Windows-, opstart- of systeemschijf en vraagt om een exacte tekstbevestiging. Deze beveiligingen vervangen geen eigen controle en vakkennis.

## Veiligheidsindeling

Veel diagnose- en rapportagefuncties zijn alleen-lezen. De volgende onderdelen kunnen wel wijzigingen uitvoeren of een systeemactie starten:

- apps bijwerken;
- Windows repareren;
- een Defender-scan starten;
- herstelpunten maken;
- tijdelijke bestanden verwijderen;
- Windows Update in- of uitschakelen;
- drivers exporteren;
- een uitschakeling plannen;
- een herstelstation maken;
- een schijf formatteren.

Maak altijd eerst een back-up van belangrijke bestanden. Sluit programma's, bewaar open documenten en lees de bevestigingsteksten voordat u doorgaat.

## Compatibiliteit

Het pakket gebruikt ingebouwde Windows-onderdelen en **Windows PowerShell 5.1**. De beschikbare functies kunnen verschillen per Windows-versie en editie.

Voorbeelden:

- Lokaal beveiligingsbeleid is meestal niet beschikbaar op Windows Home.
- `winget` vereist Windows Package Manager/App Installer.
- Microsoft Defender-functies kunnen ontbreken wanneer andere antivirussoftware actief is.
- Temperatuur- en SMART-informatie is niet op ieder apparaat volledig beschikbaar.
- Sommige functies hebben administratorrechten nodig.

Er zijn geen aparte externe hulpprogramma's nodig voor het hoofdmenu. Voor langdurige RAM- of stresstests noemt de handleiding aanvullende, handmatig te gebruiken programma's.

## Handleidingen

- [Volledige TXT-handleiding](./Marco%20Beenen%20-%20Windows%20Tools%20v4.3/LEES%20MIJ%20-%20Handleiding%20computer%20testen.txt)
- [PDF-handleiding](./Marco%20Beenen%20-%20Windows%20Tools%20v4.3/Handleiding%20computer%20testen%20-%20Marco%20Beenen.pdf)
- [RDP-handleiding](./Marco%20Beenen%20-%20Windows%20Tools%20v4.3/LEESMIJ_RDP.txt)

## Pakketcontrole

Versie v4.3 bevat:

- 49 BAT-bestanden;
- één CMD-startbestand voor de RDP-diagnose;
- één PowerShell-script voor de RDP-diagnose;
- twee TXT-handleidingen;
- één PDF-handleiding;
- in totaal 54 bestanden in de pakketmap.

De ingebouwde `pakket_zelftest.bat` controleert onder andere:

- ontbrekende bestanden;
- menuverwijzingen;
- dubbele of niet-aangesloten tools;
- versieaanduiding;
- PowerShell-syntaxis van de RDP-diagnose;
- benodigde Windows-onderdelen.

## Problemen oplossen

### Het menu opent niet goed

Pak eerst de volledige ZIP uit. Controleer daarna of `START - Windows Tools.bat` nog samen met alle andere pakketbestanden in dezelfde map staat.

### Een functie meldt dat administratorrechten nodig zijn

Start alleen opnieuw als administrator wanneer u de functie bewust hebt gekozen. Annuleer de Windows-beveiligingsvraag als u niet zeker bent.

### Winget ontbreekt

Installeer of herstel **App Installer** via de Microsoft Store en probeer daarna opnieuw.

### Een rapport wordt niet gevonden

Controleer de map `Bureaublad\Computerdiagnose rapporten`. Sommige functies openen het gemaakte rapport automatisch in Kladblok of de browser.

### Windows waarschuwt voor een BAT- of PowerShell-bestand

Lees de broncode en handleiding voordat u doorgaat. Scripts uit internetdownloads kunnen door Windows extra worden gecontroleerd. Voer nooit een script uit wanneer de inhoud onverwacht is of niet overeenkomt met deze repository.

## Projectstructuur

```text
README.md
Marco Beenen - Windows Tools v4.3.zip
Marco Beenen - Windows Tools v4.3/
    START - Windows Tools.bat
    LEES MIJ - Handleiding computer testen.txt
    Handleiding computer testen - Marco Beenen.pdf
    ...overige diagnose-, onderhouds- en hulpprogramma's
```

## Maker

**Marco Beenen**

Versie 4.3 — 17 oktober 2026
