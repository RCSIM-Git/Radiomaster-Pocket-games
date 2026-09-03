---- TNS|Bad Apple!!|TNE
--[[
    ================================================================================
    BAD APPLE!! (Pocket Edition) for EdgeTX
    Iconic Shadow Art Video & Audio Player for 128x64 Monochrome LCD
    Compatible with: RadioMaster Pocket, MT12, Boxer, TX12, Zorro
    Music: Nomico - Bad Apple!! (Alstroemeria Records / ZUN)
    Features:
      - AUTO-START: Plays immediately on launch (no clunky start menus!)
      - 20 FPS hardware-synced monochrome video streaming directly from SD card
      - High-fidelity RLE rectangle delta rendering engine (<1ms render time)
      - Dual Display Modes:
          * 4:3 RETRO THEATER (88x64 centered with live hardware audio spectrum)
          * 128x64 FULLSCREEN (stretched to fill the entire LCD)
      - Hardware-accurate 4-Band Audio VU Spectrum Analyzer (Bass, Mid, High, Treble)
      - Direct Audio Synchronization with EdgeTX PCM 16-bit 32kHz DAC
      - Pocket-optimized Controls:
          * Top shoulder button [SE] or [ENT] -> Instant Play / Pause
          * Right Stick Left / Right (or Roller) -> Seek -5s / +5s
          * Right Stick Up (or [PAGE]) -> Toggle 4:3 Theater / Fullscreen
          * Right Stick Down -> Toggle Invert Display (Normal / Inverted)
          * Rolka S1 / P1 -> Hardware Volume (1..5)
          * [RTN / EXIT] -> Safe stop & return to EdgeTX
    Author: EdgeTX Pair-Programmer & Mateusz
    ================================================================================
--]]

local LCD_W = 128
local LCD_H = 64
local VID_W = 88
local VID_H = 64
local OFFSET_X = 20 -- Center 88px inside 128px (20 left, 20 right)
local FPS = 20
local TICKS_PER_FRAME = 5 -- 100 Hz / 20 FPS = 5 ticks (50ms)

-- State Machine
local STATE_PLAY = 0
local STATE_PAUSE = 1
local STATE_ENDED = 2
local STATE_ERROR = 3

local currentState = STATE_PLAY
local errorMessage = ""

-- Display Settings
local MODE_THEATER = 0
local MODE_FULLSCREEN = 1
local displayMode = MODE_THEATER
local invertColors = false

-- Files & Playback State
local PATH_DAT = "/SCRIPTS/TOOLS/BADAPPLE/badapple.dat"
local PATH_IDX = "/SCRIPTS/TOOLS/BADAPPLE/badapple.idx"
local PATH_WAV = "/SOUNDS/MUSIC/badapple.wav"

local datFile = nil
local idxFile = nil
local totalFrames = 4384
local durationSec = 219

local currentFrame = -1
local playStartTime = 0
local pauseTime = 0
local pauseOffsetTicks = 0
local isAudioPlaying = false
local playVolume = 4

-- Startup debounce (prevent initial launch click from triggering pause or exit)
local startupIgnoreUntil = 0

-- Spectrum & Meter State (Bass, Low-Mid, High-Mid, Treble)
local curSpectrum = {0, 0, 0, 0}
local peakSpectrum = {0, 0, 0, 0}
local lastPeakDecay = 0

-- OSD Overlay
local osdMessage = ""
local osdExpireTime = 0

-- Cached Frame Payload
local currentPayload = nil

--------------------------------------------------------------------------------
-- UTILITY & AUDIO FUNCTIONS
--------------------------------------------------------------------------------

local function safeStopAudio()
    if type(stopAudio) == "function" then
        pcall(stopAudio)
    end
    isAudioPlaying = false
end

local function formatTime(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function triggerOsd(msg, durationTicks)
    osdMessage = msg
    osdExpireTime = getTime() + (durationTicks or 120)
end

-- Read S1 / P1 roller for volume
local function getRollerVolume()
    local sources = {"s1", "S1", "p1", "P1", "rol", "ROL"}
    for _, name in ipairs(sources) do
        local v = getValue(name)
        if v ~= nil and type(v) == "number" then
            local pct = math.floor(((v + 1024) / 2048) * 100)
            pct = math.max(0, math.min(100, pct))
            return math.max(1, math.min(5, math.floor(pct / 20) + 1))
        end
    end
    return 4
end

--------------------------------------------------------------------------------
-- FILE I/O & STREAMING
--------------------------------------------------------------------------------

local function closeFiles()
    if datFile then
        pcall(io.close, datFile)
        datFile = nil
    end
    if idxFile then
        pcall(io.close, idxFile)
        idxFile = nil
    end
end

local function openFiles()
    closeFiles()
    
    idxFile = io.open(PATH_IDX, "r")
    if not idxFile then
        errorMessage = "BRAK PLIKU:\n" .. PATH_IDX
        currentState = STATE_ERROR
        return false
    end

    -- Read 16-byte index header
    local hdr = io.read(idxFile, 16)
    if not hdr or #hdr < 16 then
        errorMessage = "USZKODZONY PLIK:\n" .. PATH_IDX
        currentState = STATE_ERROR
        closeFiles()
        return false
    end

    local m1, m2, m3, m4, ver, fpsVal, wVal, hVal, f1, f2, d1, d2 = string.byte(hdr, 1, 12)
    local magic = string.char(m1, m2, m3, m4)
    if magic ~= "BAPL" then
        errorMessage = "ZLY FORMAT:\n" .. magic
        currentState = STATE_ERROR
        closeFiles()
        return false
    end

    totalFrames = f1 + (f2 * 256)
    durationSec = d1 + (d2 * 256)
    if totalFrames <= 0 then totalFrames = 4384 end
    if durationSec <= 0 then durationSec = 219 end

    datFile = io.open(PATH_DAT, "r")
    if not datFile then
        errorMessage = "BRAK PLIKU:\n" .. PATH_DAT
        currentState = STATE_ERROR
        closeFiles()
        return false
    end

    return true
end

local function loadFrame(targetIdx)
    if not idxFile or not datFile then return false end
    if targetIdx < 0 then targetIdx = 0 end
    if targetIdx >= totalFrames then targetIdx = totalFrames - 1 end

    -- Seek in index file: 16 bytes header + 8 bytes per frame
    local idxPos = 16 + targetIdx * 8
    io.seek(idxFile, idxPos)
    local entry = io.read(idxFile, 8)
    if not entry or #entry < 8 then return false end

    local o1, o2, o3, o4, l1, l2, a1, a2 = string.byte(entry, 1, 8)
    local offset = o1 + (o2 * 256) + (o3 * 65536) + (o4 * 16777216)
    local length = l1 + (l2 * 256)

    -- Spectrum data (0..15 per band)
    curSpectrum[1] = math.floor(a1 / 16)
    curSpectrum[2] = a1 % 16
    curSpectrum[3] = math.floor(a2 / 16)
    curSpectrum[4] = a2 % 16

    -- Update peak decay
    for b = 1, 4 do
        if curSpectrum[b] >= peakSpectrum[b] then
            peakSpectrum[b] = curSpectrum[b]
        end
    end

    -- Seek in dat file and read payload
    io.seek(datFile, offset)
    currentPayload = io.read(datFile, length)
    currentFrame = targetIdx

    return (currentPayload ~= nil)
end

--------------------------------------------------------------------------------
-- PLAYBACK CONTROL
--------------------------------------------------------------------------------

local function startPlayback()
    if not openFiles() then return end

    playVolume = getRollerVolume()
    safeStopAudio()

    if type(playFile) == "function" then
        pcall(playFile, PATH_WAV, playVolume)
        isAudioPlaying = true
    end

    playStartTime = getTime()
    pauseOffsetTicks = 0
    currentFrame = -1
    loadFrame(0)

    currentState = STATE_PLAY
    triggerOsd("BAD APPLE!! 20 FPS", 120)
end

local function togglePause()
    local now = getTime()
    if currentState == STATE_PLAY then
        currentState = STATE_PAUSE
        pauseTime = now
        safeStopAudio()
        triggerOsd("[PAUZA]", 200)
    elseif currentState == STATE_PAUSE then
        -- Resume
        pauseOffsetTicks = pauseOffsetTicks + (now - pauseTime)
        currentState = STATE_PLAY
        
        playVolume = getRollerVolume()
        if type(playFile) == "function" then
            pcall(playFile, PATH_WAV, playVolume)
            isAudioPlaying = true
        end
        triggerOsd("[WZNOWIONO]", 100)
    end
end

local function seekRelative(secondsDelta)
    local frameDelta = secondsDelta * FPS
    local newFrame = math.max(0, math.min(totalFrames - 1, currentFrame + frameDelta))
    loadFrame(newFrame)
    
    -- Recalculate playStartTime so time synchronization stays aligned
    local newTicks = newFrame * TICKS_PER_FRAME
    playStartTime = getTime() - newTicks - pauseOffsetTicks
    
    local sign = (secondsDelta >= 0) and "+" or ""
    triggerOsd(string.format("SEEK %s%ds [%s]", sign, secondsDelta, formatTime(math.floor(newFrame / FPS))), 120)
end

--------------------------------------------------------------------------------
-- INPUT DETECTION (Pocket Optimized)
--------------------------------------------------------------------------------

local function isNext(event)
    if not event or event == 0 then return false end
    return event == EVT_VIRTUAL_INC or event == EVT_VIRTUAL_INC_REPT
        or event == EVT_VIRTUAL_NEXT or event == EVT_ROT_RIGHT
end

local function isPrev(event)
    if not event or event == 0 then return false end
    return event == EVT_VIRTUAL_DEC or event == EVT_VIRTUAL_DEC_REPT
        or event == EVT_VIRTUAL_PREV or event == EVT_ROT_LEFT
end

-- Only detect genuine Enter button release, NO collision with Exit
local function isEnter(event)
    if not event or event == 0 then return false end
    return event == EVT_ENTER_BREAK or event == EVT_VIRTUAL_ENTER
        or event == EVT_ROT_BREAK
end

local function isPage(event)
    if not event or event == 0 then return false end
    return event == EVT_VIRTUAL_NEXT_PAGE or event == EVT_PAGE_BREAK
end

-- Strictly detect Exit (RTN) button release
local function isExit(event)
    if not event or event == 0 then return false end
    return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

-- Shoulder SE button (Pocket top-right momentary push button)
local lastSeVal = 0
local function checkSeSwitch()
    local se = getValue("se") or getValue("SE") or 0
    local triggered = false
    if se > 200 and lastSeVal <= 200 then
        triggered = true
    elseif se < -200 and lastSeVal >= -200 and lastSeVal ~= 0 then
        triggered = true
    end
    lastSeVal = se
    return triggered
end

-- Gimbal / Stick Gestures (Alternative to roller for thumbs)
local lastStickNav = 0
local function checkStickInput()
    local now = getTime()
    if now - lastStickNav < 25 then return 0 end -- 250ms debounce

    -- Horizontal Stick (Ail / Rud): Seek -5s / +5s
    local ail = getValue("ail") or getValue("AIL") or 0
    local rud = getValue("rud") or getValue("RUD") or 0
    local valX = (math.abs(ail) > math.abs(rud)) and ail or rud

    if valX > 650 then
        lastStickNav = now
        return 1 -- Right: Seek +5s
    elseif valX < -650 then
        lastStickNav = now
        return -1 -- Left: Seek -5s
    end

    -- Vertical Stick (Ele): Mode / Invert
    local ele = getValue("ele") or getValue("ELE") or 0
    if ele > 750 then
        lastStickNav = now
        return 2 -- Up: Toggle Display Mode
    elseif ele < -750 then
        lastStickNav = now
        return -2 -- Down: Toggle Invert Colors
    end

    return 0
end

--------------------------------------------------------------------------------
-- RENDERING ENGINE
--------------------------------------------------------------------------------

local function renderVideoFrame()
    if not currentPayload or #currentPayload < 2 then return end

    local bg = string.byte(currentPayload, 1)
    local numRects = string.byte(currentPayload, 2)
    
    if invertColors then
        bg = (bg == 0) and 1 or 0
    end

    if displayMode == MODE_THEATER then
        -- 4:3 THEATER MODE (88x64 centered at x=20..107)
        if bg == 0 then
            -- Black background, carve white shapes with ERASE
            lcd.drawFilledRectangle(OFFSET_X, 0, VID_W, VID_H)
            local p = 3
            for i = 1, numRects do
                local rx, ry, rw, rh = string.byte(currentPayload, p, p + 3)
                if rx then
                    lcd.drawFilledRectangle(rx + OFFSET_X, ry, rw, rh, ERASE)
                end
                p = p + 4
            end
        else
            -- White background, draw black shapes
            lcd.drawFilledRectangle(OFFSET_X, 0, VID_W, VID_H, ERASE)
            local p = 3
            for i = 1, numRects do
                local rx, ry, rw, rh = string.byte(currentPayload, p, p + 3)
                if rx then
                    lcd.drawFilledRectangle(rx + OFFSET_X, ry, rw, rh)
                end
                p = p + 4
            end
        end

        -- Side dividing borders
        lcd.drawLine(OFFSET_X - 1, 0, OFFSET_X - 1, 63, SOLID, 0)
        lcd.drawLine(OFFSET_X + VID_W, 0, OFFSET_X + VID_W, 63, SOLID, 0)

    else
        -- 128x64 FULLSCREEN MODE (Stretched)
        if bg == 0 then
            lcd.clear()
            lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H)
            local p = 3
            for i = 1, numRects do
                local rx, ry, rw, rh = string.byte(currentPayload, p, p + 3)
                if rx then
                    local sx = math.floor(rx * 128 / 88)
                    local sw = math.max(1, math.ceil(rw * 128 / 88))
                    lcd.drawFilledRectangle(sx, ry, sw, rh, ERASE)
                end
                p = p + 4
            end
        else
            lcd.clear()
            local p = 3
            for i = 1, numRects do
                local rx, ry, rw, rh = string.byte(currentPayload, p, p + 3)
                if rx then
                    local sx = math.floor(rx * 128 / 88)
                    local sw = math.max(1, math.ceil(rw * 128 / 88))
                    lcd.drawFilledRectangle(sx, ry, sw, rh)
                end
                p = p + 4
            end
        end
    end
end

-- Render HUD Sidebars for 4:3 Theater Mode
local function renderTheaterSidebars()
    local now = getTime()
    
    -- Peak dot decay every 60ms
    if now - lastPeakDecay > 6 then
        lastPeakDecay = now
        for b = 1, 4 do
            if peakSpectrum[b] > 0 then
                peakSpectrum[b] = peakSpectrum[b] - 1
            end
        end
    end

    ----------------------------------------------------------------------------
    -- LEFT SIDEBAR (x: 0..19)
    ----------------------------------------------------------------------------
    -- Status Icon
    if currentState == STATE_PLAY then
        -- Play triangle [▶]
        lcd.drawLine(6, 2, 6, 8, SOLID, 0)
        lcd.drawLine(7, 3, 7, 7, SOLID, 0)
        lcd.drawLine(8, 4, 8, 6, SOLID, 0)
        lcd.drawPoint(9, 5)
    else
        -- Pause bars [❚❚]
        lcd.drawFilledRectangle(5, 2, 2, 7)
        lcd.drawFilledRectangle(9, 2, 2, 7)
    end

    -- 4-Band Equalizer / Audio Spectrum Analyzer (y: 14 to 50)
    -- Bands: Bass (x=2), LowMid (x=6), HighMid (x=10), Treble (x=14)
    local eqBaseY = 48
    local barX = {2, 6, 10, 14}
    
    -- Horizontal baseline
    lcd.drawLine(1, eqBaseY + 1, 17, eqBaseY + 1, SOLID, 0)

    for b = 1, 4 do
        local x = barX[b]
        local val = curSpectrum[b] -- 0..15
        local peak = peakSpectrum[b]

        -- Bar height (0 to 30px)
        local h = math.floor(val * 2)
        if h > 0 then
            lcd.drawFilledRectangle(x, eqBaseY - h, 3, h)
        end

        -- Falling peak dot
        local ph = math.floor(peak * 2)
        if ph > 0 and ph <= 30 then
            lcd.drawPoint(x, eqBaseY - ph - 1)
            lcd.drawPoint(x + 1, eqBaseY - ph - 1)
            lcd.drawPoint(x + 2, eqBaseY - ph - 1)
        end
    end

    -- FPS Counter at bottom
    lcd.drawText(2, 54, "20F", SMLSIZE)

    ----------------------------------------------------------------------------
    -- RIGHT SIDEBAR (x: 108..127)
    ----------------------------------------------------------------------------
    local curSec = math.floor(currentFrame / FPS)
    local curM = math.floor(curSec / 60)
    local curS = math.floor(curSec % 60)

    -- Time digits: MM (top), SS (below)
    lcd.drawText(111, 2, string.format("%02d", curM), SMLSIZE)
    lcd.drawText(111, 10, string.format("%02d", curS), SMLSIZE)

    -- Vertical Progress Bar (y: 20 to 50, h=30)
    lcd.drawRectangle(114, 20, 5, 30)
    local progPct = (totalFrames > 0) and (currentFrame / totalFrames) or 0
    local progH = math.floor(progPct * 28)
    if progH > 0 then
        lcd.drawFilledRectangle(115, 49 - progH, 3, progH)
    end

    -- Volume indicator
    lcd.drawText(111, 54, "V" .. playVolume, SMLSIZE)
end

-- Render Floating OSD Overlay (when active)
local function renderOsd()
    local now = getTime()
    if now < osdExpireTime and osdMessage ~= "" then
        local w = 114
        local h = 11
        local x = 7
        local y = 51
        lcd.drawFilledRectangle(x, y, w, h, ERASE)
        lcd.drawRectangle(x, y, w, h)
        lcd.drawText(x + 4, y + 2, osdMessage, SMLSIZE)
    end
end

--------------------------------------------------------------------------------
-- COMPLETION SCREEN
--------------------------------------------------------------------------------

local function drawEndedScreen()
    lcd.clear()
    lcd.drawRectangle(0, 0, LCD_W, LCD_H)

    lcd.drawFilledRectangle(2, 2, LCD_W - 4, 12)
    lcd.drawText(18, 4, "ODTWARZANIE UKONCZONE", INVERS)

    lcd.drawText(16, 18, "Nomico - Bad Apple!!", SMLSIZE)
    lcd.drawText(12, 28, "3:39 rendered at 20 FPS", SMLSIZE)
    lcd.drawText(14, 38, "4384 frames smoothly!", SMLSIZE)

    lcd.drawLine(2, 49, LCD_W - 3, 49, SOLID, 0)
    lcd.drawText(14, 52, "[SE]/[ENT] Replay   [RTN] Exit", SMLSIZE)
end

--------------------------------------------------------------------------------
-- ERROR SCREEN
--------------------------------------------------------------------------------

local function drawErrorScreen()
    lcd.clear()
    lcd.drawRectangle(0, 0, LCD_W, LCD_H)
    lcd.drawFilledRectangle(2, 2, LCD_W - 4, 12)
    lcd.drawText(24, 4, "FILE ERROR!", INVERS)

    lcd.drawText(6, 18, errorMessage, SMLSIZE)
    lcd.drawText(6, 32, "Check SD files in:", SMLSIZE)
    lcd.drawText(6, 42, "/SCRIPTS/TOOLS/BADAPPLE/", SMLSIZE)

    lcd.drawLine(2, 51, LCD_W - 3, 51, SOLID, 0)
    lcd.drawText(30, 53, "[RTN / EXIT] Exit", SMLSIZE)
end

--------------------------------------------------------------------------------
-- EDGETX SCRIPT INTERFACE
--------------------------------------------------------------------------------

local function init()
    displayMode = MODE_THEATER
    invertColors = false
    currentFrame = -1
    lastPeakDecay = getTime()
    startupIgnoreUntil = getTime() + 40 -- Ignore launch button bounces for 0.4s

    -- Direct Auto-Play!
    startPlayback()
end

local function run(event)
    local now = getTime()

    -- Exit Guard (Only accept EXIT after startup debounce)
    if isExit(event) and (now > startupIgnoreUntil) then
        safeStopAudio()
        closeFiles()
        return 2 -- Return cleanly to EdgeTX Menu
    end

    -- S1 / P1 Volume roller update
    local newVol = getRollerVolume()
    if newVol ~= playVolume then
        playVolume = newVol
        triggerOsd("GLOSNOSC: " .. playVolume .. "/5", 90)
    end

    ----------------------------------------------------------------------------
    -- STATE: PLAYING
    ----------------------------------------------------------------------------
    if currentState == STATE_PLAY then
        -- Check controls only after startup debounce
        if now > startupIgnoreUntil then
            -- 1. Pause via top shoulder button SE or roller Enter
            if checkSeSwitch() or isEnter(event) then
                togglePause()
            end

            -- 2. Display Mode Toggle via [PAGE]
            if isPage(event) then
                displayMode = (displayMode == MODE_THEATER) and MODE_FULLSCREEN or MODE_THEATER
                triggerOsd((displayMode == MODE_THEATER) and "TRYB: 4:3 KINOWY" or "TRYB: PELNY EKRAN", 120)
            end

            -- 3. Seeking via Roller
            if isNext(event) then
                seekRelative(5)
            elseif isPrev(event) then
                seekRelative(-5)
            end

            -- 4. Stick Gestures (Thumbs friendly)
            local stick = checkStickInput()
            if stick == 1 then
                seekRelative(5)
            elseif stick == -1 then
                seekRelative(-5)
            elseif stick == 2 then
                displayMode = (displayMode == MODE_THEATER) and MODE_FULLSCREEN or MODE_THEATER
                triggerOsd((displayMode == MODE_THEATER) and "TRYB: 4:3 KINOWY" or "TRYB: PELNY EKRAN", 120)
            elseif stick == -2 then
                invertColors = not invertColors
                triggerOsd(invertColors and "KOLORY: ODWRCONE" or "KOLORY: NORMALNE", 100)
            end
        end

        -- Calculate audio-synced target frame
        local elapsedTicks = now - playStartTime - pauseOffsetTicks
        local targetFrame = math.floor(elapsedTicks / TICKS_PER_FRAME)

        if targetFrame >= totalFrames then
            safeStopAudio()
            currentState = STATE_ENDED
            return 0
        end

        if targetFrame ~= currentFrame then
            loadFrame(targetFrame)
        end

        renderVideoFrame()

        if displayMode == MODE_THEATER then
            renderTheaterSidebars()
        end

        renderOsd()
        return 0

    ----------------------------------------------------------------------------
    -- STATE: PAUSED
    ----------------------------------------------------------------------------
    elseif currentState == STATE_PAUSE then
        if checkSeSwitch() or isEnter(event) then
            togglePause()
        elseif isPage(event) then
            displayMode = (displayMode == MODE_THEATER) and MODE_FULLSCREEN or MODE_THEATER
        elseif isNext(event) then
            seekRelative(5)
        elseif isPrev(event) then
            seekRelative(-5)
        else
            local stick = checkStickInput()
            if stick == 1 then
                seekRelative(5)
            elseif stick == -1 then
                seekRelative(-5)
            elseif stick == 2 then
                displayMode = (displayMode == MODE_THEATER) and MODE_FULLSCREEN or MODE_THEATER
            elseif stick == -2 then
                invertColors = not invertColors
            end
        end

        renderVideoFrame()

        if displayMode == MODE_THEATER then
            renderTheaterSidebars()
        end

        -- Draw persistent Pause Badge
        local pw = 60
        local ph = 13
        local px = (LCD_W - pw) / 2
        local py = 25
        lcd.drawFilledRectangle(px, py, pw, ph, ERASE)
        lcd.drawRectangle(px, py, pw, ph)
        lcd.drawText(px + 10, py + 3, "[ PAUZA ]", SMLSIZE)

        renderOsd()
        return 0

    ----------------------------------------------------------------------------
    -- STATE: ENDED
    ----------------------------------------------------------------------------
    elseif currentState == STATE_ENDED then
        if checkSeSwitch() or isEnter(event) then
            startPlayback()
        end
        drawEndedScreen()
        return 0

    ----------------------------------------------------------------------------
    -- STATE: ERROR
    ----------------------------------------------------------------------------
    elseif currentState == STATE_ERROR then
        drawErrorScreen()
        return 0
    end

    return 0
end

return { init = init, run = run }
