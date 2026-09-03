@echo off
chcp 65001 >nul
title Konwerter Audio EdgeTX dla Winamp
echo ==============================================================
echo     EdgeTX Winamp - Konwerter MP3/FLAC/WAV do 32kHz Mono
echo ==============================================================
echo.

if "%~1"=="" (
    python "%~dp0convert_music.py"
) else (
    python "%~dp0convert_music.py" %*
)

echo.
echo Nacisnij dowolny klawisz, aby zakonczyc...
pause >nul
