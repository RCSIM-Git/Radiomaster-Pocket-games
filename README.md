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
* **ELRS Telemetry Binding:** Instead of throwing Pokéballs, transmit **`BIND PACKETS`** over ExpressLRS to bind rogue drones directly into your radio's Model Hangar!
* **Paddock Quick-Repair:** Flip momentary switch `[SE]` at the hangar paddock to instantly recharge all your LiPos.

### 2. 🥚 PocketPet: Virtual Pet / Tamagotchi (`PocketPet.lua`)
A full-featured virtual pet simulation running on your RC radio:
* **Life Cycle:** Egg incubation, hatching ceremony, baby, child, and adult evolution forms (including Drone-Pet, Pika-Pet, and Dino-Pet).
* **Care System:** Feed with apples or recharge with batteries, clean poop with water showers, turn off lights for sleep, and treat illnesses.
* **Arcade Mini-Game:** Catch falling batteries and dodge bombs/glitches using the transmitter gimbals!
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

---

## 🚀 Radio SD Card Installation Guide (Step-by-Step)

### Prerequisites:
* Any transmitter running **EdgeTX 2.8+** (RadioMaster Pocket, MT12, Boxer, TX12, Zorro, etc.).
* A MicroSD card formatted as **FAT32**.

### Step 1: Connect your transmitter to PC
1. Turn on your radio.
2. Connect it to your PC using a USB-C cable.
3. On the radio screen, select **`USB Storage (SD)`**.
4. Your SD card will mount on your PC as a removable drive (e.g., `E:\` or `F:\`).

### Step 2: Copy Files
1. Download this repository (click the green **`Code` ➔ `Download ZIP`** button and extract it).
2. Copy the two main folders:
   * 📁 **`SCRIPTS`**
   * 📁 **`SOUNDS`**
3. Paste them directly into the **root directory of your SD card** (merge with existing folders).

> [!TIP]
> Ensure the Lua scripts are located in `[SD]/SCRIPTS/TOOLS/` and sound files in `[SD]/SOUNDS/`.

### Step 3: Launch on the Radio
1. Safely eject the USB connection from your PC.
2. Long-press the **`[SYS]`** button on your radio to enter the system menu.
3. Use the roller wheel to navigate to the **`TOOLS`** tab.
4. Scroll through the list and select any app (e.g., **Pocketmon**, **PocketPet**, **Doom**, **PocketAmp**).
5. Click the roller wheel **`[ENT]`** to launch and play!

---

## 💻 PC Simulators (Play on Desktop without Radio)

Every major game includes an accurate, standalone desktop simulator written in Python (using standard Tkinter, which comes pre-installed with Python on Windows).

### How to run:
Open the `simulators/` folder and double-click the desired launcher:
* **`run_pocketmon_sim.bat`** – Launches Pocketmon: Drone Edition
* **`run_pocket_pet_sim.bat`** – Launches Pocket Pet (Tamagotchi)
* **`run_bad_apple_sim.bat`** – Launches Bad Apple!! PV Player

*Requirements: Python 3.10+ installed from [python.org](https://www.python.org/).*

---

## 🎮 Controls Mapping Guide

| Game Action | RadioMaster Pocket Control | PC Keyboard (Simulator) |
| :--- | :--- | :--- |
| **Movement (Up / Down / Left / Right)** | Left or Right Gimbal (Sticks) | Arrow Keys / `W`, `A`, `S`, `D` |
| **Select / Confirm / Attack / Fire** | Click Roller **`[ENT]`** | **`Enter`** |
| **Back / Cancel / Start Menu** | Return Button **`[RTN]`** | **`Esc`** / **`Backspace`** |
| **Quick Action / Paddock Repair** | Momentary Switch **`[SE]`** | **`Spacebar`** |
| **Mode Toggle / Switch View** | Switch **`[SA]`** / **`[SB]`** | **`Tab`** / **`P`** |

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
│       ├── BADAPPLE/        (badapple.dat, badapple.idx)
│       ├── POCKETMON/       (Config & documentation)
│       └── POCKETPET/       (pet.dat – persistent save)
└── SOUNDS/
    ├── DOOM/                (Gunshots, monster sounds, item pickups)
    ├── MUSIC/               (Tracks, PocketAmp playlist, badapple.wav)
    ├── POCKETPET/           (8-bit retro Tamagotchi chiptunes)
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