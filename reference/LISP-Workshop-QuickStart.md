# AutoCAD LISP Workshop - Quick Start Guide

Welkom bij de LISP workshop. Deze handleiding bevat alle technische informatie om direct aan de slag te gaan met AutoCAD automatisering via LISP-routines.

## 🚀 Stap 1: Folder Structuur Opzetten

We beginnen met een georganiseerde werkstructuur. Dit voorkomt problemen met AutoCAD's trusted locations.

### PowerShell Script Uitvoeren

1. **Pak files.zip uit**
   - Download het bestand (heb je al gedaan als je dit leest)
   - Klik in de verkenner op "Extract all"
   - Klik `Windows + V` en dan `Turn on`
   - Selecteer in de map waar je zojuist de bestanden hebt gemaakt `setup-lisp-folders.ps1` (niet openen) en `Control + Shift + C`

2. **Verkrijg Administrator Access**
   - Druk `Windows` en zoek `Administrator Access`
   - Geef aan dat je het nodig hebt `for work`

3. **Open Windows Powershell mét Administrator Access**
   - Druk `Windows` en zoek `Windows PowerShell`
   - Klik op `Windows PowerShell` met de **RECHTER MUISKNOP**
   - Klik op **Run as administrator**

4. **Stel Execution Policy in**
   - Voer het volgende commando uit in Windows PowerShell:

     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

     NB. 'Code' wordt voorafgegaan door:

     ````text
     ```{naam van de programmeertaal}
     {Het uit te voeren programma}
     ```
     ````

     Dit zul je later ook nog terug zien bij de LISP-routines!
     Kopieer alleen het uit te voeren programma.

   - Type `Y` en Enter.

5. **Navigeer naar de script locatie**:
   - Typ in PowerShell `cd` gevolgd door een spatie, en dan `Windows + V`, en kies uit de lijst het pad naar je script.

   OF

   ```powershell
   cd "C:\pad\naar\script"
   ```

6. **Voer het script uit**:

   ```powershell
   .\setup-lisp-folders.ps1
   ```

7. **Het script maakt deze structuur aan in Documents**:

   ```text
   C:\Users\{gebruikersnaam}\Documents\AutoCAD-LISP\
   ├── 01-Workshop\
   │   ├── Voorbeelden\
   │   ├── Oefeningen\
   │   ├── Modules\
   │   └── Projecten\
   ├── 02-Productie\
   ├── 03-Templates\
   └── 04-Documentatie\
   ```

**💡 BELANGRIJK**: Noteer het pad dat het script toont. Dit pad voeg je toe aan AutoCAD's Trusted Locations.

### AutoCAD Trusted Locations Instellen

1. In AutoCAD: type `OPTIONS` (of `OP`)
2. Ga naar tabblad **Files**
3. Vouw uit: **Support File Search Path**
4. Klik **Add...** en voeg je AutoCAD-LISP folder toe
5. Ga naar **Trusted Locations**
6. Klik **Add...** en voeg dezelfde folder toe
7. Klik **OK**

---

## 🔧 Stap 2: Code Editor Kiezen

### Optie A: Visual Studio Code (Aanbevolen - Modern)

1. **Download VS Code**: [code.visualstudio.com](https://code.visualstudio.com)
2. **Installeer AutoLISP Extension**:
   - Open VS Code
   - Druk `Ctrl+Shift+X` (Extensions)
   - Zoek "AutoCAD AutoLISP Extension" (van Autodesk)
   - Klik **Install**
3. **Stel in als standaard voor .lsp files**:
   - Rechtsklik op een .lsp bestand
   - **Openen met** → **Een andere app kiezen**
   - Selecteer VS Code
   - Vink **Altijd deze app gebruiken** aan

**Voordelen VS Code:**

- Syntax highlighting
- Auto-complete
- Debugging mogelijkheden
- Geïntegreerd met AutoCAD 2024/2025
- Git integratie

### Optie B: Notepad++ (Simpel)

Als je Notepad++ al hebt geïnstalleerd:

1. Rechtsklik op een .lsp bestand
2. **Openen met** → **Een andere app kiezen**
3. Selecteer Notepad++
4. Vink **Altijd deze app gebruiken** aan

---

## 📝 Stap 3: Je Eerste LISP Routine - Hello World

Open je gekozen editor en maak een nieuw bestand.

### Hello World Voorbeeld

```lisp
;; Eerste LISP routine - Hello World
;; Bestandsnaam: hello-world.lsp

(defun c:HALLO ()
  (princ "\nWorkshop LISP Programmeren - Oktober 2025")
  (princ "\nType een AutoCAD command om verder te gaan...")
  (princ)  ; Voorkomt nil in output
)

(princ "\nHALLO command geladen. Type HALLO om uit te voeren.")
```

**Code Uitleg:**

- `defun c:HALLO` - Definieert een AutoCAD command
- `princ` - Print text naar command line
- `\n` - Nieuwe regel
- Laatste `(princ)` - Clean exit zonder nil

### Bestand Laden in AutoCAD

1. **Sla op als**: `hello-world.lsp` in `Documents\AutoCAD-LISP\01-Workshop\Voorbeelden\`

2. **In AutoCAD**:
   - Type `APPLOAD` (of `AP`)
   - Navigeer naar je bestand
   - Je krijgt automatisch een popup:
     - **Load Once** - Alleen deze sessie
     - **Always Load** - Bij elke AutoCAD start
   - Voor de workshop: kies **Load Once**

3. **Permanent laden** (voor productie routines):
   - In APPLOAD dialog: klik **Contents...**
   - Klik **Add...**
   - Selecteer je .lsp bestand
   - **Close** → **Close**

4. **Uitvoeren**: Type `HALLO` in command line

---

## 🎯 Stap 4: Modulair Werken - Routines Combineren

**BELANGRIJK CONCEPT**: Werk met kleine, herbruikbare modules. Eén functie per bestand maakt debugging en onderhoud veel eenvoudiger.

### Module 1: Geometrie Helper

Bestand: `geometrie-helper.lsp`

```lisp
;; Hulpfuncties voor geometrische berekeningen
;; Bestandsnaam: geometrie-helper.lsp

(defun bereken-middelpunt (p1 p2 p3)
  ;; Berekent middelpunt van drie punten
  (list
    (/ (+ (car p1) (car p2) (car p3)) 3.0)
    (/ (+ (cadr p1) (cadr p2) (cadr p3)) 3.0)
    (/ (+ (caddr p1) (caddr p2) (caddr p3)) 3.0)
  )
)

(defun afstand-tussen-punten (p1 p2)
  ;; Berekent afstand tussen twee punten
  (distance p1 p2)
)

(princ "\nGeometrie helper functies geladen.")
```

### Module 2: Teken Functies

Bestand: `teken-functies.lsp`

```lisp
;; Teken functies met error handling
;; Bestandsnaam: teken-functies.lsp

(defun teken-lijn-met-kleur (p1 p2 kleur / oude-kleur)
  ;; Error checking
  (if (and p1 p2 kleur)
    (progn
      ;; Bewaar huidige instellingen
      (setq oude-kleur (getvar "CECOLOR"))

      ;; Teken met nieuwe kleur
      (setvar "CECOLOR" (itoa kleur))
      (command "LINE" p1 p2 "")

      ;; Herstel originele kleur
      (setvar "CECOLOR" oude-kleur)
      T  ; Return success
    )
    nil  ; Return failure
  )
)

(princ "\nTeken functies geladen.")
```

### Module 3: Hoofd Routine

Bestand: `driehoek-tool.lsp`

```lisp
;; Hoofdroutine die modules combineert
;; Bestandsnaam: driehoek-tool.lsp

(defun c:DRIEHOEK ( / p1 p2 p3 centrum)
  ;; Laad benodigde modules
  (if (not bereken-middelpunt)
    (load "geometrie-helper.lsp")
  )
  (if (not teken-lijn-met-kleur)
    (load "teken-functies.lsp")
  )

  ;; Verzamel input met error handling
  (setq p1 (getpoint "\nEerste hoekpunt: "))
  (if p1
    (progn
      (setq p2 (getpoint p1 "\nTweede hoekpunt: "))
      (if p2
        (progn
          (setq p3 (getpoint p2 "\nDerde hoekpunt: "))
          (if p3
            (progn
              ;; Teken driehoek
              (teken-lijn-met-kleur p1 p2 1)  ; Rood
              (teken-lijn-met-kleur p2 p3 3)  ; Groen
              (teken-lijn-met-kleur p3 p1 5)  ; Blauw

              ;; Plaats label in centrum
              (setq centrum (bereken-middelpunt p1 p2 p3))
              (command "TEXT" "J" "MC" centrum "5" "0" "Driehoek")

              (princ "\nDriehoek succesvol getekend.")
            )
            (princ "\nGeen derde punt opgegeven.")
          )
        )
        (princ "\nGeen tweede punt opgegeven.")
      )
    )
    (princ "\nGeen eerste punt opgegeven.")
  )
  (princ)
)

(princ "\nDRIEHOEK command geladen.")
```

**Voordelen Modulair Werken:**

- Herbruikbare code
- Makkelijker debuggen
- Betere organisatie
- Team-vriendelijk
- Versie controle vriendelijk

---

## 🤖 Stap 5: Microsoft Copilot Gebruiken

Copilot kan complete LISP routines genereren. Gebruik specifieke prompts voor beste resultaten.

### Effectieve Copilot Prompts

```text
"Schrijf een AutoCAD LISP functie die:
- Alle TEXT entities selecteert
- De teksthoogte vermenigvuldigt met 1.5
- Error handling bevat
- Compatibel is met AutoCAD 2025"
```

```text
"Maak een modulaire LISP routine voor AutoCAD die:
- Een functie heeft om layers te maken
- Een functie heeft om layer eigenschappen in te stellen
- Hoofdfunctie c:LAYERSETUP die beide aanroept
- Gebruik maakt van error handling met *error* functie"
```

### Copilot Best Practices

1. **Specificeer AutoCAD versie** (2024/2025)
2. **Vraag om error handling**
3. **Vraag om modulaire code**
4. **Vraag om comments in Nederlands**
5. **Test gegenereerde code eerst op test drawings**

---

## 🎮 Projectideeën

### Laagdrempelige Opties

1. **AsBuilt Converter**
   - Verander layer eigenschappen van ToBuild naar AsBuilt
   - Wijzig kleuren en lijntypes
   - Update tekst prefixes

2. **Batch Layer Creator**
   - Maak standaard layers aan volgens bedrijfsstandaard
   - Stel kleuren en lijntypes in
   - Importeer uit template

3. **Quick Dimension Tool**
   - Plaats dimensies met vaste stijl
   - Automatische layer selectie
   - Sneltoetsen voor verschillende types

4. **Block Counter**
   - Tel specifieke blocks
   - Genereer rapport
   - Export naar clipboard

### Geavanceerde Opties

1. **Drawing Cleanup Suite**
   - Purge alle ongebruikte elementen
   - Audit en herstel
   - Zoom extents
   - Save met backup

2. **Revision Cloud Manager**
   - Plaats revision clouds met nummer
   - Update revision tabel
   - Track wijzigingen per datum

3. **Cable Tray Generator**
   - Teken kabelgoten met parameters
   - Automatische bochten
   - T-stukken en verbindingen
   - BOM generatie

4. **Room Data Extractor**
   - Lees polyline boundaries
   - Bereken oppervlaktes
   - Plaats room labels
   - Export naar Excel

5. **Parametric Equipment**
   - Teken equipment volgens specs
   - Aanpasbare parameters
   - Automatische annotations
   - Connection points

---

## 🔧 Troubleshooting

### Veel Voorkomende Issues

#### "Unknown command"

- Controleer spelling (hoofdlettergevoelig)
- Is routine geladen? Check: `!c:JOUWCOMMAND`
- Controleer haakjes balans

#### "Error: bad argument type"

- Variabele is nil waar waarde verwacht
- Voeg nil checks toe: `(if variabele ...)`
- Gebruik `(vl-catch-all-apply ...)`

#### "Malformed list on input"

- Ongelijke haakjes
- VS Code/Notepad++ toont haakjes paren
- Check met `(load "bestand.lsp")` voor specifieke regel

#### Performance Issues

```lisp
;; Zet command echo uit voor snelheid
(setvar "CMDECHO" 0)
;; ... je code ...
(setvar "CMDECHO" 1)
```

#### Error Handler Template

```lisp
(defun c:MYCOMMAND ( / *error* old-cmdecho)
  (defun *error* (msg)
    (if old-cmdecho (setvar "CMDECHO" old-cmdecho))
    (if (not (member msg '("Function cancelled" "quit / exit abort")))
      (princ (strcat "\nError: " msg))
    )
    (princ)
  )
  (setq old-cmdecho (getvar "CMDECHO"))
  (setvar "CMDECHO" 0)

  ;; Je code hier

  (setvar "CMDECHO" old-cmdecho)
  (princ)
)
```

---

## 📚 Handige Resources

- **AutoCAD LISP Reference**: [help.autodesk.com/view/ACD/2025/ENU/](https://help.autodesk.com/view/ACD/2025/ENU/?guid=GUID-B36082E8-9AD4-4158-BEAC-7C2CC5BBCF3F)
- **Visual LISP IDE** (Legacy): Type `VLIDE` in AutoCAD
- **VS Code AutoLISP**: [marketplace.visualstudio.com](https://marketplace.visualstudio.com/items?itemName=Autodesk.autolispext)
- **Lee Mac Programming**: [lee-mac.com](http://lee-mac.com) - Uitgebreide voorbeelden
- **Microsoft Copilot**: [copilot.microsoft.com](https://copilot.microsoft.com)
- **AfraLISP Tutorial**: [afralisp.net](https://afralisp.net) - Basis tutorials

---

Workshop AutoCAD LISP Programmeren | Oktober 2025 | Versie 2.0
