import os
import sys
import subprocess
import wave
import struct
import math
import time

SOURCE_VIDEO = "badapple_source.mp4"
OUTPUT_DIR = r"POCKET\SCRIPTS\TOOLS\BADAPPLE"
OUTPUT_DAT = os.path.join(OUTPUT_DIR, "badapple.dat")
OUTPUT_IDX = os.path.join(OUTPUT_DIR, "badapple.idx")
OUTPUT_WAV = r"POCKET\SOUNDS\MUSIC\badapple.wav"

FPS = 20
WIDTH = 88
HEIGHT = 64
SAMPLE_RATE = 32000
SAMPLES_PER_FRAME = SAMPLE_RATE // FPS # 1600 samples

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(os.path.dirname(OUTPUT_WAV), exist_ok=True)

print("=== Step 1: Exporting 32kHz Mono WAV Audio ===")
if not os.path.exists(OUTPUT_WAV):
    cmd_audio = [
        "ffmpeg", "-y", "-i", SOURCE_VIDEO,
        "-vn", "-ar", str(SAMPLE_RATE), "-ac", "1",
        "-c:a", "pcm_s16le", OUTPUT_WAV
    ]
    subprocess.run(cmd_audio, check=True)
    print("Audio exported successfully.")
else:
    print(f"Audio already exists at {OUTPUT_WAV}")

print("\n=== Step 2: Analyzing Audio Spectrum (4 Bands) ===")
w = wave.open(OUTPUT_WAV, "rb")
total_samples = w.getnframes()
raw_audio = w.readframes(total_samples)
w.close()

samples = struct.unpack(f"<{total_samples}h", raw_audio)
num_audio_frames = total_samples // SAMPLES_PER_FRAME
print(f"Total audio samples: {total_samples}, frames: {num_audio_frames}")

# Compute 4-band spectrum per frame:
# Band 0: Sub/Bass (<250Hz) - moving average window 64
# Band 1: Low-Mid (250-1000Hz) - moving average window 16 minus bass
# Band 2: High-Mid (1000-4000Hz) - moving average window 4 minus low-mid
# Band 3: Treble (>4000Hz) - high frequency differences
audio_spectrum = []

for f in range(num_audio_frames):
    chunk = samples[f * SAMPLES_PER_FRAME : (f + 1) * SAMPLES_PER_FRAME]
    if len(chunk) < SAMPLES_PER_FRAME:
        chunk = list(chunk) + [0] * (SAMPLES_PER_FRAME - len(chunk))
    
    # 1. Bass: low pass filter (box filter approx 250Hz at 32kHz is ~64 samples)
    step_bass = 16
    bass_sum = 0
    cnt_bass = 0
    for j in range(0, len(chunk) - step_bass, step_bass):
        avg = sum(chunk[j : j + step_bass]) // step_bass
        bass_sum += avg * avg
        cnt_bass += 1
    bass_val = int(math.sqrt(bass_sum / max(1, cnt_bass)))
    
    # 2. Low-Mid: box filter approx 4 samples minus bass
    step_mid = 4
    mid_sum = 0
    cnt_mid = 0
    for j in range(0, len(chunk) - step_mid, step_mid):
        avg = sum(chunk[j : j + step_mid]) // step_mid
        mid_sum += avg * avg
        cnt_mid += 1
    mid_val = int(math.sqrt(mid_sum / max(1, cnt_mid)))
    low_mid_val = max(0, mid_val - bass_val // 2)
    
    # 3. High-Mid & Treble: differences between adjacent samples
    diff_sum = 0
    diff2_sum = 0
    for j in range(0, len(chunk) - 2, 2):
        d = abs(chunk[j + 1] - chunk[j])
        diff_sum += d * d
        d2 = abs(chunk[j + 2] - 2 * chunk[j + 1] + chunk[j])
        diff2_sum += d2 * d2
    high_mid_val = int(math.sqrt(diff_sum / (len(chunk) // 2)))
    treble_val = int(math.sqrt(diff2_sum / (len(chunk) // 2)))
    
    # Normalize to 0..15
    b0 = min(15, max(0, int(bass_val / 650)))
    b1 = min(15, max(0, int(low_mid_val / 550)))
    b2 = min(15, max(0, int(high_mid_val / 400)))
    b3 = min(15, max(0, int(treble_val / 350)))
    
    audio_spectrum.append((b0, b1, b2, b3))

print(f"Processed audio spectrum for {len(audio_spectrum)} frames.")

print("\n=== Step 3: Extracting & Compressing Video Frames ===")
cmd_video = [
    "ffmpeg", "-y", "-i", SOURCE_VIDEO,
    "-r", str(FPS),
    "-vf", f"scale={WIDTH}:{HEIGHT}",
    "-f", "image2pipe",
    "-pix_fmt", "gray",
    "-vcodec", "rawvideo",
    "-"
]
proc = subprocess.Popen(cmd_video, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

def extract_rectangles(frame_bytes, target_val):
    row_spans = []
    for y in range(HEIGHT):
        spans = []
        in_run = False
        start_x = 0
        row = frame_bytes[y * WIDTH : (y + 1) * WIDTH]
        for x in range(WIDTH):
            val = (row[x] >= 128) == target_val
            if val and not in_run:
                in_run = True
                start_x = x
            elif not val and in_run:
                in_run = False
                spans.append((start_x, x - 1))
        if in_run:
            spans.append((start_x, WIDTH - 1))
        row_spans.append(spans)
    
    active_rects = []
    finished_rects = []
    for y in range(HEIGHT):
        spans = row_spans[y]
        new_active = []
        matched_spans = set()
        for r in active_rects:
            rx1, rx2, ry1, ry2 = r
            found = False
            for idx, (sx1, sx2) in enumerate(spans):
                if idx not in matched_spans and sx1 == rx1 and sx2 == rx2:
                    found = True
                    matched_spans.add(idx)
                    new_active.append((rx1, rx2, ry1, y))
                    break
            if not found:
                finished_rects.append(r)
        for idx, (sx1, sx2) in enumerate(spans):
            if idx not in matched_spans:
                new_active.append((sx1, sx2, y, y))
        active_rects = new_active
    finished_rects.extend(active_rects)
    
    # Return as list of (x, y, w, h)
    return [(rx1, ry1, rx2 - rx1 + 1, ry2 - ry1 + 1) for rx1, rx2, ry1, ry2 in finished_rects]

frames_data = [] # list of bytes
index_entries = [] # list of (offset, length, a1, a2)

current_offset = 0
frame_idx = 0

t_start = time.time()
while True:
    buf = proc.stdout.read(WIDTH * HEIGHT)
    if not buf or len(buf) < WIDTH * HEIGHT:
        break
    
    rects_white = extract_rectangles(buf, True)
    rects_black = extract_rectangles(buf, False)
    
    if len(rects_white) <= len(rects_black):
        chosen_rects = rects_white
        bg = 0 # Black background, draw white shapes
    else:
        chosen_rects = rects_black
        bg = 1 # White background, draw black shapes
        
    num_rects = min(255, len(chosen_rects))
    
    # Frame payload: [bg: 1 byte, num_rects: 1 byte, (x, y, w, h) * num_rects: 4 bytes each]
    payload = bytearray([bg, num_rects])
    for r in chosen_rects[:num_rects]:
        payload.extend([r[0], r[1], r[2], r[3]])
        
    frame_bytes = bytes(payload)
    frame_len = len(frame_bytes)
    
    # Audio spectrum for this frame
    if frame_idx < len(audio_spectrum):
        b0, b1, b2, b3 = audio_spectrum[frame_idx]
    else:
        b0, b1, b2, b3 = (0, 0, 0, 0)
    
    a1 = (b0 << 4) | (b1 & 0x0F)
    a2 = (b2 << 4) | (b3 & 0x0F)
    
    index_entries.append((current_offset, frame_len, a1, a2))
    frames_data.append(frame_bytes)
    
    current_offset += frame_len
    frame_idx += 1
    
    if frame_idx % 500 == 0:
        print(f"Encoded {frame_idx} frames...")

proc.wait()
total_frames = frame_idx
duration_sec = total_frames // FPS
print(f"Encoding complete in {time.time() - t_start:.2f}s! Total frames: {total_frames} ({duration_sec}s)")

print("\n=== Step 4: Writing BADAPPLE.DAT and BADAPPLE.IDX ===")
with open(OUTPUT_DAT, "wb") as f_dat:
    for fbytes in frames_data:
        f_dat.write(fbytes)
dat_size = os.path.getsize(OUTPUT_DAT)
print(f"Wrote {OUTPUT_DAT} ({dat_size / 1024:.1f} KB)")

# Index Header:
# 0..3: "BAPL"
# 4: Version (1)
# 5: FPS (20)
# 6: Width (88)
# 7: Height (64)
# 8..9: TotalFrames (uint16)
# 10..11: DurationSec (uint16)
# 12..15: 4 bytes reserved
with open(OUTPUT_IDX, "wb") as f_idx:
    header = struct.pack("<4sBBBBHH4s", b"BAPL", 1, FPS, WIDTH, HEIGHT, total_frames, duration_sec, b"\x00"*4)
    f_idx.write(header)
    
    # Entries: 8 bytes each
    # offset (uint32), length (uint16), a1 (uint8), a2 (uint8)
    for offset, length, a1, a2 in index_entries:
        entry = struct.pack("<IHBB", offset, length, a1, a2)
        f_idx.write(entry)

idx_size = os.path.getsize(OUTPUT_IDX)
print(f"Wrote {OUTPUT_IDX} ({idx_size / 1024:.1f} KB)")

print("\n=== All Bad Apple assets generated successfully! ===")
