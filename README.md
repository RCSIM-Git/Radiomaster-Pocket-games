# 🎮 RadioMaster Pocket Games & Apps (EdgeTX 128x64 LCD) 🛸

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![EdgeTX](https://img.shields.io/badge/EdgeTX-2.8%2B%20%7C%202.9%20%7C%202.10%2B-orange.svg)](https://edgetx.org/)
[![Hardware](https://img.shields.io/badge/Hardware-RadioMaster%20Pocket%20%2F%20MT12%20%2F%20Boxer-blue.svg)](https://www.radiomasterrc.com/)
[![Display](https://img.shields.io/badge/Display-128x64%20Monochrome%20LCD-brightgreen.svg)]()
[![Python Simulators](https://img.shields.io/badge/PC%20Simulators-Python%203%20%2F%20Tkinter-green.svg)]()

Oficjalna kolekcja gier i aplikacji rozrywkowych stworzona specjalnie dla miniaturowej aparatury **RadioMaster Pocket** oraz innych aparatur z monochromatycznym ekranem **128x64** pracujących pod kontrolą systemu **EdgeTX** (np. MT12, Boxer, TX12, Zorro).

---

## 📑 Spis treści / Table of Contents
1. [Przegląd Gier / Games Showcase](#-przegląd-gier--games-showcase)
2. [Instrukcja Instalacji na Aparaturze (SD Card)](#-instrukcja-instalacji-na-aparaturze-krok-po-kroku)
3. [Symulatory PC (Graj na komputerze)](#-symulatory-pc-graj-na-komputerze-bez-radia)
4. [Tabela Sterowania / Controls](#-tabela-sterowania--controls-guide)
5. [Struktura Katalogów Karty SD](#-struktura-katalogów-karty-sd)
6. [Narzędzia Deweloperskie](#-narzędzia-deweloperskie--tools)
7. [Licencja](#-licencja--license)

---

## 🕹️ Przegląd Gier / Games Showcase

### 1. 🛸 Pocketmon: Drone Edition (`Pocketmon.lua`)
Autorskie retro RPG w świecie dronów FPV! 
- **Wybór Drona Startowego:** `WHOOPY` (Micro TinyWhoop), `5"BEAST` (Freestyle Monster), `TOOTHY` (Toothpick racer), `CINEMAX` (Pusher cinequad).
- **Eksploracja Świata:** Mapa lotniska i opuszczonego Bando z przeszkodami, hangarem i strefą ładowania pakietów.
- **Dzikie Drony:** Poluj i walcz z `MOBULA 7`, `NAZGUL 5`, czy legendarnym `PHANTOM` z atakiem *Return To Home*!
- **Mechanika Bindowania ELRS:** Zamiast Pokéballi wysyłasz pakiety bindowania telemetrii ELRS!
- **Szybka naprawa:** Przełącznik `[SE]` w padoku błyskawicznie ładuje pakiety LiPo Twojej floty.

### 2. ⚡ Pokémon Classic: Gen 1 (`Pokemon.lua`)
Wierne odtworzenie kultowego Pokémon Red/Blue z Game Boya dostosowane do ekranu 128x64:
- **Startery:** Pikachu, Charmander, Squirtle, Bulbasaur.
- **Eksploracja:** Pallet Town, Route 1, dzika trawa, mechanika losowych spotkań.
- **Turowy System Walki:** Paski HP, animacje ataków (Thundershock, Ember, Vine Whip), rzucanie Pokéballami i zapis stanu gry.

### 3. 🥚 PocketPet: Wirtualny Zwierzak / Tamagotchi (`PocketPet.lua`)
Kultowy wirtualny zwierzak retro na Twoim radiu!
- **Cykl życia:** Wykluwanie jajka, faza niemowlaka, dziecka oraz dorosłe ewolucje (m.in. Drone-Pet, Pika-Pet, Dino-Pet).
- **Opieka:** Karmienie (jabłka / baterie), sprzątanie odchodów prysznicem, gaszenie światła do snu, leczenie chorób.
- **Minigra zręcznościowa:** Łap spadające baterie i unikaj bomb gimbalem aparatury!
- **Stały zapis:** Stan Twojego zwierzaka zapisuje się na karcie SD (`pet.dat`).

### 4. 💀 DOOM: Pocket Edition (`Doom.lua`)
Prawdziwy silnik 3D Raycasting (pseudo-3D wolfenstein/doom) renderowany w czasie rzeczywistym na monochromatycznym ekranie LCD 128x64!
- **Płynny raycasting:** 64 promienie renderowane w ~30 FPS.
- **Arsenał:** Pistolet oraz potężny Shotgun z animacją strzału i odrzutu.
- **Przeciwnicy:** Demony czające się w korytarzach, minimapa podglądu pozycji oraz efekty dźwiękowe.

### 5. 🍎 Bad Apple!! PV Player (`BadApple.lua`)
Legendarna animacja *Bad Apple!!* odtwarzana bezpośrednio na aparaturze:
- **Płynny strumień wideo:** 20 FPS przy użyciu wydajnego silnika dekompresji prostokątów RLE.
- **Zsynchronizowany dźwięk:** Jakość 32kHz 16-bit PCM Mono.
- **Spektrum audio:** Równolegle animowany 4-pasmowy analizator widma audio na żywo.

### 6. 📻 Winamp Retro Player (`Winamp.lua`)
Kultowy odtwarzacz muzyczny Winamp 2.91 na Twoim nadajniku:
- **Interfejs retro:** 10-słupkowy animowany korektor graficzny (Spectrum Analyzer) z opadającymi pikami.
- **Duży licznik czasu:** Wyświetlacz segmentowy MM:SS, wskaźniki bitrate i częstotliwości.
- **Płynny Marquee:** Przewijane tytuły odtwarzanych utworów.
- **Playlista i sterowanie:** Play, Pause, Prev, Next, Repeat, Shuffle, przewijanie paska postępu.
- **Dźwięk:** Odsłuch przez wbudowany głośniczek lub wyjście słuchawkowe jack 3.5mm w aparaturze!

### 7. 🕹️ Retro Arcade Pack
Zestaw klasycznych gier zręcznościowych przygotowanych pod gimbale aparatury:
- **`Game-Asteroids.lua`**: Kosmiczna strzelanka z niszczeniem asteroid i efektami dźwiękowymi.
- **`Game-Breakout.lua`**: Klasyczny Arkanoid / niszczenie cegiełek paletką i piłką.
- **`Game-Pong.lua`**: Pojedynek z komputerowym przeciwnikiem na punkty.
- **`Game-Snake.lua`**: Nieśmiertelny wąż zbierający punkty na ekranie.
- **`Game-Simulator.lua`**: Mini-symulator lotu samolotem rc kontrolowany drążkami.
- **`Game-X-Tris.lua`**: Klasyczny Tetris z pełną oprawą graficzną i dźwiękami.

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
4. Przewiń listę i wybierz dowolną grę (np. **Pocketmon**, **Pokemon**, **Doom**, **PocketPet**).
5. Kliknij rolkę **`[ENT]`**, aby uruchomić grę!

---

## 💻 Symulatory PC (Graj na komputerze bez radia!)

Wszystkie główne gry posiadają dedykowane, w 100% wierne symulatory PC napisane w języku Python (wykorzystujące bibliotekę Tkinter wbudowaną w każdego standardowego Pythona na Windows).

### Jak uruchomić symulator:
Wejdź do folderu `simulators/` i uruchom odpowiedni plik dwuklikiem:
- **`run_pocketmon_sim.bat`** – Uruchamia Pocketmon: Drone Edition
- **`run_pokemon_sim.bat`** – Uruchamia Pokémon Classic Gen 1
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
│       ├── Game-Asteroids.lua
│       ├── Game-Breakout.lua
│       ├── Game-Pong.lua
│       ├── Game-Simulator.lua
│       ├── Game-Snake.lua
│       ├── Game-X-Tris.lua
│       ├── Pocketmon.lua
│       ├── PocketPet.lua
│       ├── Pokemon.lua
│       ├── Winamp.lua
│       ├── ASTEROIDS/       (Assety graficzne i dźwiękowe)
│       ├── BADAPPLE/        (badapple.dat, badapple.idx)
│       ├── BREAKOUT/        (Grafiki i dźwięki)
│       ├── POCKETMON/       (Instrukcje i konfiguracja)
│       ├── POCKETPET/       (pet.dat – stan zapisu)
│       ├── POKEMON/         (Instrukcje i konfiguracja)
│       └── X-TRIS/          (Assety Tetrisa)
└── SOUNDS/
    ├── DOOM/                (Efekty strzałów, wrogów i przedmiotów)
    ├── MUSIC/               (Utwory muzyczne, Winamp playlist, badapple.wav)
    ├── POCKETPET/           (8-bitowe retro dźwięki Tamagotchi)
    └── POKEMON/             (Dźwięki walki, ewolucji, bindowania i łapania)
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