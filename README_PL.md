# 🎮 RadioMaster Pocket Games & Apps (EdgeTX 128x64 LCD) 🛸

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![EdgeTX](https://img.shields.io/badge/EdgeTX-2.8%2B%20%7C%202.9%20%7C%202.10%2B-orange.svg)](https://edgetx.org/)
[![Hardware](https://img.shields.io/badge/Hardware-RadioMaster%20Pocket%20%2F%20MT12%20%2F%20Boxer-blue.svg)](https://www.radiomasterrc.com/)
[![Display](https://img.shields.io/badge/Display-128x64%20Monochrome%20LCD-brightgreen.svg)]()
[![Python Simulators](https://img.shields.io/badge/PC%20Simulators-Python%203%20%2F%20Tkinter-green.svg)]()

> 🌐 **Język / Language:** [English (Default)](README.md) | **Polski**

Oficjalna kolekcja gier i aplikacji rozrywkowych stworzona specjalnie dla miniaturowej aparatury **RadioMaster Pocket** oraz innych aparatur z monochromatycznym ekranem **128x64** pracujących pod kontrolą systemu **EdgeTX** (np. MT12, Boxer, TX12, Zorro).

---

## 📑 Spis treści / Table of Contents
1. [Kompatybilność z Aparaturami](#-kompatybilność-z-innymi-aparaturami-edgetx--opentx)
2. [Przegląd Gier / Games Showcase](#-przegląd-gier--games-showcase)
3. [Instrukcja Instalacji na Aparaturze (SD Card)](#-instrukcja-instalacji-na-aparaturze-krok-po-kroku)
4. [Symulatory PC (Graj na komputerze)](#-symulatory-pc-graj-na-komputerze-bez-radia)
5. [Tabela Sterowania / Controls](#-tabela-sterowania--controls-guide)
6. [Struktura Katalogów Karty SD](#-struktura-katalogów-karty-sd)
7. [Narzędzia Deweloperskie](#-narzędzia-deweloperskie--tools)
8. [Licencja](#-licencja--license)

---

## 📻 Kompatybilność z Innymi Aparaturami (EdgeTX / OpenTX)

Wszystkie gry i aplikacje zostały napisane w czystym **EdgeTX Lua** i zoptymalizowane natywnie pod monochromatyczne ekrany **128x64 LCD**.

### ✅ Pełna kompatybilność (100% Plug & Play - 128x64)
Potwierdzone działanie od razu, bez konieczności jakichkolwiek modyfikacji kodu:
* **RadioMaster:**
  * **Pocket** (Natywna platforma referencyjna)
  * **Boxer** (Ten sam ekran 128x64 LCD i procesor STM32)
  * **TX12 / TX12 MKII** (128x64 monochromatyczny)
  * **Zorro** (128x64 monochromatyczny – format gamepadu!)
  * **MT12** (Aparatura pistoletowa do modeli aut i łodzi – sterowanie kołem i spustem)
* **Jumper:**
  * **T-Lite / T-Lite V2** (128x64 mono)
  * **T-Pro / T-Pro V2** (128x64 mono)
* **FrSky:**
  * **Taranis Q X7 / Q X7S** (128x64 mono)
  * **Taranis X9 Lite** (128x64 mono)
* **BetaFPV:**
  * **LiteRadio 3 Pro** (Wersja z EdgeTX)

### ⚠️ Częściowa kompatybilność (Szersze lub kolorowe ekrany)
* **FrSky Taranis X9D / X9D Plus / 2019 (212x64):** Gry działają w 100% płynnie, wyjustowane do lewej krawędzi szerszego wyświetlacza (z marginesem po prawej).
* **Aparatury z kolorowymi ekranami (RadioMaster TX16S / TX16S MKII, Jumper T16 / T18, FrSky Horus X10/X12, 480x272):** Gry uruchamiają się bez błędów, renderowane w oknie 128x64 w lewym górnym rogu.

### ❌ Brak kompatybilności
* **Aparatury z systemem FrSky ETHOS (np. X18, X20, Tandem, Twin):** ETHOS posiada własne, odmienne API Lua i nie uruchamia skryptów EdgeTX/OpenTX.

### ⚙️ Wymagania
* **Oprogramowanie:** EdgeTX 2.7+ (zalecane EdgeTX 2.8 / 2.9 / 2.10+) lub OpenTX 2.3+ z włączoną obsługą `LUA`.
* **Karta pamięci:** Format FAT32 ze standardową strukturą katalogów `/SCRIPTS/TOOLS/` oraz `/SOUNDS/`.

---

## 🕹️ Przegląd Gier / Games Showcase

### 1. 🛸 Pocketmon: Drone Edition (`Pocketmon.lua`)
Autorskie retro RPG w świecie dronów FPV! 
- **Wybór Drona Startowego:** `WHOOPY` (Micro TinyWhoop), `5"BEAST` (Freestyle Monster), `TOOTHY` (Toothpick racer), `CINEMAX` (Pusher cinequad).
- **Eksploracja Świata:** Mapa lotniska i opuszczonego Bando z przeszkodami, hangarem i strefą ładowania pakietów.
- **Dzikie Drony:** Poluj i walcz z `MOBULA 7`, `NAZGUL 5`, czy legendarnym `PHANTOM` z atakiem *Return To Home*!
- **Mechanika Bindowania ELRS:** Zamiast Pokéballi wysyłasz pakiety bindowania telemetrii ELRS!
- **Szybka naprawa:** Przełącznik `[SE]` w padoku błyskawicznie ładuje pakiety LiPo Twojej floty.

### 2. 🥚 PocketPet: Wirtualny Dron FPV (`PocketPet.lua`)
Zaawansowany symulator wirtualnego zwierzaka-drona w stylu retro na Twoim nadajniku:
- **Cykl życia:** 4 etapy ewolucji floty: Skrzynia transportowa (Jajko) ➔ TinyWhoop (Baby) ➔ Toothpick 3" (Child) ➔ Dorosły quad (5" Freestyle Beast, Cinewhoop 4K Pro lub Skrzydło FPV Wing)!
- **Obsługa i opieka:** Ładowanie pakietów LiPo, czyszczenie silników z trawy i brudu, kalibracja ESC, tryb uśpienia i serwis elektroniki.
- **Minigra zręcznościowa:** "Catch the Battery" – steruj dronem za pomocą drążków aparatury, łap spadające pakiety LiPo i unikaj zakłóceń!
- **Telemetria na żywo:** PocketPet odczytuje rzeczywiste napięcie akumulatora Twojej aparatury i na bieżąco je komentuje!
- **Stały zapis:** Postęp i stan Twojego drona automatycznie zapisują się na karcie SD (`pet.dat`).

### 3. 💀 DOOM: Pocket Edition (`Doom.lua`)
Prawdziwy silnik 3D Raycasting (pseudo-3D wolfenstein/doom) renderowany w czasie rzeczywistym na monochromatycznym ekranie LCD 128x64!
- **Płynny raycasting:** 64 promienie renderowane w ~30 FPS.
- **Arsenał:** Pistolet oraz potężny Shotgun z animacją strzału i odrzutu.
- **Przeciwnicy:** Demony czające się w korytarzach, minimapa podglądu pozycji oraz efekty dźwiękowe.

### 4. 🍎 Bad Apple!! PV Player (`BadApple.lua`)
Legendarna animacja *Bad Apple!!* odtwarzana bezpośrednio na aparaturze:
- **Płynny strumień wideo:** 20 FPS przy użyciu wydajnego silnika dekompresji prostokątów RLE.
- **Zsynchronizowany dźwięk:** Jakość 32kHz 16-bit PCM Mono.
- **Spektrum audio:** Równolegle animowany 4-pasmowy analizator widma audio na żywo.

### 5. 📻 PocketAmp: Retro Odtwarzacz z Lat 90. (`PocketAmp.lua`)
Kultowy styl klasycznych desktopowych odtwarzaczy muzycznych z lat 90. na Twoim nadajniku:
- **Interfejs retro:** 10-słupkowy animowany korektor graficzny (Spectrum Analyzer) z opadającymi pikami.
- **Duży licznik czasu:** Wyświetlacz segmentowy MM:SS, wskaźniki bitrate i częstotliwości.
- **Płynny Marquee:** Przewijane tytuły odtwarzanych utworów.
- **Playlista i sterowanie:** Play, Pause, Prev, Next, Repeat, Shuffle, przewijanie paska postępu.
- **Dźwięk:** Odsłuch przez wbudowany głośniczek lub wyjście słuchawkowe jack 3.5mm w aparaturze!

---

## 🚀 Instrukcja Instalacji na Aparaturze (Krok po kroku)

### Wymagania:
- Dowolna aparatura z systemem **EdgeTX 2.8+** (RadioMaster Pocket, MT12, Boxer, TX12, Zorro itp.).
- Karta pamięci MicroSD sformatowana w systemie **FAT32**.

### Krok 1: Podłączenie aparatury do komputera
1. Włącz aparaturę.
2. Podłącz ją kablem USB-C do komputera.
3. Na ekranie aparatury wybierz opcję: **`USB Storage (SD)`**.
4. W komputerze pojawi się dysk wymienny Twojej karty SD (np. `E:\` lub `F:\`).

### Krok 2: Kopiowanie plików
1. Pobierz to repozytorium (kliknij zielony przycisk **`Code` -> `Download ZIP`** i wypakuj).
2. Skopiuj foldery:
   - 📁 **`SCRIPTS`**
   - 📁 **`SOUNDS`**
3. Wklej je bezpośrednio do **głównego katalogu karty SD** (nadpisz lub połącz z istniejącymi folderami).

> [!TIP]
> Upewnij się, że pliki gier trafiły do `[SD]/SCRIPTS/TOOLS/`, a dźwięki do `[SD]/SOUNDS/`.

### Krok 3: Uruchomienie gry na aparaturze
1. Bezpiecznie odłącz kabel USB od aparatury.
2. Przytrzymaj przycisk **`[SYS]`** na aparaturze, aby wejść w menu systemowe.
3. Za pomocą rolki przejdź na zakładkę **`TOOLS`** (Narzędzia).
4. Przewiń listę i wybierz dowolną aplikację (np. **Pocketmon**, **PocketPet**, **Doom**, **PocketAmp**).
5. Kliknij rolkę **`[ENT]`**, aby uruchomić!

---

## 💻 Symulatory PC (Graj na komputerze bez radia!)

Wszystkie główne gry posiadają dedykowane, w 100% wierne symulatory PC napisane w języku Python (wykorzystujące bibliotekę Tkinter wbudowaną w każdego standardowego Pythona na Windows).

### Jak uruchomić symulator:
Wejdź do folderu `simulators/` i uruchom odpowiedni plik dwuklikiem:
- **`run_pocketmon_sim.bat`** – Uruchamia Pocketmon: Drone Edition
- **`run_pocket_pet_sim.bat`** – Uruchamia wirtualnego zwierzaka Pocket Pet
- **`run_bad_apple_sim.bat`** – Uruchamia odtwarzacz Bad Apple!!

*Wymagania PC: Zainstalowany Python 3.10+ (dostępny na python.org).*

---

## 🎮 Tabela Sterowania / Controls Guide

| Akcja w grze | Aparatura RadioMaster Pocket | Klawiatura PC (Symulator) |
| :--- | :--- | :--- |
| **Poruszanie się (Góra/Dół/Lewo/Prawo)** | Lewy lub prawy Gimbal (drążki) | Strzałki / `W`, `A`, `S`, `D` |
| **Wybór / Akcja / Atak / Zatwierdź** | Kliknięcie rolki **`[ENT]`** | Klawisz **`Enter`** |
| **Powrót / Anuluj / Menu Start** | Przycisk powrotu **`[RTN]`** | Klawisz **`Esc`** / **`Backspace`** |
| **Szybka akcja / Naprawa / Przełącznik** | Przełącznik chwilowy **`[SE]`** | Klawisz **`Spacja`** |
| **Pauza / Zmiana widoku** | Przełącznik **`[SA]`** lub **`[SB]`** | Klawisz **`Tab`** / **`P`** |

---

## 📁 Struktura Katalogów Karty SD

Po skopiowaniu na kartę SD struktura powinna wyglądać następująco:

```text
SD_CARD_ROOT/
├── SCRIPTS/
│   └── TOOLS/
│       ├── BadApple.lua
│       ├── Doom.lua
│       ├── Pocketmon.lua
│       ├── PocketPet.lua
│       ├── PocketAmp.lua
│       ├── BADAPPLE/        (badapple.dat, badapple.idx)
│       ├── POCKETMON/       (Instrukcje i konfiguracja)
│       └── POCKETPET/       (pet.dat – stan zapisu)
└── SOUNDS/
    ├── DOOM/                (Efekty strzałów, wrogów i przedmiotów)
    ├── MUSIC/               (Utwory muzyczne, PocketAmp playlist, badapple.wav)
    ├── POCKETPET/           (8-bitowe retro dźwięki Tamagotchi)
    └── POCKETMON/           (Dźwięki quadów, manewry FPV, bindowanie ELRS)
```

---

## 🛠️ Narzędzia Deweloperskie / Tools

W folderze `tools/` znajdują się skrypty ułatwiające rozbudowę projektu:
- **`convert_to_edgetx_wav.bat` / `convert_music.py`**: Automatyczny konwerter dowolnych plików MP3/FLAC na wymagany przez EdgeTX format **WAV 32000Hz, 16-bit PCM, Mono** wraz z dodawaniem do `playlist.txt`.
- **`build_pocket_pet_assets.py`**: Syntezator 8-bitowych retro dźwięków generowanych matematycznie dla Pocket Pet.
- **`build_bad_apple.py`**: Kompresor wideo RLE oraz analityk pasm częstotliwości audio.
- **`verify_lua.py`**: Walidator składni i domknięć bloków skryptów Lua dla EdgeTX.

---

## 📄 Licencja / License

Projekt jest udostępniony na otwartej licencji **MIT License**. Możesz go dowolnie modyfikować, rozwijać i dzielić się nim ze społecznością pilotów RC i entuzjastów EdgeTX!

Szczegóły w pliku [LICENSE](LICENSE).
Twórca: **RCSIM** ([GitHub](https://github.com/RCSIM-Git))