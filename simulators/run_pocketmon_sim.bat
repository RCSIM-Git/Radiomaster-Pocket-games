@echo off
title Pocketmon: Drone Edition Simulator
cd /d "%~dp0"
echo ===================================================
echo     POCKETMON: DRONE EDITION (EdgeTX LCD Simulator)
echo ===================================================
echo Controls:
echo   [Arrows / W,A,S,D] : Walk / D-Pad Movement (Gimbals)
echo   [Enter]            : Select / Confirm [ENT]
echo   [Esc / Backspace]  : Cancel / Back / Start Menu [RTN]
echo   [Space]            : Action / Quick Repair [SE]
echo ===================================================
python preview_pocketmon.py
pause
