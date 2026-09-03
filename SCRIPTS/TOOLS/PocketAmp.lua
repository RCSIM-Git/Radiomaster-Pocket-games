---- TNS|PocketAmp Player|TNE
--------------------------------------------------------------------------------
-- POCKETAMP v2.0 FOR EDGETX (128x64 Monochrome LCD)
-- Compatible with: RadioMaster Pocket, RadioMaster MT12, TX12, Boxer, Zorro
-- Features:
--   - Authentic 90s retro desktop player interface
--   - Animated Spectrum Analyzer with falling peak lines
--   - Big LCD segmented timer (MM:SS) & Bitrate / Frequency indicators
--   - Smooth Marquee ticker for track titles
--   - Seek / progress bar with retro thumb
--   - Interactive control buttons: Prev, Play, Pause, Stop, Next, List, Repeat, Shuffle
--   - Full Playlist Editor window with SD card auto-scanning
--   - Hardware audio routing: Built-in speaker OR 3.5mm Headphone Jack (Pocket)
--------------------------------------------------------------------------------
local VIEW_PLAYER = 0
local VIEW_PLAYLIST = 1

local viewMode = VIEW_PLAYER
local tracks = {}
local currentTrack = 1
local isPlaying = false
local isPaused = false
local startTime = 0
local pauseElapsed = 0
local selectedButton = 2 -- Default: Play button
local playlistCursor = 1
local playlistOffset = 0
local repeatMode = 1 -- 0: Off, 1: Repeat All, 2: Repeat One
local shuffleMode = false

-- Spectrum Analyzer state (10 bars)
local NUM_BARS = 10
local spectrumHeights = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local spectrumPeaks = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local lastAnimTick = 0

-- Marquee state
local marqueeText = "POCKETAMP - RETRO AUDIO PLAYER FOR EDGETX"
local marqueeOffset = 0
local lastMarqueeTick = 0

-- Exit safety
local lastExitTime = 0

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

local function formatTime(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

-- Read WAV duration directly from RIFF header
local function getWavDuration(filePath)
    local f = io.open(filePath, "r")
    if not f then return 180 end
    
    local header = io.read(f, 512)
    io.close(f)
    
    if not header or #header < 44 then return 180 end
    if string.sub(header, 1, 4) ~= "RIFF" or string.sub(header, 9, 12) ~= "WAVE" then return 180 end
    
    -- Find "fmt " chunk to get byteRate (sampleRate * channels * bytesPerSample)
    local fmtPos = string.find(header, "fmt ", 1, true)
    local byteRate = 64000
    if fmtPos and #header >= fmtPos + 19 then
        local b1, b2, b3, b4 = string.byte(header, fmtPos + 16, fmtPos + 19)
        byteRate = b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
    end
    
    -- Find "data" chunk to get dataSize
    local dataPos = string.find(header, "data", 1, true)
    if dataPos and #header >= dataPos + 7 then
        local d1, d2, d3, d4 = string.byte(header, dataPos + 4, dataPos + 7)
        local dataSize = d1 + (d2 * 256) + (d3 * 65536) + (d4 * 16777216)
        if byteRate > 0 and dataSize > 0 then
            local dur = math.floor(dataSize / byteRate)
            if dur > 0 then return dur end
        end
    end
    
    return 180
end

-- Scan SD card for audio files
local function scanTracks()
    tracks = {}
    local added = {}
    
    local function addTrack(fname)
        if fname and type(fname) == "string" then
            if string.lower(string.sub(fname, -4)) == ".wav" then
                local lower = string.lower(fname)
                if not added[lower] then
                    added[lower] = true
                    local title = string.sub(fname, 1, -5)
                    if lower == "llama.wav" then
                        title = "DJ Mike Llama - Llama Whippin' Intro"
                    elseif lower == "pocketamp_intro.wav" then
                        title = "PocketAmp - Chiptune Intro"
                    end
                    tracks[#tracks + 1] = {
                        name = fname,
                        path = "/SOUNDS/MUSIC/" .. fname,
                        title = title,
                        duration = 0
                    }
                end
            end
        end
    end
    
    -- 1. Read playlist.txt first using EdgeTX io.read (preserves user track order)
    local pf = io.open("/SOUNDS/MUSIC/playlist.txt", "r")
    if pf then
        local content = ""
        while true do
            local chunk = io.read(pf, 256)
            if not chunk or #chunk == 0 then break end
            content = content .. chunk
        end
        io.close(pf)
        
        for line in string.gmatch(content, "[^\r\n]+") do
            line = string.gsub(line, "^%s*(.-)%s*$", "%1")
            if #line > 0 and string.sub(line, 1, 1) ~= "#" then
                local fn = line
                if string.lower(string.sub(fn, -4)) ~= ".wav" then fn = fn .. ".wav" end
                addTrack(fn)
            end
        end
    end
    
    -- 2. Scan /SOUNDS/MUSIC using EdgeTX dir() iterator
    if type(dir) == "function" then
        local ok, iter = pcall(dir, "/SOUNDS/MUSIC")
        if ok and type(iter) == "function" then
            for fname in iter do
                if type(fname) == "string" then
                    addTrack(fname)
                end
            end
        end
    end
    
    -- 3. Fallback if no files found
    if #tracks == 0 then
        tracks[#tracks + 1] = {
            name = "llama.wav",
            path = "/SOUNDS/MUSIC/llama.wav",
            title = "DJ Mike Llama - Llama Whippin' Intro",
            duration = 5
        }
    end
    
    -- Cache duration for first track
    if tracks[1] and tracks[1].duration == 0 then
        tracks[1].duration = getWavDuration(tracks[1].path)
    end
end

--------------------------------------------------------------------------------
-- AUDIO ENGINE
--------------------------------------------------------------------------------

local function safeStopAudio()
    if type(stopAudio) == "function" then
        pcall(stopAudio)
    end
end

local function getRollerVolume()
    local sources = {"s1", "S1", "p1", "P1", "rol", "ROL"}
    for _, name in ipairs(sources) do
        local v = getValue(name)
        if v ~= nil and type(v) == "number" then
            local pct = math.floor(((v + 1024) / 2048) * 100)
            if pct < 0 then pct = 0 end
            if pct > 100 then pct = 100 end
            return pct
        end
    end
    return 80
end

local function playTrack(idx)
    if #tracks == 0 then return end
    if idx < 1 then idx = #tracks end
    if idx > #tracks then idx = 1 end
    
    currentTrack = idx
    local trk = tracks[currentTrack]
    
    if trk.duration == 0 or not trk.duration then
        trk.duration = getWavDuration(trk.path)
    end
    
    safeStopAudio()
    
    -- Volume from S1/P1 roller (1 to 5)
    local vPct = getRollerVolume()
    local playVol = math.max(1, math.min(5, math.floor(vPct / 20) + 1))
    playFile(trk.path, playVol)
    
    isPlaying = true
    isPaused = false
    startTime = getTime()
    pauseElapsed = 0
    marqueeOffset = 0
    
    marqueeText = string.format("*** %02d. %s (%s) ***", 
        currentTrack, string.upper(trk.title), formatTime(trk.duration))
end

local function pauseTrack()
    if not isPlaying then return end
    if isPaused then
        -- Unpause
        isPaused = false
        startTime = getTime()
        local vPct = getRollerVolume()
        local playVol = math.max(1, math.min(5, math.floor(vPct / 20) + 1))
        playFile(tracks[currentTrack].path, playVol)
    else
        -- Pause
        isPaused = true
        pauseElapsed = pauseElapsed + math.floor((getTime() - startTime) / 100)
        safeStopAudio()
    end
end

local function stopTrack()
    safeStopAudio()
    isPlaying = false
    isPaused = false
    startTime = 0
    pauseElapsed = 0
    -- Clear spectrum bars
    for i = 1, NUM_BARS do
        spectrumHeights[i] = 0
        spectrumPeaks[i] = 0
    end
end

local function nextTrack()
    if shuffleMode and #tracks > 1 then
        local nextIdx = math.random(1, #tracks)
        while nextIdx == currentTrack do
            nextIdx = math.random(1, #tracks)
        end
        playTrack(nextIdx)
    else
        playTrack(currentTrack + 1)
    end
end

local function prevTrack()
    local elapsed = 0
    if isPlaying and not isPaused then
        elapsed = math.floor((getTime() - startTime) / 100) + pauseElapsed
    end
    -- If played more than 3 seconds, restart current track
    if elapsed > 3 then
        playTrack(currentTrack)
    else
        playTrack(currentTrack - 1)
    end
end

--------------------------------------------------------------------------------
-- SPECTRUM ANALYZER ANIMATION
--------------------------------------------------------------------------------

local function updateSpectrum()
    local now = getTime()
    if now == lastAnimTick then return end
    lastAnimTick = now

    if isPlaying and not isPaused then
        local t = now / 10.0
        for i = 1, NUM_BARS do
            -- Pseudo-organic frequency bands calculation
            local phase = t * (0.8 + (i * 0.25))
            local raw = (math.sin(phase) * 0.5) + (math.cos(phase * 1.7) * 0.3) + (math.sin(phase * 0.3 + i) * 0.2)
            raw = (raw + 1.0) / 2.0 -- normalize 0.0 .. 1.0
            
            -- Bass emphasis on bars 1-3, mid activity on 4-7, treble on 8-10
            local boost = (i <= 3) and 1.2 or ((i >= 8) and 0.8 or 1.0)
            local targetH = math.floor(raw * 16 * boost)
            if targetH > 18 then targetH = 18 end
            if targetH < 1 then targetH = 1 end
            
            spectrumHeights[i] = targetH
            
            -- Peak drop logic (classic PocketAmp visualizer feature)
            if targetH >= spectrumPeaks[i] then
                spectrumPeaks[i] = targetH
            else
                if (now % 3) == 0 and spectrumPeaks[i] > 0 then
                    spectrumPeaks[i] = spectrumPeaks[i] - 1
                end
            end
        end
    else
        -- Decay bars when stopped or paused
        for i = 1, NUM_BARS do
            if spectrumHeights[i] > 0 then
                spectrumHeights[i] = spectrumHeights[i] - 1
            end
            if spectrumPeaks[i] > 0 and (now % 2) == 0 then
                spectrumPeaks[i] = spectrumPeaks[i] - 1
            end
        end
    end
end

--------------------------------------------------------------------------------
-- DRAWING: MAIN PLAYER WINDOW
--------------------------------------------------------------------------------

local function drawPlayer()
    local trk = tracks[currentTrack] or {title = "BRAK UTWOROW", duration = 0}
    
    -- Current elapsed time
    local elapsed = 0
    if isPlaying then
        if isPaused then
            elapsed = pauseElapsed
        else
            elapsed = math.floor((getTime() - startTime) / 100) + pauseElapsed
        end
    end
    
    local dur = trk.duration or 180
    if dur > 0 and elapsed >= dur and isPlaying and not isPaused then
        -- Auto-advance track
        if repeatMode == 2 then
            playTrack(currentTrack)
        elseif repeatMode == 1 then
            nextTrack()
        elseif currentTrack < #tracks then
            playTrack(currentTrack + 1)
        else
            stopTrack()
        end
    end

    -- 1. TITLE BAR (y: 0..7)
    lcd.drawFilledRectangle(0, 0, 128, 8)
    lcd.drawText(2, 1, "~ POCKETAMP 2.0", INVERS + SMLSIZE)
    lcd.drawText(112, 1, "_ X", INVERS + SMLSIZE)
    
    -- 2. MAIN DISPLAY BOX (y: 9..34)
    lcd.drawRectangle(0, 9, 128, 26)
    
    -- Left Section: Status & Big LCD Clock
    local statusStr = "[STOP]"
    if isPlaying then
        statusStr = isPaused and "[PAUS]" or "[PLAY]"
    end
    local volPct = getRollerVolume()
    lcd.drawText(3, 11, statusStr, SMLSIZE)
    lcd.drawText(30, 11, "32k", SMLSIZE)
    lcd.drawText(49, 11, string.format("V%2d", volPct), SMLSIZE)
    
    -- Big LCD Timer (MM:SS)
    local timeStr = formatTime(elapsed)
    lcd.drawText(3, 18, timeStr, DBLSIZE)
    
    -- Separator line between Timer and Spectrum
    lcd.drawLine(68, 10, 68, 33, DOTTED, 0)
    
    -- Right Section: Spectrum Analyzer (10 bars)
    local specBaseX = 72
    local specBaseY = 32
    for i = 1, NUM_BARS do
        local bx = specBaseX + (i - 1) * 5
        local h = spectrumHeights[i] or 0
        local pk = spectrumPeaks[i] or 0
        
        -- Bar column (width: 3px)
        if h > 0 then
            lcd.drawFilledRectangle(bx, specBaseY - h, 3, h)
        end
        -- Peak line (width: 3px, 1px height)
        if pk > 0 then
            local py = specBaseY - pk
            if py < 12 then py = 12 end
            lcd.drawLine(bx, py, bx + 2, py, SOLID, 0)
        end
    end
    
    -- 3. MARQUEE TICKER (y: 36..44)
    lcd.drawRectangle(0, 36, 128, 10)
    local tick = getTime()
    -- Zwolniono przewijanie z 12 na 35 (czytelne ~350ms na literę)
    if tick - lastMarqueeTick >= 35 then
        lastMarqueeTick = tick
        marqueeOffset = marqueeOffset + 1
    end
    
    local fullMarquee = marqueeText .. "   "
    local mLen = #fullMarquee
    local startIdx = (marqueeOffset % mLen) + 1
    local windowStr = string.sub(fullMarquee, startIdx, startIdx + 21)
    if #windowStr < 22 then
        windowStr = windowStr .. string.sub(fullMarquee, 1, 22 - #windowStr)
    end
    lcd.drawText(2, 38, windowStr, SMLSIZE)
    
    -- 4. SEEK / PROGRESS BAR (y: 47..51)
    lcd.drawLine(3, 49, 124, 49, SOLID, 0)
    local progress = (dur > 0) and math.min(1.0, elapsed / dur) or 0
    local knobX = math.floor(3 + progress * 116)
    lcd.drawFilledRectangle(knobX, 47, 5, 5)
    lcd.drawPoint(knobX + 2, 49) -- Recessed center dot
    
    -- 5. BUTTONS BAR (y: 53..63)
    -- Buttons layout:
    -- 1: |<< (Prev)  2: > (Play)  3: || (Pause)  4: [] (Stop)  5: >>| (Next)
    -- 6: LST         7: RPT       8: RND
    local buttons = {
        {lbl = "|<",  x = 1,   w = 13},
        {lbl = " >",  x = 15,  w = 13},
        {lbl = "||",  x = 29,  w = 13},
        {lbl = "[]",  x = 43,  w = 13},
        {lbl = ">|",  x = 57,  w = 13},
        {lbl = "LST", x = 72,  w = 17},
        {lbl = (repeatMode == 0 and "ROF" or (repeatMode == 1 and "R:A" or "R:1")), x = 90,  w = 17},
        {lbl = (shuffleMode and "SHF" or "S:O"), x = 108, w = 19}
    }
    
    for i, btn in ipairs(buttons) do
        local isSel = (selectedButton == i)
        if isSel then
            lcd.drawFilledRectangle(btn.x, 53, btn.w, 10)
            lcd.drawText(btn.x + 1, 55, btn.lbl, INVERS + SMLSIZE)
        else
            lcd.drawRectangle(btn.x, 53, btn.w, 10)
            lcd.drawText(btn.x + 1, 55, btn.lbl, SMLSIZE)
        end
    end
end

--------------------------------------------------------------------------------
-- DRAWING: PLAYLIST WINDOW
--------------------------------------------------------------------------------

local function drawPlaylist()
    -- Header
    lcd.drawFilledRectangle(0, 0, 128, 8)
    local headerTitle = string.format("~ POCKETAMP PLAYLIST (%d)", #tracks)
    lcd.drawText(2, 1, headerTitle, INVERS + SMLSIZE)
    lcd.drawText(112, 1, "ESC", INVERS + SMLSIZE)
    
    -- Playlist entries (shows 4 tracks per page)
    local PAGE_SIZE = 4
    if playlistCursor > playlistOffset + PAGE_SIZE then
        playlistOffset = playlistCursor - PAGE_SIZE
    elseif playlistCursor <= playlistOffset then
        playlistOffset = playlistCursor - 1
    end
    if playlistOffset < 0 then playlistOffset = 0 end
    
    local yStart = 10
    for i = 1, PAGE_SIZE do
        local idx = playlistOffset + i
        local y = yStart + (i - 1) * 11
        if idx <= #tracks then
            local trk = tracks[idx]
            local isCursor = (idx == playlistCursor)
            local isCurPlay = (idx == currentTrack and isPlaying)
            
            if isCursor then
                lcd.drawFilledRectangle(0, y, 122, 10)
                local prefix = isCurPlay and ">*" or "> "
                local title = string.sub(trk.title, 1, 14)
                local line = string.format("%s%02d.%s", prefix, idx, title)
                lcd.drawText(1, y + 1, line, INVERS + SMLSIZE)
                lcd.drawText(98, y + 1, formatTime(trk.duration), INVERS + SMLSIZE)
            else
                local prefix = isCurPlay and "* " or "  "
                local title = string.sub(trk.title, 1, 14)
                local line = string.format("%s%02d.%s", prefix, idx, title)
                lcd.drawText(1, y + 1, line, SMLSIZE)
                lcd.drawText(98, y + 1, formatTime(trk.duration), SMLSIZE)
            end
        end
    end
    
    -- Scrollbar on right edge
    if #tracks > PAGE_SIZE then
        lcd.drawLine(124, 10, 124, 52, SOLID, 0)
        local barH = math.max(6, math.floor(PAGE_SIZE / #tracks * 42))
        local barY = 10 + math.floor(playlistOffset / (#tracks - PAGE_SIZE) * (42 - barH))
        lcd.drawFilledRectangle(123, barY, 3, barH)
    end
    
    -- Footer hints
    lcd.drawRectangle(0, 54, 128, 10)
    lcd.drawText(2, 56, "[ENT] Graj | [RTN] Wroc", SMLSIZE)
end

--------------------------------------------------------------------------------
-- EVENT & NAVIGATION HANDLER
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

local function isEnter(event)
    if not event or event == 0 then return false end
    return event == EVT_ENTER_BREAK or event == EVT_VIRTUAL_ENTER
        or event == EVT_ROT_BREAK
end

local function isPage(event)
    if not event or event == 0 then return false end
    return event == EVT_VIRTUAL_NEXT_PAGE or event == EVT_PAGE_BREAK
end

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

-- Nawigacja drążkiem jako alternatywa dla rolki
local lastStickNav = 0
local function checkStickNav()
    local now = getTime()
    if now - lastStickNav < 20 then return 0 end
    local ail = getValue("ail") or 0
    local rud = getValue("rud") or 0
    local val = (math.abs(ail) > math.abs(rud)) and ail or rud
    if val > 500 then
        lastStickNav = now
        return 1
    elseif val < -500 then
        lastStickNav = now
        return -1
    end
    return 0
end

local function executeButton(btnIdx)
    if btnIdx == 1 then
        prevTrack()
    elseif btnIdx == 2 then
        -- Przycisk Play: przełącza Play / Pause
        if isPlaying and not isPaused then
            pauseTrack()
        else
            if isPaused then pauseTrack() else playTrack(currentTrack) end
        end
    elseif btnIdx == 3 then
        pauseTrack()
    elseif btnIdx == 4 then
        stopTrack()
    elseif btnIdx == 5 then
        nextTrack()
    elseif btnIdx == 6 then
        viewMode = VIEW_PLAYLIST
        playlistCursor = currentTrack
    elseif btnIdx == 7 then
        repeatMode = (repeatMode + 1) % 3
    elseif btnIdx == 8 then
        shuffleMode = not shuffleMode
    end
end

--------------------------------------------------------------------------------
-- LIFECYCLE: INIT & RUN
--------------------------------------------------------------------------------

local startupIgnoreUntil = 0

local function init()
    scanTracks()
    if #tracks > 0 then
        local trk = tracks[currentTrack]
        marqueeText = string.format("*** %02d. %s (%s) ***", 
            currentTrack, string.upper(trk.title), formatTime(trk.duration))
    end
    startupIgnoreUntil = getTime() + 40 -- 0.4s debounce na start
end

local function run(event)
    local now = getTime()
    lcd.clear()
    
    -- Update visualizer & timers
    updateSpectrum()
    
    local sNav = checkStickNav()
    local seTriggered = checkSeSwitch()
    
    -- Quick shoulder button [SE] to Play/Pause
    if seTriggered and (now > startupIgnoreUntil) then
        if isPlaying and not isPaused then
            pauseTrack()
        else
            if isPaused then pauseTrack() else playTrack(currentTrack) end
        end
    end
    
    -- Page button switches between Player and Playlist
    if isPage(event) and (now > startupIgnoreUntil) then
        if viewMode == VIEW_PLAYER then
            viewMode = VIEW_PLAYLIST
            playlistCursor = currentTrack
        else
            viewMode = VIEW_PLAYER
        end
    end
    
    -- Handle Events
    if viewMode == VIEW_PLAYER then
        if isNext(event) or sNav == 1 then
            selectedButton = (selectedButton % 8) + 1
        elseif isPrev(event) or sNav == -1 then
            selectedButton = (selectedButton - 2 + 8) % 8 + 1
        elseif isEnter(event) and (now > startupIgnoreUntil) then
            executeButton(selectedButton)
        elseif isExit(event) and (now > startupIgnoreUntil) then
            -- Clean exit from PocketAmp
            safeStopAudio()
            return 2
        end
        
        drawPlayer()
        
    elseif viewMode == VIEW_PLAYLIST then
        if isNext(event) or sNav == 1 then
            playlistCursor = math.min(#tracks, playlistCursor + 1)
        elseif isPrev(event) or sNav == -1 then
            playlistCursor = math.max(1, playlistCursor - 1)
        elseif isEnter(event) and (now > startupIgnoreUntil) then
            playTrack(playlistCursor)
            viewMode = VIEW_PLAYER
        elseif isExit(event) and (now > startupIgnoreUntil) then
            viewMode = VIEW_PLAYER
        end
        
        drawPlaylist()
    end
    
    return 0
end

return {init = init, run = run}
