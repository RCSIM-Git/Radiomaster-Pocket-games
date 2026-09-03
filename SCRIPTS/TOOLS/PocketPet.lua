---- TNS|Pocket Pet|TNE
--[[
    ================================================================================
    POCKET PET (FPV Drone Edition) for EdgeTX
    Virtual FPV Drone Simulator for 128x64 Monochrome LCD
    Compatible with: RadioMaster Pocket, MT12, Boxer, TX12, Zorro
    Features:
      - 4 Drone Evolution Stages: Flight Case -> Tiny Whoop -> Toothpick -> Adult (5" Freestyle / Cinewhoop / Wing)
      - Dynamic Needs: Battery (Hunger), Happiness, Energy, Dirt (Hygiene), Service (Health)
      - 6 Interactive Actions: Feed, Sleep, Game, Meds, Wash, Stats
      - Arcade Mini-Game: "Catch the Battery" (Fly drone with gimbals, catch LiPos!)
      - RadioMaster Telemetry: Drone reads actual transmitter battery voltage & comments!
      - Authentic 8-bit chiptune sound effects via hardware DAC (/SOUNDS/POCKETPET/)
      - SD card auto-save & offline time simulation (/SCRIPTS/TOOLS/POCKETPET/pet.dat)
      - Pocket-tailored controls: Top shoulder [SE], Gimbals, Roller [ENT], [RTN] exit
    Author: EdgeTX Pair-Programmer & Mateusz
    ================================================================================
--]]

local LCD_W = 128
local LCD_H = 64

-- Evolution Stages
local STAGE_EGG = 0
local STAGE_BABY = 1
local STAGE_CHILD = 2
local STAGE_ADULT_DRONE = 3
local STAGE_ADULT_PIKA = 4
local STAGE_ADULT_DINO = 5

-- Game Modes / Screens
local MODE_MAIN = 0
local MODE_FEED_MENU = 1
local MODE_STATS = 2
local MODE_MINIGAME = 3
local MODE_ANIMATION = 4
local MODE_CONFIRM_RESET = 5

local currentMode = MODE_MAIN
local activeAnim = ""
local animTimer = 0
local statsIgnoreUntil = 0
local confirmIgnoreUntil = 0

-- Action Icons (Top Bar - strictly 4 characters each to fit 21px slot)
local ICONS = { "FEED", "REST", "PLAY", "MEDS", "WASH", "STAT" }
local selectedIcon = 1

-- Feed Submenu Selection (1: LiPo Pack, 2: Snack Fuel)
local feedSubSelection = 1

-- Persistent Pet State
local pet = {
    stage = STAGE_EGG,
    eggWarmth = 0,       -- 0..100 to hatch
    name = "DRONE",
    hunger = 4,          -- 0..4 hearts (LiPo charge)
    happiness = 4,       -- 0..4 hearts
    energy = 100,        -- 0..100
    isSleeping = false,
    poops = 0,           -- 0..3 (Grass/dirt on motors)
    isSick = false,      -- Glitch/service required
    ageMinutes = 0,
    weight = 5,          -- grams
    careMistakes = 0,
    totalGamesPlayed = 0,
    discipline = 50,
    birthTime = 0,
    lastTickTime = 0,
}

local SAVE_PATH = "/SCRIPTS/TOOLS/POCKETPET/pet.dat"

-- Pet Physics & Animation in Playfield
local petX = 64
local petY = 32
local petDir = 1
local petMoveTimer = 0
local animFrame = 0
local lastAnimTick = 0

-- Thought Bubble / Message at Bottom
local petMessage = "Hello! Charge the flight case [SE]!"
local messageExpireTime = 0

-- Startup Debounce & Timing
local startupIgnoreUntil = 0
local playVolume = 4

--------------------------------------------------------------------------------
-- AUDIO UTILITIES (8-bit Chiptune)
--------------------------------------------------------------------------------

local function playSfx(filename)
    if type(playFile) == "function" then
        pcall(playFile, "/SOUNDS/POCKETPET/" .. filename, playVolume)
    end
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

local function triggerMessage(msg, durationTicks)
    petMessage = msg
    messageExpireTime = getTime() + (durationTicks or 200)
end

--------------------------------------------------------------------------------
-- SAVE & LOAD PERSISTENCE
--------------------------------------------------------------------------------

local function savePetState()
    local f = io.open(SAVE_PATH, "w")
    if not f then return false end
    
    local line = string.format("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
        pet.stage,
        pet.eggWarmth,
        pet.hunger,
        pet.happiness,
        pet.energy,
        pet.isSleeping and 1 or 0,
        pet.poops,
        pet.isSick and 1 or 0,
        pet.ageMinutes,
        pet.weight,
        pet.careMistakes,
        pet.totalGamesPlayed,
        pet.discipline
    )
    io.write(f, line)
    io.close(f)
    return true
end

local function loadPetState()
    local f = io.open(SAVE_PATH, "r")
    if not f then
        pet.stage = STAGE_EGG
        pet.eggWarmth = 0
        pet.hunger = 4
        pet.happiness = 4
        pet.energy = 100
        pet.isSleeping = false
        pet.poops = 0
        pet.isSick = false
        pet.ageMinutes = 0
        pet.weight = 5
        pet.careMistakes = 0
        pet.totalGamesPlayed = 0
        pet.discipline = 50
        return
    end

    local line = io.read(f, 256)
    io.close(f)

    if line and #line > 5 then
        local parts = {}
        for val in string.gmatch(line, "([^,]+)") do
            parts[#parts + 1] = tonumber(val)
        end

        if #parts >= 12 then
            pet.stage = parts[1] or STAGE_EGG
            pet.eggWarmth = parts[2] or 0
            pet.hunger = math.max(0, math.min(4, parts[3] or 4))
            pet.happiness = math.max(0, math.min(4, parts[4] or 4))
            pet.energy = math.max(0, math.min(100, parts[5] or 100))
            pet.isSleeping = (parts[6] == 1)
            pet.poops = math.max(0, math.min(3, parts[7] or 0))
            pet.isSick = (parts[8] == 1)
            pet.ageMinutes = parts[9] or 0
            pet.weight = parts[10] or 5
            pet.careMistakes = parts[11] or 0
            pet.totalGamesPlayed = parts[12] or 0
            pet.discipline = parts[13] or 50
        end
    end
end

--------------------------------------------------------------------------------
-- RADIO TELEMETRY TIE-IN
--------------------------------------------------------------------------------

local function getRadioBattInfo()
    local v = getValue("batt")
    if not v or type(v) ~= "number" or v <= 0 then
        return 8.0, "OK"
    end
    local volts = (v > 20) and (v / 10.0) or v
    local comment = "GOOD!"
    if volts >= 8.0 then
        comment = "100%!"
    elseif volts >= 7.4 then
        comment = "GOOD"
    elseif volts >= 6.8 then
        comment = "CHARGE!"
    else
        comment = "LOW BATT!"
    end
    return volts, comment
end

--------------------------------------------------------------------------------
-- EVOLUTION & LIFECYCLE ENGINE
--------------------------------------------------------------------------------

local function checkEvolution()
    if pet.stage == STAGE_EGG then
        if pet.eggWarmth >= 100 then
            pet.stage = STAGE_BABY
            pet.hunger = 2
            pet.happiness = 3
            pet.weight = 5
            playSfx("hatch.wav")
            triggerMessage("DRONE ACTIVATED! Welcome Tiny Whoop!", 250)
            savePetState()
        end
    elseif pet.stage == STAGE_BABY then
        if pet.ageMinutes >= 4 then
            pet.stage = STAGE_CHILD
            playSfx("win.wav")
            triggerMessage("EVOLUTION! Upgraded to Toothpick 3\"!", 250)
            savePetState()
        end
    elseif pet.stage == STAGE_CHILD then
        if pet.ageMinutes >= 10 then
            local battV = getRadioBattInfo()
            if pet.totalGamesPlayed >= 3 and pet.careMistakes <= 1 then
                pet.stage = STAGE_ADULT_DRONE -- 5" Freestyle
                triggerMessage("EVOLUTION: 5\" Freestyle Beast Unlocked!", 250)
            elseif battV >= 7.8 and pet.careMistakes <= 2 then
                pet.stage = STAGE_ADULT_PIKA -- Cinewhoop
                triggerMessage("EVOLUTION: Cinewhoop 4K Pro Unlocked!", 250)
            else
                pet.stage = STAGE_ADULT_DINO -- FPV Wing
                triggerMessage("EVOLUTION: FPV Flying Wing Unlocked!", 250)
            end
            playSfx("win.wav")
            savePetState()
        end
    end
end

-- Simulates time passing every second
local lastTickSec = 0
local function updatePetNeeds()
    local now = getTime()
    if now - lastTickSec < 100 then return end
    lastTickSec = now

    pet.ageMinutes = pet.ageMinutes + (1 / 60)

    if pet.stage == STAGE_EGG then
        return
    end

    if pet.isSleeping then
        pet.energy = math.min(100, pet.energy + 1)
        if math.random(1, 120) == 1 and pet.hunger > 0 then
            pet.hunger = pet.hunger - 1
        end
    else
        pet.energy = math.max(0, pet.energy - 0.25)
        if math.random(1, 45) == 1 and pet.hunger > 0 then
            pet.hunger = pet.hunger - 1
            if pet.hunger <= 1 then
                playSfx("beep.wav")
                triggerMessage("Low Battery! Feed LiPo pack! 🍗", 150)
            end
        end

        if math.random(1, 70) == 1 and pet.happiness > 0 then
            pet.happiness = pet.happiness - 1
        end

        -- Dirt on props / motors
        if math.random(1, 90) == 1 and pet.poops < 3 then
            pet.poops = pet.poops + 1
            playSfx("beep.wav")
            triggerMessage("Motors dirty! Wash the props! 🚿", 150)
        end
    end

    -- Sickness / glitch check
    if (pet.poops >= 2 or pet.hunger == 0) and not pet.isSick then
        if math.random(1, 40) == 1 then
            pet.isSick = true
            pet.careMistakes = pet.careMistakes + 1
            playSfx("sick.wav")
            triggerMessage("GLITCH DETECTED! Needs service! 💉", 200)
        end
    end

    checkEvolution()
end

--------------------------------------------------------------------------------
-- MINI-GAME: "CATCH THE BATTERY"
--------------------------------------------------------------------------------

local mg = {
    active = false,
    score = 0,
    lives = 3,
    playerX = 64,
    items = {},
    lastSpawn = 0,
    timer = 30,
    lastSec = 0
}

local function startMiniGame()
    currentMode = MODE_MINIGAME
    mg.active = true
    mg.score = 0
    mg.lives = 3
    mg.playerX = 64
    mg.items = {}
    mg.lastSpawn = getTime()
    mg.timer = 30
    mg.lastSec = getTime()
    playSfx("happy.wav")
end

local function updateMiniGame(stickVal, btnEnter, btnSe)
    local now = getTime()

    -- Move flying drone
    if stickVal > 300 then
        mg.playerX = math.min(115, mg.playerX + 3)
    elseif stickVal < -300 then
        mg.playerX = math.max(12, mg.playerX - 3)
    end

    -- Timer countdown
    if now - mg.lastSec >= 100 then
        mg.lastSec = now
        mg.timer = mg.timer - 1
        if mg.timer <= 0 then
            mg.active = false
            pet.totalGamesPlayed = pet.totalGamesPlayed + 1
            pet.happiness = math.min(4, pet.happiness + 2)
            pet.weight = math.max(3, pet.weight - 1)
            playSfx("win.wav")
            triggerMessage(string.format("GAME OVER! Score: %d pts!", mg.score), 250)
            currentMode = MODE_MAIN
            savePetState()
            return
        end
    end

    -- Spawn falling items
    if now - mg.lastSpawn > math.random(60, 110) then
        mg.lastSpawn = now
        local itype = math.random(1, 10)
        -- 1..6: Battery (+10), 7..8: Fuel (+5), 9..10: Bomb (-1 life)
        local tname = (itype <= 6) and 1 or ((itype <= 8) and 2 or 3)
        mg.items[#mg.items + 1] = {
            x = math.random(15, 112),
            y = 12,
            type = tname,
            speed = (tname == 3) and 1.8 or 1.3
        }
    end

    -- Move items down & check collision
    local newItems = {}
    for i = 1, #mg.items do
        local it = mg.items[i]
        it.y = it.y + it.speed

        if it.y >= 46 and it.y <= 54 and math.abs(it.x - mg.playerX) < 14 then
            if it.type == 1 then
                mg.score = mg.score + 10
                playSfx("catch.wav")
            elseif it.type == 2 then
                mg.score = mg.score + 5
                playSfx("eat.wav")
            elseif it.type == 3 then
                mg.lives = mg.lives - 1
                playSfx("hurt.wav")
                if mg.lives <= 0 then
                    mg.active = false
                    pet.totalGamesPlayed = pet.totalGamesPlayed + 1
                    pet.happiness = math.min(4, pet.happiness + 1)
                    triggerMessage("BOMB HIT! Out of lives!", 200)
                    currentMode = MODE_MAIN
                    savePetState()
                    return
                end
            end
        elseif it.y < 58 then
            newItems[#newItems + 1] = it
        end
    end
    mg.items = newItems
end

local function drawMiniGame()
    lcd.clear()
    -- Header: Score, Lives, Timer
    lcd.drawFilledRectangle(0, 0, LCD_W, 11)
    lcd.drawText(2, 2, string.format("SCORE: %d", mg.score), INVERS + SMLSIZE)
    lcd.drawText(62, 2, string.format("TIME: %ds", mg.timer), INVERS + SMLSIZE)
    
    -- Heart lives on right
    for l = 1, mg.lives do
        lcd.drawText(100 + (l - 1) * 9, 2, "♥", INVERS + SMLSIZE)
    end

    -- Floor line
    lcd.drawLine(0, 56, LCD_W - 1, 56, SOLID, 0)

    -- Falling items (No circles - using rectangles & lines)
    for _, it in ipairs(mg.items) do
        local ix = math.floor(it.x)
        local iy = math.floor(it.y)
        if it.type == 1 then
            -- Battery glyph: [||]
            lcd.drawRectangle(ix - 3, iy - 3, 7, 6)
            lcd.drawPoint(ix + 4, iy - 1)
            lcd.drawPoint(ix + 4, iy)
            lcd.drawLine(ix - 1, iy - 2, ix - 1, iy + 1, SOLID, 0)
        elseif it.type == 2 then
            -- Snack / Fuel drumstick
            lcd.drawFilledRectangle(ix - 2, iy - 2, 5, 5)
            lcd.drawLine(ix, iy, ix - 4, iy + 3, SOLID, 0)
        elseif it.type == 3 then
            -- Bomb / Glitch: square bomb with fuse
            lcd.drawRectangle(ix - 2, iy - 2, 5, 5)
            lcd.drawLine(ix, iy - 2, ix + 2, iy - 5, SOLID, 0)
            lcd.drawPoint(ix + 3, iy - 6)
        end
    end

    -- Player Pet (Flying Drone)
    local px = math.floor(mg.playerX)
    local py = 50
    -- Central drone body
    lcd.drawFilledRectangle(px - 5, py - 2, 10, 5)
    -- Left & Right Arms
    lcd.drawLine(px - 5, py, px - 11, py - 3, SOLID, 0)
    lcd.drawLine(px + 4, py, px + 10, py - 3, SOLID, 0)
    -- Motors & Spinning Props
    lcd.drawPoint(px - 11, py - 4)
    lcd.drawPoint(px + 10, py - 4)
    lcd.drawLine(px - 15, py - 5, px - 7, py - 5, SOLID, 0)
    lcd.drawLine(px + 6, py - 5, px + 14, py - 5, SOLID, 0)
    -- VTX Antenna
    lcd.drawLine(px + 2, py - 2, px + 4, py - 6, SOLID, 0)
    lcd.drawPoint(px + 4, py - 6)
    -- Camera eye
    lcd.drawPoint(px - 1, py)
    lcd.drawPoint(px + 1, py)

    -- Instructions
    lcd.drawText(2, 58, "STICKS: Fly   [RTN] Exit", SMLSIZE)
end

--------------------------------------------------------------------------------
-- ACTIONS IMPLEMENTATION
--------------------------------------------------------------------------------

local function doFeedMeal()
    if pet.isSleeping then
        triggerMessage("Sleeping! Wake up first! 💡", 150)
        return
    end
    if pet.hunger >= 4 then
        triggerMessage("Full battery! Not hungry! 🍗", 150)
        playSfx("sick.wav")
        return
    end
    pet.hunger = math.min(4, pet.hunger + 2)
    pet.weight = pet.weight + 1
    playSfx("eat.wav")
    activeAnim = "EAT"
    animTimer = getTime() + 60
    triggerMessage("Chomp! LiPo pack charged!", 150)
    savePetState()
end

local function doFeedSnack()
    if pet.isSleeping then
        triggerMessage("Sleeping! Wake up first! 💡", 150)
        return
    end
    pet.happiness = math.min(4, pet.happiness + 1)
    pet.weight = pet.weight + 2
    playSfx("eat.wav")
    activeAnim = "EAT"
    animTimer = getTime() + 50
    triggerMessage("Snack fuel! Delicious! 🍬", 150)
    savePetState()
end

local function doToggleLight()
    pet.isSleeping = not pet.isSleeping
    if pet.isSleeping then
        triggerMessage("Goodnight! Zzz... 💡", 150)
    else
        triggerMessage("Good morning! Ready to fly! ☀️", 150)
        playSfx("happy.wav")
    end
    savePetState()
end

local function doMedicine()
    if pet.isSleeping then
        triggerMessage("Sleeping! Wake up first! 💡", 150)
        return
    end
    if not pet.isSick then
        triggerMessage("Healthy! No service needed! 💉", 150)
        return
    end
    pet.isSick = false
    playSfx("happy.wav")
    activeAnim = "HAPPY"
    animTimer = getTime() + 70
    triggerMessage("Repairs complete! Ready to fly!", 200)
    savePetState()
end

local function doShower()
    if pet.poops == 0 then
        triggerMessage("Already clean! No dirt on motors!", 150)
        return
    end
    pet.poops = 0
    playSfx("clean.wav")
    activeAnim = "SHOWER"
    animTimer = getTime() + 80
    triggerMessage("Clean! Props and motors washed!", 200)
    savePetState()
end

local function doPetPraise()
    if pet.isSleeping then return end
    pet.happiness = math.min(4, pet.happiness + 1)
    playSfx("happy.wav")
    activeAnim = "HAPPY"
    animTimer = getTime() + 60
    triggerMessage("❤️ Motor test OK! Pilot loved!", 150)
    savePetState()
end

local function warmEgg()
    pet.eggWarmth = pet.eggWarmth + 10
    playSfx("catch.wav")
    activeAnim = "WOBBLE"
    animTimer = getTime() + 25
    triggerMessage(string.format("Charging case! Power: %d%%", pet.eggWarmth), 100)
    checkEvolution()
end

--------------------------------------------------------------------------------
-- SPRITE RENDERING (Flight Case, Tiny Whoop, Toothpick, 5" Freestyle, Cinewhoop, Wing)
--------------------------------------------------------------------------------

local function drawFlightCase(cx, cy, wobble)
    local ox = cx + (wobble and math.random(-1, 1) or 0)
    -- Rugged Flight Case
    lcd.drawRectangle(ox - 14, cy - 8, 28, 18)
    lcd.drawFilledRectangle(ox - 12, cy - 6, 24, 14)
    -- Corner bumpers
    lcd.drawPoint(ox - 14, cy - 8)
    lcd.drawPoint(ox + 13, cy - 8)
    lcd.drawPoint(ox - 14, cy + 9)
    lcd.drawPoint(ox + 13, cy + 9)
    -- Center latches & handle
    lcd.drawRectangle(ox - 5, cy - 10, 10, 3)
    lcd.drawLine(ox - 8, cy - 1, ox - 6, cy - 1, SOLID, 0)
    lcd.drawLine(ox + 6, cy - 1, ox + 8, cy - 1, SOLID, 0)
    -- Status battery charge bar inside case
    lcd.drawFilledRectangle(ox - 9, cy + 2, 18, 4, ERASE)
    local wFill = math.floor((pet.eggWarmth / 100) * 16)
    if wFill > 0 then
        lcd.drawFilledRectangle(ox - 8, cy + 3, wFill, 2)
    end
    -- VTX Antenna sticking out top
    lcd.drawLine(ox + 7, cy - 8, ox + 11, cy - 14, SOLID, 0)
    lcd.drawFilledRectangle(ox + 10, cy - 15, 3, 3)
end

local function drawTinyWhoop(cx, cy, frame, isEating)
    local hover = (frame == 1) and -1 or 1
    local y = cy + hover

    -- 4 Distinct Propeller Ducts
    lcd.drawRectangle(cx - 15, y - 8, 10, 8)
    lcd.drawRectangle(cx + 5, y - 8, 10, 8)
    lcd.drawRectangle(cx - 12, y + 1, 9, 8)
    lcd.drawRectangle(cx + 3, y + 1, 9, 8)

    -- Spinning Propellers inside ducts
    if frame == 0 then
        lcd.drawLine(cx - 14, y - 4, cx - 6, y - 4, SOLID, 0)
        lcd.drawLine(cx + 6, y - 4, cx + 14, y - 4, SOLID, 0)
        lcd.drawLine(cx - 11, y + 5, cx - 4, y + 5, SOLID, 0)
        lcd.drawLine(cx + 4, y + 5, cx + 11, y + 5, SOLID, 0)
    else
        lcd.drawLine(cx - 13, y - 6, cx - 7, y - 2, SOLID, 0)
        lcd.drawLine(cx + 7, y - 6, cx + 13, y - 2, SOLID, 0)
        lcd.drawLine(cx - 10, y + 3, cx - 5, y + 7, SOLID, 0)
        lcd.drawLine(cx + 5, y + 3, cx + 10, y + 7, SOLID, 0)
    end

    -- Center Canopy Pod
    lcd.drawFilledRectangle(cx - 5, y - 5, 10, 11)
    
    -- FPV Camera Lens / Visor
    lcd.drawFilledRectangle(cx - 3, y - 3, 6, 4, ERASE)
    if isEating then
        lcd.drawFilledRectangle(cx - 2, y - 1, 4, 2)
    else
        lcd.drawPoint(cx - 1, y - 1)
        lcd.drawPoint(cx + 1, y - 1)
    end

    -- Micro VTX Antenna
    lcd.drawLine(cx, y - 5, cx + 3, y - 11, SOLID, 0)
    lcd.drawPoint(cx + 3, y - 11)

    -- Prop-wash wind dots
    if frame == 1 then
        lcd.drawPoint(cx - 10, y + 11)
        lcd.drawPoint(cx + 10, y + 11)
    end
end

local function drawToothpickQuad(cx, cy, frame)
    local hover = (frame == 1) and -1 or 1
    local y = cy + hover

    -- Carbon Fiber X-Frame Arms
    lcd.drawLine(cx - 6, y - 2, cx - 17, y - 7, SOLID, 0)
    lcd.drawLine(cx + 5, y - 2, cx + 16, y - 7, SOLID, 0)
    lcd.drawLine(cx - 5, y + 3, cx - 15, y + 8, SOLID, 0)
    lcd.drawLine(cx + 4, y + 3, cx + 14, y + 8, SOLID, 0)

    -- 4 Brushless Motor Bells (3x3)
    lcd.drawFilledRectangle(cx - 19, y - 8, 3, 3)
    lcd.drawFilledRectangle(cx + 16, y - 8, 3, 3)
    lcd.drawFilledRectangle(cx - 17, y + 7, 3, 3)
    lcd.drawFilledRectangle(cx + 14, y + 7, 3, 3)

    -- Spinning 3-inch Propellers
    local pW = (frame == 1) and 10 or 6
    lcd.drawLine(cx - 18 - pW/2, y - 9, cx - 18 + pW/2, y - 9, SOLID, 0)
    lcd.drawLine(cx + 17 - pW/2, y - 9, cx + 17 + pW/2, y - 9, SOLID, 0)
    lcd.drawLine(cx - 16 - pW/2, y + 6, cx - 16 + pW/2, y + 6, SOLID, 0)
    lcd.drawLine(cx + 15 - pW/2, y + 6, cx + 15 + pW/2, y + 6, SOLID, 0)

    -- Central Carbon Fuselage
    lcd.drawFilledRectangle(cx - 6, y - 3, 12, 8)
    
    -- Top 3S LiPo Battery with battery strap
    lcd.drawFilledRectangle(cx - 4, y - 6, 8, 3)
    lcd.drawLine(cx, y - 6, cx, y - 4, SOLID, 0)

    -- FPV Camera Roll-Cage & Lens
    lcd.drawFilledRectangle(cx - 3, y - 1, 6, 4, ERASE)
    lcd.drawPoint(cx - 1, y + 1)
    lcd.drawPoint(cx + 1, y + 1)

    -- Rear VTX Pagoda Antenna
    lcd.drawLine(cx + 4, y - 5, cx + 8, y - 11, SOLID, 0)
    lcd.drawFilledRectangle(cx + 7, y - 12, 3, 3)

    -- Thrust wind lines
    lcd.drawLine(cx - 18, y + 1, cx - 18, y + 3, SOLID, 0)
    lcd.drawLine(cx + 17, y + 1, cx + 17, y + 3, SOLID, 0)
end

local function drawFreestyle5Inch(cx, cy, frame)
    local hover = (frame == 1) and -2 or 0
    local y = cy + hover

    -- Beefy Carbon Arms
    lcd.drawLine(cx - 7, y - 2, cx - 21, y - 7, SOLID, 0)
    lcd.drawLine(cx - 7, y - 3, cx - 21, y - 8, SOLID, 0)
    lcd.drawLine(cx + 6, y - 2, cx + 20, y - 7, SOLID, 0)
    lcd.drawLine(cx + 6, y - 3, cx + 20, y - 8, SOLID, 0)
    lcd.drawLine(cx - 6, y + 3, cx - 18, y + 9, SOLID, 0)
    lcd.drawLine(cx + 5, y + 3, cx + 17, y + 9, SOLID, 0)

    -- 4 Big 2207 Brushless Motors
    lcd.drawFilledRectangle(cx - 23, y - 9, 4, 4)
    lcd.drawFilledRectangle(cx + 19, y - 9, 4, 4)
    lcd.drawFilledRectangle(cx - 20, y + 7, 4, 4)
    lcd.drawFilledRectangle(cx + 16, y + 7, 4, 4)

    -- 5" Propeller Blades & Blur Effect
    if frame == 0 then
        lcd.drawLine(cx - 29, y - 10, cx - 15, y - 10, SOLID, 0)
        lcd.drawLine(cx + 13, y - 10, cx + 27, y - 10, SOLID, 0)
        lcd.drawLine(cx - 26, y + 6, cx - 12, y + 6, SOLID, 0)
        lcd.drawLine(cx + 10, y + 6, cx + 24, y + 6, SOLID, 0)
    else
        lcd.drawLine(cx - 28, y - 12, cx - 16, y - 8, SOLID, 0)
        lcd.drawLine(cx + 14, y - 12, cx + 26, y - 8, SOLID, 0)
        lcd.drawLine(cx - 25, y + 4, cx - 13, y + 8, SOLID, 0)
        lcd.drawLine(cx + 11, y + 4, cx + 23, y + 8, SOLID, 0)
    end

    -- Central Frame & Top Plate
    lcd.drawFilledRectangle(cx - 8, y - 4, 16, 9)
    
    -- Top 6S LiPo Battery with battery strap
    lcd.drawFilledRectangle(cx - 6, y - 8, 12, 4)
    lcd.drawLine(cx - 1, y - 8, cx - 1, y - 5, SOLID, 0)

    -- Action Cam / GoPro on 30 deg TPU mount
    lcd.drawFilledRectangle(cx - 4, y - 13, 7, 5)
    lcd.drawPoint(cx - 1, y - 11)

    -- Front FPV Camera in CNC Aluminum Cage
    lcd.drawFilledRectangle(cx - 4, y - 1, 8, 4, ERASE)
    lcd.drawPoint(cx - 2, y + 1)
    lcd.drawPoint(cx + 1, y + 1)

    -- Rear Pagoda Antenna
    lcd.drawLine(cx + 5, y - 6, cx + 9, y - 14, SOLID, 0)
    lcd.drawRectangle(cx + 8, y - 15, 3, 3)
    lcd.drawPoint(cx + 9, y - 14)

    -- Tail LED lights on rear arms
    if frame == 1 then
        lcd.drawPoint(cx - 18, y + 12)
        lcd.drawPoint(cx + 17, y + 12)
    end

    -- Prop wash thrust lines
    lcd.drawLine(cx - 21, y - 4, cx - 21, y, SOLID, 0)
    lcd.drawLine(cx + 20, y - 4, cx + 20, y, SOLID, 0)
end

local function drawCinewhoop(cx, cy, frame)
    local hover = (frame == 1) and -1 or 1
    local y = cy + hover

    -- 4 Big Ducted Bumpers
    lcd.drawRectangle(cx - 20, y - 9, 14, 11)
    lcd.drawRectangle(cx + 6, y - 9, 14, 11)
    lcd.drawRectangle(cx - 16, y + 3, 13, 10)
    lcd.drawRectangle(cx + 3, y + 3, 13, 10)

    -- Internal spinning props
    lcd.drawLine(cx - 18, y - 4, cx - 8, y - 4, SOLID, 0)
    lcd.drawLine(cx + 8, y - 4, cx + 18, y - 4, SOLID, 0)
    lcd.drawLine(cx - 14, y + 8, cx - 5, y + 8, SOLID, 0)
    lcd.drawLine(cx + 5, y + 8, cx + 14, y + 8, SOLID, 0)

    -- Central Pod with 4K Cine Camera
    lcd.drawFilledRectangle(cx - 6, y - 6, 12, 12)
    lcd.drawFilledRectangle(cx - 4, y - 3, 8, 6, ERASE)
    lcd.drawFilledRectangle(cx - 1, y - 1, 3, 3)

    -- Top LiPo & Antenna
    lcd.drawFilledRectangle(cx - 4, y - 9, 8, 3)
    lcd.drawLine(cx + 3, y - 8, cx + 7, y - 14, SOLID, 0)
    lcd.drawRectangle(cx + 6, y - 15, 3, 3)
end

local function drawFPVWing(cx, cy, frame)
    local hover = (frame == 1) and -1 or 1
    local y = cy + hover

    -- Aerodynamic Swept Delta Wing
    lcd.drawLine(cx, y - 7, cx - 20, y + 4, SOLID, 0)
    lcd.drawLine(cx, y - 7, cx + 20, y + 4, SOLID, 0)
    lcd.drawLine(cx - 20, y + 4, cx + 20, y + 4, SOLID, 0)
    lcd.drawFilledRectangle(cx - 5, y - 6, 10, 11)

    -- Twin Vertical Stabilizer Fins on Wingtips
    lcd.drawLine(cx - 20, y + 4, cx - 20, y - 3, SOLID, 0)
    lcd.drawLine(cx + 20, y + 4, cx + 20, y - 3, SOLID, 0)

    -- Nose FPV Camera Bubble
    lcd.drawFilledRectangle(cx - 2, y - 7, 4, 3, ERASE)
    lcd.drawPoint(cx, y - 6)

    -- Rear Pusher Motor & Spinning Propeller
    lcd.drawFilledRectangle(cx - 2, y + 5, 4, 3)
    local pW = (frame == 1) and 12 or 8
    lcd.drawLine(cx - pW/2, y + 8, cx + pW/2, y + 8, SOLID, 0)

    -- Wingtip Navigation Lights
    if frame == 1 then
        lcd.drawPoint(cx - 20, y - 4)
        lcd.drawPoint(cx + 20, y - 4)
    end
end

local function drawPoop(px, py)
    -- Dirt/mud clump on field
    lcd.drawFilledRectangle(px - 3, py + 1, 6, 3)
    lcd.drawFilledRectangle(px - 2, py - 1, 4, 2)
    lcd.drawPoint(px - 1, py - 2)
    lcd.drawPoint(px - 2, py - 4)
    lcd.drawPoint(px + 2, py - 4)
end

--------------------------------------------------------------------------------
-- DRAWING ROOM & USER INTERFACE
--------------------------------------------------------------------------------

local function drawTopIcons()
    local slotW = 21
    for i, name in ipairs(ICONS) do
        local x = (i - 1) * slotW + 1
        local isSel = (i == selectedIcon) and (currentMode == MODE_MAIN)
        
        if isSel then
            lcd.drawFilledRectangle(x, 1, slotW - 1, 9)
        end

        local flags = isSel and (SMLSIZE + INVERS) or SMLSIZE
        lcd.drawText(x + 1, 2, name, flags)
    end
    lcd.drawLine(0, 11, LCD_W - 1, 11, SOLID, 0)
end

local function drawStatusBar()
    local sName = "CASE"
    if pet.stage == STAGE_BABY then sName = "WHOOP"
    elseif pet.stage == STAGE_CHILD then sName = "TOOTH"
    elseif pet.stage == STAGE_ADULT_DRONE then sName = "5\"BEAST"
    elseif pet.stage == STAGE_ADULT_PIKA then sName = "CINE"
    elseif pet.stage == STAGE_ADULT_DINO then sName = "WING"
    end
    lcd.drawText(2, 13, sName, SMLSIZE)

    -- Radio Battery Voltage in Center (clean 10px margin)
    local volts, comment = getRadioBattInfo()
    lcd.drawText(54, 13, string.format("%.1fV", volts), SMLSIZE)

    -- Alerts on Right
    if pet.isSick then
        lcd.drawText(86, 13, "SERVICE", SMLSIZE + INVERS)
    elseif pet.poops > 0 then
        lcd.drawText(88, 13, pet.poops .. "xDIRT", SMLSIZE)
    elseif pet.hunger <= 1 and pet.stage ~= STAGE_EGG then
        lcd.drawText(92, 13, "LIPO!", SMLSIZE + BLINK)
    else
        lcd.drawText(94, 13, "OK", SMLSIZE)
    end

    lcd.drawLine(0, 21, LCD_W - 1, 21, SOLID, 0)
end

local function drawPlayfield()
    local now = getTime()

    if now - lastAnimTick > 30 then
        lastAnimTick = now
        animFrame = (animFrame == 0) and 1 or 0

        if not pet.isSleeping and pet.stage ~= STAGE_EGG and currentMode == MODE_MAIN then
            if math.random(1, 4) == 1 then
                petDir = (math.random(0, 1) == 1) and 1 or -1
            end
            petX = math.max(25, math.min(100, petX + petDir * 2))
        end
    end

    -- Floor
    lcd.drawLine(0, 53, LCD_W - 1, 53, DOTTED, 0)

    -- Sleep Mode (Shaded Dark Room)
    if pet.isSleeping then
        for x = 0, LCD_W - 1, 3 do
            lcd.drawLine(x, 22, x, 52, DOTTED, 0)
        end
        local zOff = (animFrame == 1) and 1 or 0
        lcd.drawText(petX + 12, petY - 5 - zOff, "z", SMLSIZE)
        lcd.drawText(petX + 18, petY - 10 - zOff, "Z", SMLSIZE)
    end

    -- Draw Drone Pet according to stage
    local isEating = (activeAnim == "EAT" and now < animTimer)
    local isWobble = (activeAnim == "WOBBLE" and now < animTimer)

    if pet.stage == STAGE_EGG then
        drawFlightCase(petX, petY + 4, isWobble)
    elseif pet.stage == STAGE_BABY then
        drawTinyWhoop(petX, petY + 4, animFrame, isEating)
    elseif pet.stage == STAGE_CHILD then
        drawToothpickQuad(petX, petY + 4, animFrame)
    elseif pet.stage == STAGE_ADULT_DRONE then
        drawFreestyle5Inch(petX, petY + 4, animFrame)
    elseif pet.stage == STAGE_ADULT_PIKA then
        drawCinewhoop(petX, petY + 4, animFrame)
    elseif pet.stage == STAGE_ADULT_DINO then
        drawFPVWing(petX, petY + 4, animFrame)
    end

    -- Hearts / Sparkles when happy
    if activeAnim == "HAPPY" and now < animTimer then
        lcd.drawText(petX - 16, petY - 8, "♥", SMLSIZE)
        lcd.drawText(petX + 12, petY - 8, "♥", SMLSIZE)
    end

    -- Shower Animation (Water stream)
    if activeAnim == "SHOWER" and now < animTimer then
        for i = 0, 4 do
            local dropY = 22 + ((now * 2 + i * 7) % 28)
            lcd.drawLine(petX - 6 + i * 3, dropY, petX - 6 + i * 3, dropY + 3, SOLID, 0)
        end
    end

    -- Dirt clumps on floor
    if pet.poops >= 1 then drawPoop(16, 50) end
    if pet.poops >= 2 then drawPoop(26, 50) end
    if pet.poops >= 3 then drawPoop(110, 50) end
end

local function drawBottomHint()
    local now = getTime()
    lcd.drawLine(0, 54, LCD_W - 1, 54, SOLID, 0)
    
    if now < messageExpireTime and petMessage ~= "" then
        lcd.drawText(4, 56, petMessage, SMLSIZE)
    else
        if pet.stage == STAGE_EGG then
            lcd.drawText(6, 56, "[SE] Charge   [RTN] Exit", SMLSIZE)
        else
            lcd.drawText(6, 56, "[SE] Action   [RTN] Exit", SMLSIZE)
        end
    end
end

--------------------------------------------------------------------------------
-- SUB-SCREENS: FEED MENU & STATS
--------------------------------------------------------------------------------

local function drawFeedMenu()
    local mx = 18
    local my = 17
    local mw = 92
    local mh = 34
    lcd.drawFilledRectangle(mx, my, mw, mh, ERASE)
    lcd.drawRectangle(mx, my, mw, mh)
    lcd.drawText(mx + 12, my + 3, "SELECT FOOD:", SMLSIZE)

    local items = { "1. LIPO (+2)", "2. SNACK (+1)" }
    for i, t in ipairs(items) do
        local iy = my + 13 + (i - 1) * 9
        if i == feedSubSelection then
            lcd.drawFilledRectangle(mx + 4, iy - 1, mw - 8, 9)
            lcd.drawText(mx + 8, iy, t, SMLSIZE + INVERS)
        else
            lcd.drawText(mx + 8, iy, t, SMLSIZE)
        end
    end
end

local function drawStatsScreen(resetHoldCount)
    lcd.clear()
    lcd.drawFilledRectangle(0, 0, LCD_W, 11)
    lcd.drawText(28, 2, "DRONE STATUS", INVERS + SMLSIZE)

    -- LiPo Hearts
    lcd.drawText(6, 13, "LIPO:", SMLSIZE)
    for h = 1, 4 do
        local fill = (h <= pet.hunger) and "♥" or "♡"
        lcd.drawText(46 + (h - 1) * 10, 13, fill, SMLSIZE)
    end

    -- Happiness Hearts
    lcd.drawText(6, 23, "HAPPY:", SMLSIZE)
    for h = 1, 4 do
        local fill = (h <= pet.happiness) and "♥" or "♡"
        lcd.drawText(46 + (h - 1) * 10, 23, fill, SMLSIZE)
    end

    -- Energy Bar
    lcd.drawText(6, 33, "POWER:", SMLSIZE)
    lcd.drawRectangle(46, 34, 44, 6)
    local eFill = math.floor((pet.energy / 100) * 42)
    if eFill > 0 then
        lcd.drawFilledRectangle(47, 35, eFill, 4)
    end
    lcd.drawText(96, 33, string.format("%d%%", math.floor(pet.energy)), SMLSIZE)

    -- Weight, Age
    lcd.drawText(6, 43, string.format("WT: %dg     TIME: %dm", pet.weight, math.floor(pet.ageMinutes)), SMLSIZE)

    -- Bottom line: Radio Battery & [ENT] Reset
    local volts = getRadioBattInfo()
    lcd.drawText(6, 53, string.format("%.1fV   [ENT] RESET", volts), SMLSIZE)

    lcd.drawLine(0, 63, LCD_W - 1, 63, SOLID, 0)
end

local function drawResetConfirm()
    local mx = 14
    local my = 14
    local mw = 100
    local mh = 36
    lcd.drawFilledRectangle(mx, my, mw, mh, ERASE)
    lcd.drawRectangle(mx, my, mw, mh)
    lcd.drawText(mx + 16, my + 4, "RESET PROGRESS?", SMLSIZE)
    lcd.drawText(mx + 22, my + 14, "START NEW EGG?", SMLSIZE)
    lcd.drawFilledRectangle(mx + 6, my + 24, 42, 9)
    lcd.drawText(mx + 10, my + 25, "[ENT] YES", INVERS + SMLSIZE)
    lcd.drawText(mx + 56, my + 25, "[RTN] NO", SMLSIZE)
end

--------------------------------------------------------------------------------
-- INPUT DETECTION (Pocket Tailored)
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

local function isExit(event)
    if not event or event == 0 then return false end
    return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

-- Shoulder SE button
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

local function resetPet()
    pet.stage = STAGE_EGG
    pet.eggWarmth = 0
    pet.hunger = 4
    pet.happiness = 4
    pet.energy = 100
    pet.isSleeping = false
    pet.poops = 0
    pet.isSick = false
    pet.ageMinutes = 0
    pet.weight = 5
    pet.careMistakes = 0
    pet.totalGamesPlayed = 0
    pet.discipline = 50
    petX = 64
    petY = 32
    savePetState()
    playSfx("hatch.wav")
    triggerMessage("RESET COMPLETE! New flight case!", 250)
end

-- Gimbal / Stick reading for navigation
local function getStickX()
    local ail = getValue("ail") or getValue("AIL") or 0
    local rud = getValue("rud") or getValue("RUD") or 0
    return (math.abs(ail) > math.abs(rud)) and ail or rud
end

--------------------------------------------------------------------------------
-- LIFECYCLE: INIT & RUN
--------------------------------------------------------------------------------

local function init()
    currentMode = MODE_MAIN
    loadPetState()
    playVolume = getRollerVolume()
    startupIgnoreUntil = getTime() + 40
    lastTickSec = getTime()
    statsIgnoreUntil = 0
    confirmIgnoreUntil = 0
    
    if pet.stage == STAGE_EGG then
        triggerMessage("Hello! Charge flight case [SE]!", 200)
    else
        playSfx("happy.wav")
        triggerMessage("Hello! Your drone is ready!", 200)
    end
end

local function run(event)
    local now = getTime()

    -- Volume roller update
    local newVol = getRollerVolume()
    if newVol ~= playVolume then
        playVolume = newVol
    end

    -- Exit Guard
    if isExit(event) and (now > startupIgnoreUntil) then
        if currentMode == MODE_CONFIRM_RESET then
            currentMode = MODE_STATS
            statsIgnoreUntil = now + 30
            return 0
        elseif currentMode == MODE_STATS or currentMode == MODE_FEED_MENU then
            currentMode = MODE_MAIN
            return 0
        elseif currentMode == MODE_MINIGAME then
            currentMode = MODE_MAIN
            return 0
        else
            savePetState()
            return 2
        end
    end

    updatePetNeeds()

    local sePressed = checkSeSwitch()
    local stickX = getStickX()

    ----------------------------------------------------------------------------
    -- MODE: MINI-GAME
    ----------------------------------------------------------------------------
    if currentMode == MODE_MINIGAME then
        updateMiniGame(stickX, isEnter(event), sePressed)
        drawMiniGame()
        return 0
    end

    ----------------------------------------------------------------------------
    -- MODE: STATS SCREEN (Click [ENT] to Reset)
    ----------------------------------------------------------------------------
    if currentMode == MODE_STATS then
        if isEnter(event) and (now > statsIgnoreUntil) then
            currentMode = MODE_CONFIRM_RESET
            confirmIgnoreUntil = now + 30
            return 0
        end
        drawStatsScreen()
        return 0
    end

    ----------------------------------------------------------------------------
    -- MODE: CONFIRM RESET DIALOG
    ----------------------------------------------------------------------------
    if currentMode == MODE_CONFIRM_RESET then
        if isEnter(event) and (now > confirmIgnoreUntil) then
            resetPet()
            currentMode = MODE_MAIN
            return 0
        end
        drawStatsScreen()
        drawResetConfirm()
        return 0
    end

    ----------------------------------------------------------------------------
    -- MODE: FEED SUBMENU
    ----------------------------------------------------------------------------
    if currentMode == MODE_FEED_MENU then
        if isNext(event) or stickX > 500 then
            feedSubSelection = 2
        elseif isPrev(event) or stickX < -500 then
            feedSubSelection = 1
        elseif (isEnter(event) or sePressed) and (now > startupIgnoreUntil) then
            if feedSubSelection == 1 then
                doFeedMeal()
            else
                doFeedSnack()
            end
            currentMode = MODE_MAIN
        end

        lcd.clear()
        drawTopIcons()
        drawStatusBar()
        drawPlayfield()
        drawFeedMenu()
        return 0
    end

    ----------------------------------------------------------------------------
    -- MODE: MAIN ROOM
    ----------------------------------------------------------------------------
    if now > startupIgnoreUntil then
        if sePressed then
            if pet.stage == STAGE_EGG then
                warmEgg()
            else
                doPetPraise()
            end
        end

        if isNext(event) then
            selectedIcon = (selectedIcon % #ICONS) + 1
        elseif isPrev(event) then
            selectedIcon = selectedIcon - 1
            if selectedIcon < 1 then selectedIcon = #ICONS end
        end

        if isEnter(event) then
            local action = ICONS[selectedIcon]
            if action == "FEED" then
                if pet.stage == STAGE_EGG then
                    triggerMessage("Case doesn't eat! Charge with [SE]", 150)
                else
                    currentMode = MODE_FEED_MENU
                    feedSubSelection = 1
                end
            elseif action == "REST" then
                if pet.stage == STAGE_EGG then
                    warmEgg()
                else
                    doToggleLight()
                end
            elseif action == "PLAY" then
                if pet.stage == STAGE_EGG then
                    triggerMessage("Hatch drone first!", 150)
                elseif pet.isSleeping then
                    triggerMessage("Sleeping! Wake up first!", 150)
                elseif pet.isSick then
                    triggerMessage("Glitch! Needs service!", 150)
                else
                    startMiniGame()
                end
            elseif action == "MEDS" then
                doMedicine()
            elseif action == "WASH" then
                doShower()
            elseif action == "STAT" then
                currentMode = MODE_STATS
                statsIgnoreUntil = now + 35
            end
        end
    end

    -- Draw Main Scene
    lcd.clear()
    drawTopIcons()
    drawStatusBar()
    drawPlayfield()
    drawBottomHint()

    return 0
end

return { init = init, run = run }
