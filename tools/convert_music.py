"""
EdgeTX Audio Converter for Winamp Lua Player
Konwertuje pliki MP3 / FLAC / M4A / WAV do formatu wymaganego przez EdgeTX:
WAV, 32000 Hz, 16-bit PCM, Mono.
"""

import sys
import os
import subprocess
import shutil

OUTPUT_DIRS = [
    os.path.join(os.path.dirname(__file__), "POCKET", "SOUNDS", "MUSIC"),
    os.path.join(os.path.dirname(__file__), "01.09backup", "SOUNDS", "MUSIC")
]

def ensure_dirs():
    for d in OUTPUT_DIRS:
        os.makedirs(d, exist_ok=True)

def convert_file(input_file):
    if not os.path.exists(input_file):
        print(f"[BLAD] Plik nie istnieje: {input_file}")
        return False

    base_name = os.path.splitext(os.path.basename(input_file))[0]
    # Usun znaki specjalne / spacje na podkreslenia dla bezpieczenstwa FAT32
    safe_name = "".join(c if c.isalnum() or c in "._-" else "_" for c in base_name)
    out_filename = safe_name + ".wav"

    ensure_dirs()
    target_primary = os.path.join(OUTPUT_DIRS[0], out_filename)

    print(f"\n--- Konwersja: {os.path.basename(input_file)} -> {out_filename} ---")
    
    # Komenda ffmpeg: 32000Hz, mono (1 kanal), 16-bit PCM
    cmd = [
        "ffmpeg", "-y",
        "-i", input_file,
        "-vn",
        "-ar", "32000",
        "-ac", "1",
        "-c:a", "pcm_s16le",
        target_primary
    ]

    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode != 0:
            print(f"[BLAD] ffmpeg zwrocil blad:\n{res.stderr[-300:]}")
            return False

        print(f"[OK] Zapisano w: {target_primary}")

        # Kopiuj do drugiego folderu jesli istnieje
        if len(OUTPUT_DIRS) > 1 and os.path.exists(OUTPUT_DIRS[1]):
            shutil.copy2(target_primary, os.path.join(OUTPUT_DIRS[1], out_filename))
            print(f"[OK] Skopiowano do: {OUTPUT_DIRS[1]}")

        # Dodaj do playlist.txt jesli jeszcze tam nie ma
        playlist_path = os.path.join(OUTPUT_DIRS[0], "playlist.txt")
        if os.path.exists(playlist_path):
            with open(playlist_path, "r", encoding="utf-8", errors="ignore") as pf:
                lines = pf.read().splitlines()
            if out_filename not in [l.strip() for l in lines]:
                with open(playlist_path, "a", encoding="utf-8") as pf:
                    pf.write(f"{out_filename}\n")
                print(f"[OK] Dodano '{out_filename}' do playlist.txt")

        return True

    except FileNotFoundError:
        print("[BLAD] Nie znaleziono programu 'ffmpeg' w systemie!")
        return False

def main():
    if len(sys.argv) > 1:
        files = sys.argv[1:]
        success_count = 0
        for f in files:
            if convert_file(f):
                success_count += 1
        print(f"\nUkonczono konwersje {success_count}/{len(files)} plikow.")
    else:
        print("=" * 60)
        print("  EdgeTX Winamp - Konwerter Utworow Audio (32kHz Mono WAV)")
        print("=" * 60)
        print("Wskazowka: Mozesz po prostu przeciagnac pliki MP3 na plik convert_to_edgetx_wav.bat")
        print("lub podac sciezke do pliku ponizej:\n")
        path = input("Podaj sciezke do pliku audio: ").strip().strip('"')
        if path:
            convert_file(path)

if __name__ == "__main__":
    main()
