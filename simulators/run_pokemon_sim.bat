@echo off
title Pokemon Classic 128x64 Simulator
cd /d "%~dp0"
echo ===================================================
echo     POKEMON CLASSIC - EdgeTX 128x64 LCD SIMULATOR
echo ===================================================
echo Controls:
echo   [Arrows / W,A,S,D] : Walk / D-Pad Movement (Gimbals)
echo   [Enter]            : Select / Confirm [ENT]
echo   [Esc / Backspace]  : Cancel / Back / Start Menu [RTN]
echo   [Space]            : Action / Heal Party [SE]
echo ===================================================
python preview_pokemon.py
pause
