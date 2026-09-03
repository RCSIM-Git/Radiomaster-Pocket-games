"""
Desktop Simulator / Previewer for Bad Apple on EdgeTX (RadioMaster Pocket)
Simulates the 128x64 monochrome LCD display, 20 FPS video streaming,
and the real-time 4-band hardware audio spectrum analyzer.
"""

import os
import sys
import time
import struct
import tkinter as tk

def find_asset(rel_path):
    base_dirs = [
        os.getcwd(),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..")),
        os.path.dirname(__file__),
    ]
    for b in base_dirs:
        p1 = os.path.join(b, rel_path)
        if os.path.exists(p1):
            return p1
        p2 = os.path.join(b, "POCKET", rel_path)
        if os.path.exists(p2):
            return p2
    return rel_path

DAT_PATH = find_asset(os.path.join("SCRIPTS", "TOOLS", "BADAPPLE", "badapple.dat"))
IDX_PATH = find_asset(os.path.join("SCRIPTS", "TOOLS", "BADAPPLE", "badapple.idx"))
WAV_PATH = find_asset(os.path.join("SOUNDS", "MUSIC", "badapple.wav"))

SCALE = 6  # 128x64 * 6 = 768x384 window
WIDTH = 128
HEIGHT = 64
OFFSET_X = 20
VID_W = 88
FPS = 20

class BadAppleSimulator:
    def __init__(self, root):
        self.root = root
        self.root.title("Bad Apple!! (EdgeTX Pocket Simulator - 128x64 LCD)")
        self.root.resizable(False, False)

        # LCD colors: retro greenish-white backlight with dark pixels
        self.BG_COLOR = "#9EAE82"  # EdgeTX Monochrome LCD clear pixel
        self.PIXEL_COLOR = "#121A0E"  # EdgeTX Monochrome LCD active pixel

        self.canvas = tk.Canvas(
            root,
            width=WIDTH * SCALE,
            height=HEIGHT * SCALE,
            bg=self.BG_COLOR,
            highlightthickness=0
        )
        self.canvas.pack()

        self.status_label = tk.Label(
            root,
            text="Space: Play/Pause | F: Toggle Fullscreen | Left/Right: Seek 5s | Esc: Exit",
            bg="#222",
            fg="#CCC",
            font=("Consolas", 10)
        )
        self.status_label.pack(fill=tk.X)

        self.mode_theater = True
        self.invert = False
        self.is_playing = True
        self.current_frame = 0
        self.total_frames = 4384
        self.start_time = time.time()
        self.pause_offset = 0
        self.pause_start = 0

        self.peaks = [0, 0, 0, 0]

        # Load files
        if not os.path.exists(DAT_PATH) or not os.path.exists(IDX_PATH):
            print(f"Error: Missing binary files {DAT_PATH} or {IDX_PATH}")
            sys.exit(1)

        self.f_idx = open(IDX_PATH, "rb")
        self.f_dat = open(DAT_PATH, "rb")

        # Read header
        header = self.f_idx.read(16)
        magic, ver, fps, w, h, frames, dur = struct.unpack("<4sBBBBHH", header[:12])
        self.total_frames = frames
        self.duration = dur

        # Bind keys
        root.bind("<space>", self.toggle_play)
        root.bind("<f>", self.toggle_mode)
        root.bind("<F>", self.toggle_mode)
        root.bind("<i>", self.toggle_invert)
        root.bind("<Left>", lambda e: self.seek(-5))
        root.bind("<Right>", lambda e: self.seek(5))
        root.bind("<Escape>", lambda e: root.destroy())

        # Try playing audio in background if winsound is available
        try:
            import winsound
            winsound.PlaySound(WAV_PATH, winsound.SND_FILENAME | winsound.SND_ASYNC)
        except Exception:
            pass

        self.update_loop()

    def toggle_play(self, event=None):
        now = time.time()
        if self.is_playing:
            self.is_playing = False
            self.pause_start = now
            try:
                import winsound
                winsound.PlaySound(None, winsound.SND_PURGE)
            except Exception:
                pass
        else:
            self.is_playing = True
            self.pause_offset += (now - self.pause_start)
            try:
                import winsound
                winsound.PlaySound(WAV_PATH, winsound.SND_FILENAME | winsound.SND_ASYNC)
            except Exception:
                pass

    def toggle_mode(self, event=None):
        self.mode_theater = not self.mode_theater

    def toggle_invert(self, event=None):
        self.invert = not self.invert

    def seek(self, seconds):
        delta = seconds * FPS
        self.current_frame = max(0, min(self.total_frames - 1, self.current_frame + delta))
        self.start_time = time.time() - (self.current_frame / FPS) - self.pause_offset

    def update_loop(self):
        if self.is_playing:
            now = time.time()
            elapsed = now - self.start_time - self.pause_offset
            target_frame = int(elapsed * FPS)

            if target_frame >= self.total_frames:
                self.is_playing = False
                target_frame = self.total_frames - 1

            if target_frame != self.current_frame:
                self.current_frame = target_frame
                self.render_frame(self.current_frame)
        else:
            self.render_frame(self.current_frame)

        self.root.after(20, self.update_loop)

    def render_frame(self, frame_idx):
        if frame_idx < 0 or frame_idx >= self.total_frames:
            return

        # Read index entry: 16 bytes header + 8 bytes * frame_idx
        self.f_idx.seek(16 + frame_idx * 8)
        entry = self.f_idx.read(8)
        if len(entry) < 8:
            return
        offset, length, a1, a2 = struct.unpack("<IHBB", entry)

        # Read payload from dat
        self.f_dat.seek(offset)
        payload = self.f_dat.read(length)
        if len(payload) < 2:
            return

        bg = payload[0]
        num_rects = payload[1]

        if self.invert:
            bg = 1 - bg

        # Audio spectrum (0..15)
        b0 = a1 >> 4
        b1 = a1 & 0x0F
        b2 = a2 >> 4
        b3 = a2 & 0x0F
        spectrum = [b0, b1, b2, b3]

        for i in range(4):
            if spectrum[i] >= self.peaks[i]:
                self.peaks[i] = spectrum[i]
            else:
                self.peaks[i] = max(0, self.peaks[i] - 0.5)

        self.canvas.delete("all")

        # Palette
        col_dark = self.PIXEL_COLOR
        col_light = self.BG_COLOR

        if self.mode_theater:
            # 4:3 Theater Mode
            # Viewport background
            vp_bg = col_dark if bg == 0 else col_light
            rect_color = col_light if bg == 0 else col_dark

            self.canvas.create_rectangle(
                OFFSET_X * SCALE, 0,
                (OFFSET_X + VID_W) * SCALE, HEIGHT * SCALE,
                fill=vp_bg, outline=vp_bg
            )

            # Draw rectangles
            p = 2
            for _ in range(num_rects):
                if p + 4 > len(payload):
                    break
                rx, ry, rw, rh = payload[p : p + 4]
                p += 4
                x1 = (rx + OFFSET_X) * SCALE
                y1 = ry * SCALE
                x2 = (rx + OFFSET_X + rw) * SCALE
                y2 = (ry + rh) * SCALE
                self.canvas.create_rectangle(x1, y1, x2, y2, fill=rect_color, outline=rect_color)

            # Dividers
            self.canvas.create_line(
                (OFFSET_X - 1) * SCALE, 0,
                (OFFSET_X - 1) * SCALE, HEIGHT * SCALE,
                fill=col_dark, width=2
            )
            self.canvas.create_line(
                (OFFSET_X + VID_W) * SCALE, 0,
                (OFFSET_X + VID_W) * SCALE, HEIGHT * SCALE,
                fill=col_dark, width=2
            )

            # Left Sidebar: Status & Equalizer
            status_text = "▶" if self.is_playing else "❚❚"
            self.canvas.create_text(
                10 * SCALE, 5 * SCALE,
                text=status_text, fill=col_dark, font=("Consolas", int(9 * SCALE / 6), "bold")
            )

            # 4-Band VU Bars
            eq_base = 48
            bar_x = [2, 6, 10, 14]
            self.canvas.create_line(1 * SCALE, (eq_base + 1) * SCALE, 17 * SCALE, (eq_base + 1) * SCALE, fill=col_dark)

            for b in range(4):
                bx = bar_x[b]
                h = int(spectrum[b] * 2)
                ph = int(self.peaks[b] * 2)
                if h > 0:
                    self.canvas.create_rectangle(
                        bx * SCALE, (eq_base - h) * SCALE,
                        (bx + 3) * SCALE, eq_base * SCALE,
                        fill=col_dark, outline=col_dark
                    )
                if ph > 0:
                    self.canvas.create_rectangle(
                        bx * SCALE, (eq_base - ph - 1) * SCALE,
                        (bx + 3) * SCALE, (eq_base - ph) * SCALE,
                        fill=col_dark, outline=col_dark
                    )

            self.canvas.create_text(
                9 * SCALE, 58 * SCALE,
                text="20F", fill=col_dark, font=("Consolas", int(8 * SCALE / 6), "bold")
            )

            # Right Sidebar: Time & Progress
            cur_sec = frame_idx // FPS
            m = cur_sec // 60
            s = cur_sec % 60
            self.canvas.create_text(
                117 * SCALE, 5 * SCALE,
                text=f"{m:02d}", fill=col_dark, font=("Consolas", int(8 * SCALE / 6), "bold")
            )
            self.canvas.create_text(
                117 * SCALE, 13 * SCALE,
                text=f"{s:02d}", fill=col_dark, font=("Consolas", int(8 * SCALE / 6), "bold")
            )

            # Progress Bar
            self.canvas.create_rectangle(114 * SCALE, 20 * SCALE, 120 * SCALE, 50 * SCALE, outline=col_dark, width=1)
            prog = frame_idx / max(1, self.total_frames)
            prog_h = int(prog * 28)
            if prog_h > 0:
                self.canvas.create_rectangle(
                    115 * SCALE, (49 - prog_h) * SCALE,
                    119 * SCALE, 49 * SCALE,
                    fill=col_dark, outline=col_dark
                )

            self.canvas.create_text(
                117 * SCALE, 58 * SCALE,
                text="V4", fill=col_dark, font=("Consolas", int(8 * SCALE / 6), "bold")
            )

        else:
            # Fullscreen Mode 128x64
            vp_bg = col_dark if bg == 0 else col_light
            rect_color = col_light if bg == 0 else col_dark

            self.canvas.create_rectangle(0, 0, WIDTH * SCALE, HEIGHT * SCALE, fill=vp_bg, outline=vp_bg)

            p = 2
            for _ in range(num_rects):
                if p + 4 > len(payload):
                    break
                rx, ry, rw, rh = payload[p : p + 4]
                p += 4
                sx = int(rx * 128 / 88)
                sw = max(1, int(rw * 128 / 88 + 0.99))
                x1 = sx * SCALE
                y1 = ry * SCALE
                x2 = (sx + sw) * SCALE
                y2 = (ry + rh) * SCALE
                self.canvas.create_rectangle(x1, y1, x2, y2, fill=rect_color, outline=rect_color)

        if not self.is_playing:
            # Draw Paused badge
            pw = 60 * SCALE
            ph = 14 * SCALE
            px = (WIDTH * SCALE - pw) // 2
            py = 25 * SCALE
            self.canvas.create_rectangle(px, py, px + pw, py + ph, fill=col_light, outline=col_dark, width=2)
            self.canvas.create_text(
                (WIDTH * SCALE) // 2, py + ph // 2,
                text="[ PAUSED ]", fill=col_dark, font=("Consolas", int(10 * SCALE / 6), "bold")
            )

    def __del__(self):
        try:
            self.f_idx.close()
            self.f_dat.close()
        except Exception:
            pass


if __name__ == "__main__":
    root = tk.Tk()
    app = BadAppleSimulator(root)
    root.mainloop()
