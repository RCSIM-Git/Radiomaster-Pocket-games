# 🎮 RadioMaster Pocket Games & Apps Suite (EdgeTX 128x64 LCD) 🛸

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![EdgeTX](https://img.shields.io/badge/EdgeTX-2.8%2B%20%7C%202.9%20%7C%202.10%2B-orange.svg)](https://edgetx.org/)
[![Hardware](https://img.shields.io/badge/Hardware-RadioMaster%20Pocket%20%2F%20MT12%20%2F%20Boxer-blue.svg)](https://www.radiomasterrc.com/)
[![Display](https://img.shields.io/badge/Display-128x64%20Monochrome%20LCD-brightgreen.svg)]()
[![PC Simulators](https://img.shields.io/badge/PC%20Simulators-Python%203%20%2F%20Tkinter-green.svg)]()

> 🌐 **Language:** **English** | [Polski (Wersja polska)](README_PL.md)

The ultimate collection of custom retro games, media players, and entertainment tools engineered specifically for the compact **RadioMaster Pocket** and other **EdgeTX** transmitters featuring a **128x64 monochrome LCD screen** (such as the RadioMaster MT12, Boxer, TX12, and Zorro).

---

## 📑 Table of Contents
1. [Radio Hardware Compatibility](#-radio-hardware-compatibility)
2. [Games & Apps Showcase](#-games--apps-showcase)
3. [Radio SD Card Installation Guide](#-radio-sd-card-installation-guide-step-by-step)
4. [PC Simulators (Play on Desktop without Radio)](#-pc-simulators-play-on-desktop-without-radio)
5. [Controls Mapping Guide](#-controls-mapping-guide)
6. [SD Card Directory Structure](#-sd-card-directory-structure)
7. [Developer & Audio Tools](#-developer--audio-tools)
8. [License & Credits](#-license--credits)

---

## 📻 Radio Hardware Compatibility

All games and utilities are written in standard **EdgeTX Lua** and designed natively for **128x64 Monochrome LCD** screens.

### ✅ Fully Compatible (100% Plug & Play - 128x64)
Confirmed working out-of-the-box with zero configuration or code changes:
* **RadioMaster:**
  * **Pocket** (Native reference design)
  * **Boxer** (Same 128x64 LCD & STM32 processor)
  * **TX12 / TX12 MKII** (128x64 monochrome)
  * **Zorro** (128x64 monochrome – perfect gamepad ergonomics!)
  * **MT12** (Surface pistol-grip radio for RC cars & boats – steering wheel & trigger support)
* **Jumper:**
  * **T-Lite / T-Lite V2** (128x64 monochrome)
  * **T-Pro / T-Pro V2** (128x64 monochrome)
* **FrSky:**
  * **Taranis Q X7 / Q X7S** (128x64 monochrome)
  * **Taranis X9 Lite** (128x64 monochrome)
* **BetaFPV:**
  * **LiteRadio 3 Pro** (EdgeTX version)

### ⚠️ Partially Compatible (Wider or Color Screens)
* **FrSky Taranis X9D / X9D Plus / 2019 (212x64):** Runs at 100% full speed, rendered aligned to the left side of the wider display (with blank space on the right).
* **Color Screen Radios (RadioMaster TX16S / TX16S MKII, Jumper T16 / T18, FrSky Horus X10/X12, 480x272):** Scripts run without crashing, rendered in a 128x64 box in the top-left corner.

### ❌ Incompatible
* **FrSky ETHOS Radios (X18, X20, Tandem, Twin):** ETHOS uses a proprietary Lua API and does not support EdgeTX/OpenTX scripts.

### ⚙️ Firmware Requirements
* **Firmware:** EdgeTX 2.7+ (EdgeTX 2.8 / 2.9 / 2.10+ recommended) or OpenTX 2.3+ with `LUA` enabled.
* **MicroSD Card:** FAT32 formatted with standard `/SCRIPTS/TOOLS/` and `/SOUNDS/` directories.

---

## 🕹️ Games & Apps Showcase

### 1. 🛸 Pocketmon: Drone Edition (`Pocketmon.lua`)
An original retro RPG tailored for the FPV drone community!
* **Starter Quad Selection:** Choose your first starter drone at the workshop:
  * `WHOOPY` (Micro TinyWhoop – High RPM, ducted agility)
  * `5"BEAST` (Freestyle Monster – 6S raw power and durability)
  * `TOOTHY` (Toothpick 2-3" – Ultra-lightweight racer)
  * `CINEMAX` (Pusher Cinewhoop – Armored foam ducts, smooth roll)
* **Airfield & Bando Overworld:** Explore tarmac runways, tall weeds, safety fences, trees, and hangar workshops.
* **Wild Rogue Quads:** Encounter and battle wild quads like `MOBULA 7`, `NAZGUL 5`, and the rare legendary GPS boss `PHANTOM` featuring the *Return To Home* move!
* **ELRS Telemetry Binding:** Transmit **`BIND PACKETS`** over ExpressLRS to wirelessly bind rogue drones directly into your radio's Model Hangar!
* **Paddock Quick-Repair:** Flip momentary switch `[SE]` at the hangar paddock to instantly recharge all your LiPos.

### 2. 🥚 PocketPet: FPV Drone Virtual Pet (`PocketPet.lua`)
A full-featured virtual drone pet simulation running on your RC radio:
* **Life Cycle:** 4 Evolution Stages: Flight Case (Egg) ➔ TinyWhoop (Baby) ➔ Toothpick 3" (Child) ➔ Adult Fleet (5" Freestyle Beast, Cinewhoop 4K Pro, or FPV Flying Wing)!
* **Care System:** Charge LiPo batteries, clean grass/dirt from motors, calibrate ESCs, sleep mode, and service electronics.
* **Arcade Mini-Game:** "Catch the Battery" – pilot your drone with the transmitter gimbals to catch falling LiPos while dodging glitches!
* **Telemetry Integration:** PocketPet reads your radio's actual battery voltage and comments on your charge levels!
* **Battery-Backed Save State:** Progress automatically persists to `pet.dat` on the SD card.

### 3. 💀 DOOM: Pocket Edition (`Doom.lua`)
A real-time 3D Raycasting first-person shooter engine running at a smooth 30 FPS on a 128x64 monochrome display:
* **High-Performance Raycaster:** 64 rays cast in real time with distance shading.
* **Weapons:** Pistol and a devastating Shotgun with muzzle flash, recoil animation, and sound effects.
* **Enemies & Levels:** Imp demons roaming dungeon corridors, item pickups, and live mini-map navigation.

### 4. 🍎 Bad Apple!! PV Player (`BadApple.lua`)
The iconic *Bad Apple!!* music video streamed directly on your transmitter:
* **Smooth 20 FPS Video Streaming:** Powered by a customized high-speed 2D RLE rectangle decompression engine.
* **Synchronized Audio:** 32kHz 16-bit PCM mono audio playback.
* **Live Hardware Spectrum Analyzer:** Real-time 4-band audio EQ visualizer animated alongside the video in retro 4:3 theater mode.

### 5. 📻 PocketAmp: Retro 90s Player (`PocketAmp.lua`)
A nostalgic 90s-style desktop audio player recreated for EdgeTX:
* **Retro Interface:** Animated 10-bar graphic equalizer with falling peak meters.
* **Big LCD Timer:** Digital MM:SS segment display, bitrate, and sample rate indicators.
* **Smooth Marquee:** Horizontal scrolling ticker for song titles.
* **Full Playlist Support:** Prev, Play, Pause, Stop, Next, Repeat, Shuffle, and progress seek bar.
* **Audio Routing:** Listen via the built-in radio speaker or the 3.5mm headphone jack.

### 6. 🚗 CarPet: Virtual RC Garage Edition (`Game-CarPet.lua`)
An authentic retro virtual RC garage & car pet simulator for your transmitter:
* **Build & Maintain:** Assemble from bare Tamiya Kit up to Carbon Pro Roller, charge LiPo batteries, wash off track mud, and replace tires.
* **Iconic Evolutions:** Unlock Team Associated RC10 "Gold Tub", Yokomo YD-2 Drift S15, Traxxas TRX-4 Crawler, Subaru Impreza WRC '99, or Arrma Infraction 8S depending on your driving style.
* **Dyno Run Mini-Game:** Steer into target RPM zones and hold throttle to score XP.
* **Dual Control:** Natively supports both MT12 wheel/trigger and Pocket sticks!

### 7. 🏁 RC Racer: Highway Rush (`Game-RCRacer.lua`)
High-speed retro highway traffic dodger:
* **Action Packed:** Dodge civilian traffic, collect bonus gold coins, and push your speed up to 220 km/h.
* **Nitro Boost:** Hit Switch `[SD]` for temporary maximum acceleration!
* **Controls:** Smooth analog steering with MT12 wheel or Pocket gimbals.

### 8. 🏎️ Tomy Turnin' Turbo Dashboard (`Game-TomyTurbo.lua`)
Nostalgic recreation of the famous 1980s mechanical tabletop dashboard toy:
* **Mechanical Road Simulation:** Procedural pseudo-curved highway rendering simulating the rotating mechanical drum.
* **2-Speed Shifter:** Toggle Switch `[SB]` between LOW (0-60 km/h) and HIGH (up to 160 km/h!).
* **Fuel & Odometer:** Dodge obstacle vehicles, pick up fuel canisters, and rack up odometer distance before running dry.

### 9. 🏓 Pong MT12 & 🐍 Snake MT12 (`Game-Pong-MT12.lua`, `Game-Snake-MT12.lua`)
Arcade games optimized for EdgeTX 128x64 transmitters:
* **`Game-Pong-MT12.lua`**: Fast arcade table tennis with AI opponent, smash mechanics, and analog paddle control.
* **`Game-Snake-MT12.lua`**: Retro classic snake with trigger/stick boost mode.

### 10. ⏱️ Surface RC Utilities
* **`CarTuner.lua`**: RC curve, expo, and setup visualizer with profiles for Buggy, Drift, Crawler, and Rally.
* **`LapTimer.lua`**: High-precision lap timer and personal best (PB) tracker with audio beeps and trigger switches.

---

## 🚀 Radio SD Card Installation Guide (Step-by-Step)

### Prerequisites:
* Any transmitter running **EdgeTX 2.8+** (RadioMaster Pocket, MT12, Boxer, TX12, Zorro, etc.).
* A MicroSD card formatted as **FAT32**.

### Step 1: Connect your radio to PC
1. Power ON your radio transmitter.
2. Connect it to your PC via a USB-C cable.
3. On the radio LCD prompt, select **`USB Storage (SD)`**.
4. The SD card will mount on your computer as a removable drive.

### Step 2: Copy files
1. Download this repository (`Code` -> `Download ZIP` and extract).
2. Copy the folders:
   - 📁 **`SCRIPTS`**
   - 📁 **`SOUNDS`**
3. Paste directly into the **root of your SD card** (merge with existing folders).

### Step 3: Run on Radio
1. Safely disconnect USB.
2. Long-press **`[SYS]`** to enter the System Menu.
3. Page to the **`TOOLS`** tab.
4. Scroll and launch any game or tool!

---

## 💻 PC Simulators (Play on Desktop without Radio)

Every major game includes an accurate, standalone desktop simulator written in Python (using standard Tkinter, which comes pre-installed with Python on Windows).

### How to run:
Open the `simulators/` folder and double-click the desired launcher:
* **`run_pocketmon_sim.bat`** – Launches Pocketmon: Drone Edition
* **`run_pocket_pet_sim.bat`** – Launches Pocket Pet (Virtual Pet)
* **`run_bad_apple_sim.bat`** – Launches Bad Apple!! PV Player

*Requirements: Python 3.10+ installed from [python.org](https://www.python.org/).*

---

## 🎮 Controls Mapping Guide

| Action | RadioMaster Pocket (Sticks) | RadioMaster MT12 (Pistol) | PC Simulator |
| :--- | :--- | :--- | :--- |
| **Steering / Movement** | Gimbals (CH1/CH2 or RUD/AIL/ELE/THR) | Steering Wheel (ST) | Arrow Keys / `W`,`A`,`S`,`D` |
| **Throttle / Accelerate** | Throttle Stick (THR / ELE) | Throttle Trigger (TH Pull) | `W` / `Up` |
| **Brake / Reverse** | Throttle Stick down | Throttle Trigger (TH Push) | `S` / `Down` |
| **Select / Confirm / Fire** | Click Roller **`[ENT]`** | Roller **`[ENT]`** / Trigger Pull | **`Enter`** |
| **Back / Cancel / Exit** | Return Button **`[RTN]`** | Return Button **`[RTN]`** | **`Esc`** / **`Backspace`** |
| **Quick Action / Nitro / Shifter** | Switch **`[SE]`** / **`[SA]`** | Switch **`[SD]`** / **`[SB]`** | **`Spacebar`** / **`Tab`** |

---

## 📁 SD Card Directory Structure

Once copied to your SD card, your file tree will look like this:

```text
SD_CARD_ROOT/
├── SCRIPTS/
│   └── TOOLS/
│       ├── BadApple.lua
│       ├── Doom.lua
│       ├── Pocketmon.lua
│       ├── PocketPet.lua
│       ├── PocketAmp.lua
│       ├── Game-CarPet.lua
│       ├── Game-RCRacer.lua
│       ├── Game-TomyTurbo.lua
│       ├── Game-Pong-MT12.lua
│       ├── Game-Snake-MT12.lua
│       ├── CarTuner.lua
│       ├── LapTimer.lua
│       ├── BADAPPLE/        (badapple.dat, badapple.idx)
│       ├── CARPET/          (carpet.dat – persistent garage save)
│       ├── POCKETMON/       (Config & documentation)
│       └── POCKETPET/       (pet.dat – persistent drone save)
└── SOUNDS/
    ├── DOOM/                (Gunshots, monster sounds, item pickups)
    ├── MUSIC/               (Tracks, PocketAmp playlist, badapple.wav)
    ├── POCKETPET/           (8-bit retro virtual pet chiptunes)
    └── POCKETMON/           (FPV drone moves, telemetry binds, level up)
```

---

## 🛠️ Developer & Audio Tools

Located in the `tools/` folder:
* **`convert_to_edgetx_wav.bat` / `convert_music.py`**: Automatically converts any MP3, FLAC, or M4A audio into the required EdgeTX format (**WAV, 32000 Hz, 16-bit PCM, Mono**) and appends it to `playlist.txt`.
* **`build_pocket_pet_assets.py`**: Mathematical 8-bit sound synthesizer that generates all retro sound effects for Pocket Pet.
* **`build_bad_apple.py`**: 2D RLE video frame compressor and 4-band audio frequency analyzer.
* **`verify_lua.py`**: Static syntax and block-balance analyzer for EdgeTX Lua scripts.

---

## 📄 License & Credits

Distributed under the open-source **MIT License**. Feel free to fork, expand, and share with the global RC and EdgeTX pilot communities!

See the [LICENSE](LICENSE) file for complete details.  
Created by: **RCSIM** ([GitHub](https://github.com/RCSIM-Git))