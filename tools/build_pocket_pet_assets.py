"""
Asset generator for Pocket Pet (RadioMaster Pocket / EdgeTX)
Generates authentic 8-bit retro chiptune sound effects in PCM 16-bit 32kHz Mono WAV format.
"""

import os
import wave
import struct
import math

SOUNDS_DIR = os.path.join("POCKET", "SOUNDS", "POCKETPET")
os.makedirs(SOUNDS_DIR, exist_ok=True)

SAMPLE_RATE = 32000

def write_wav(filename, samples):
    filepath = os.path.join(SOUNDS_DIR, filename)
    with wave.open(filepath, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        raw = struct.pack(f"<{len(samples)}h", *samples)
        w.writeframes(raw)
    print(f"Generated: {filepath} ({len(samples)} samples, {len(raw)} bytes)")

def tone_square(freq, duration_sec, volume=0.8, decay=True):
    samples = []
    total = int(SAMPLE_RATE * duration_sec)
    for i in range(total):
        t = i / SAMPLE_RATE
        vol = volume * (max(0.05, 1.0 - (t / duration_sec)) if decay else 1.0)
        phase = (i * freq / SAMPLE_RATE) % 1.0
        val = 20000 * vol if phase < 0.5 else -20000 * vol
        samples.append(int(val))
    return samples

def tone_sweep(f_start, f_end, duration_sec, volume=0.8):
    samples = []
    total = int(SAMPLE_RATE * duration_sec)
    phase = 0.0
    for i in range(total):
        t = i / total
        freq = f_start + (f_end - f_start) * t
        phase = (phase + freq / SAMPLE_RATE) % 1.0
        vol = volume * (1.0 - (i / total) * 0.5)
        val = 20000 * vol if phase < 0.5 else -20000 * vol
        samples.append(int(val))
    return samples

def tone_noise(duration_sec, volume=0.5):
    import random
    samples = []
    total = int(SAMPLE_RATE * duration_sec)
    for i in range(total):
        t = i / total
        vol = volume * (1.0 - t)
        val = int((random.random() * 2 - 1) * 20000 * vol)
        samples.append(val)
    return samples

def silence(duration_sec):
    return [0] * int(SAMPLE_RATE * duration_sec)

print("=== Generating 8-bit Virtual Pet Sound Effects ===")

# 1. BEEP (Classic retro alert double-beep: 1046Hz, 1500Hz)
beep = (
    tone_square(1046, 0.08, volume=0.7) +
    silence(0.04) +
    tone_square(1568, 0.12, volume=0.8)
)
write_wav("beep.wav", beep)

# 2. HAPPY (Ascending cheerful arpeggio: C6, E6, G6, C7)
happy = (
    tone_square(1046, 0.06, volume=0.7) +
    tone_square(1318, 0.06, volume=0.7) +
    tone_square(1568, 0.06, volume=0.7) +
    tone_square(2093, 0.15, volume=0.8)
)
write_wav("happy.wav", happy)

# 3. EAT (Munch crunch crunch: quick pitch drop & noise)
eat = []
for _ in range(3):
    eat.extend(tone_sweep(400, 150, 0.04, volume=0.7) + tone_noise(0.03, volume=0.4) + silence(0.04))
write_wav("eat.wav", eat)

# 4. WIN (Victory jingle: G5, C6, E6, G6 - sustained)
win = (
    tone_square(784, 0.09, volume=0.7) +
    tone_square(1046, 0.09, volume=0.7) +
    tone_square(1318, 0.09, volume=0.7) +
    tone_square(1568, 0.25, volume=0.85)
)
write_wav("win.wav", win)

# 5. HATCH (Egg hatching triumph: rising trills & fanfare)
hatch = []
for f in [523, 659, 784, 1046, 1318, 1568, 2093]:
    hatch.extend(tone_square(f, 0.05, volume=0.75))
hatch.extend(tone_square(2093, 0.25, volume=0.9))
write_wav("hatch.wav", hatch)

# 6. CLEAN (Water shower / splash sound)
clean = (
    tone_noise(0.08, volume=0.5) +
    tone_sweep(800, 300, 0.08, volume=0.6) +
    tone_noise(0.12, volume=0.6) +
    tone_sweep(600, 200, 0.10, volume=0.4)
)
write_wav("clean.wav", clean)

# 7. SICK (Sad warning low pitch drop: 300Hz -> 120Hz)
sick = (
    tone_sweep(320, 140, 0.20, volume=0.7) +
    silence(0.05) +
    tone_sweep(280, 110, 0.25, volume=0.7)
)
write_wav("sick.wav", sick)

# 8. CATCH (Coin / battery catch in mini-game)
catch = tone_square(1568, 0.04, volume=0.7) + tone_square(2093, 0.08, volume=0.8)
write_wav("catch.wav", catch)

# 9. HURT (Bomb / glitch hit in mini-game)
hurt = tone_noise(0.12, volume=0.8) + tone_sweep(200, 80, 0.10, volume=0.6)
write_wav("hurt.wav", hurt)

print("\nAll 9 audio assets generated successfully in POCKET/SOUNDS/POCKETPET/")
