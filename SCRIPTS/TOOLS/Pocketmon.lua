--[[
================================================================================
Pocketmon: Drone Edition - EdgeTX 128x64 Monochrome LCD Edition
Authentic FPV Drone RPG for RadioMaster Pocket / MT12
================================================================================
Controls:
  * Gimbals / Sticks (AIL/ELE/RUD) : 4-way D-Pad movement
  * Roller Scroll                   : Menu navigation
  * Roller Click [ENT]              : Select / Confirm / Attack
  * [RTN] Button                    : Cancel / Back / Start Menu
  * [SE] Switch                     : Action / Quick Repair at Paddock
================================================================================
]]--

local LCD_W = 128
local LCD_H = 64

-- Game States
local STATE_TITLE = 0
local STATE_STARTER_SELECT = 1
local STATE_OVERWORLD = 2
local STATE_START_MENU = 3
local STATE_BATTLE_INTRO = 4
local STATE_BATTLE_MENU = 5
local STATE_BATTLE_MOVES = 6
local STATE_BATTLE_BAG = 7
local STATE_BATTLE_DIALOGUE = 8
local STATE_CATCH_ANIM = 9

local gameState = STATE_TITLE

-- Timing & Debounce
local lastStepTime = 0
local msgTimer = 0
local afterMsgState = nil
local screenShake = 0
local startupIgnoreUntil = 0
local battleMsg = ""

-- Audio SFX Player
local function playSfx(file)
    playFile("/SOUNDS/POCKETMON/" .. file)
end

--------------------------------------------------------------------------------
-- BITMAPS & SPRITES
--------------------------------------------------------------------------------

local TILES = {
    [0] = { "........","........","........","........","........","........","........","........" },
    [1] = { ".#...#..","#.#.#.#.","#.###.#.","..#.#...","#...#.#.","#.#.#.#.","..#.#.#.","........" },
    [2] = { "..####..",".######.",".######.","########","########",".######.","...##...","...##..." },
    [3] = { "#..#..#.","########","#..#..#.","########","#..#..#.","#..#..#.",".#..#..#","........" },
    [4] = { "........","..####..","........","####....","........","..####..","........","####...." },
    [5] = { "########","########",".######.",".######.","..####..","..####..","...##...","........" },
    [6] = { "########","#..#..#.","########","..#..#..","########","#..#..#.","########","........" },
    [7] = { "..####..",".######.",".######.",".######.",".######.",".######.",".######.","........" },
    [8] = { "...##...","..####..",".######.","########","...##...","..####..",".######.","........" },
    [9] = { ".######.",".#....#.",".######.","...##...","...##...","...##...","...##...","........" }
}

local PLAYER_SPRITES = {
    DOWN  = { ".######.",".##..##.","..####..",".######.","..####..","..####..","..#..#..","..#..#.." },
    UP    = { ".######.",".######.","..####..",".######.","..####..","..####..","..#..#..","..#..#.." },
    LEFT  = { ".######.",".###....","..####..",".#####..","..####..","..####..","..##....","..##...." },
    RIGHT = { ".######.","....###.","..####..","..#####.","..####..","..####..","....##..","....##.." }
}

local BIND_SPRITE = {
    "...##...",
    "...##...",
    ".######.",
    "##.##.##",
    "...##...",
    "..####..",
    ".######.",
    "..####.."
}

local SPRITES_24 = {
    WHOOPY = {
        "....####........####....",
        "...######......######...",
        "..##.##.##....##.##.##..",
        "..######.######.######..",
        "...######..##..######...",
        "....####..####..####....",
        ".........######.........",
        "........########........",
        "..##....########....##..",
        ".####...###..###...####.",
        "######..###..###..######",
        "######..########..######",
        ".####...########...####.",
        "..##....########....##..",
        ".........######.........",
        "....####..####..####....",
        "...######..##..######...",
        "..######.######.######..",
        "..##.##.##....##.##.##..",
        "...######......######...",
        "....####........####....",
        "........................",
        "........................",
        "........................"
    },
    BEAST5 = {
        "###..................###",
        ".#####............#####.",
        "..######........######..",
        "...######......######...",
        "....######....######....",
        ".....######..######.....",
        "......############......",
        ".......##########.......",
        "........########........",
        ".........######.........",
        ".......##########.......",
        "......############......",
        "......############......",
        ".......##########.......",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......############......",
        ".....######..######.....",
        "....######....######....",
        "...######......######...",
        "..######........######..",
        ".#####............#####.",
        "###..................###"
    },
    TOOTHY = {
        "........................",
        "..##................##..",
        "...####..........####...",
        "....####........####....",
        ".....####......####.....",
        "......####....####......",
        ".......##########.......",
        "........########........",
        ".........######.........",
        ".........##..##.........",
        "........########........",
        ".......##########.......",
        ".......##########.......",
        "........########........",
        ".........##..##.........",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......####....####......",
        ".....####......####.....",
        "....####........####....",
        "...####..........####...",
        "..##................##..",
        "........................"
    },
    CINEMAX = {
        "..########....########..",
        ".##########..##########.",
        "############.###########",
        "############.###########",
        "###..##..##############.",
        "###..##..##############.",
        "############.###########",
        ".##########..##########.",
        "..########....########..",
        ".........######.........",
        "........########........",
        "........########........",
        "........########........",
        ".........######.........",
        "..########....########..",
        ".##########..##########.",
        "############.###########",
        "###..##..##############.",
        "###..##..##############.",
        "############.###########",
        "############.###########",
        ".##########..##########.",
        "..########....########..",
        "........................"
    },
    MOBULA7 = {
        "....####........####....",
        "...######......######...",
        "..########....########..",
        "..##.##.##....##.##.##..",
        "...######..##..######...",
        "....####..####..####....",
        ".........######.........",
        "........########........",
        "........###..###........",
        "........########........",
        ".........######.........",
        "....####..####..####....",
        "...######..##..######...",
        "..##.##.##....##.##.##..",
        "..########....########..",
        "...######......######...",
        "....####........####....",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................"
    },
    NAZGUL5 = {
        "##....................##",
        ".####..............####.",
        "..####............####..",
        "...####..........####...",
        "....####........####....",
        ".....#####....#####.....",
        "......############......",
        ".......##########.......",
        "........########........",
        ".........######.........",
        ".......##########.......",
        "......############......",
        "......############......",
        ".......##########.......",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......############......",
        ".....#####....#####.....",
        "....####........####....",
        "...####..........####...",
        "..####............####..",
        ".####..............####.",
        "##....................##"
    },
    PHANTOM = {
        "........................",
        "...........##...........",
        "..........####..........",
        ".........######.........",
        "........########........",
        ".......##########.......",
        "......############......",
        ".....##############.....",
        "....################....",
        "...##################...",
        "..####################..",
        "..##..############..##..",
        "..##...##########...##..",
        "..##....########....##..",
        "..##.....######.....##..",
        "..##......####......##..",
        "..##.......##.......##..",
        "..##................##..",
        "..##................##..",
        "..##................##..",
        ".####..............####.",
        "######............######",
        "........................",
        "........................"
    }
}

--------------------------------------------------------------------------------
-- MAP DATA (32 x 24 Tiles)
--------------------------------------------------------------------------------
local MAP_W = 32
local MAP_H = 24

local MAP_DATA = {
    {2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
    {2,2,1,1,1,1,2,2,1,1,1,1,2,2,0,0,0,2,2,1,1,1,1,2,2,1,1,1,1,2,2,2},
    {2,2,1,1,1,1,2,2,1,1,1,1,2,2,0,0,0,2,2,1,1,1,1,2,2,1,1,1,1,2,2,2},
    {2,2,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2},
    {2,2,2,2,3,3,3,3,0,0,0,0,3,3,3,0,3,3,3,0,0,0,0,3,3,3,3,2,2,2,2,2},
    {2,2,1,1,1,1,1,1,0,0,0,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,1,2,2,2},
    {2,2,1,1,1,1,1,1,0,0,9,0,1,1,1,0,1,1,1,0,0,0,0,1,1,1,1,1,1,2,2,2},
    {2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {2,2,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,2},
    {2,2,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,2},
    {2,2,3,3,3,3,3,3,0,0,0,0,2,2,2,0,2,2,2,0,0,0,3,3,3,3,3,3,0,2,2,2},
    {2,2,1,1,1,1,1,1,0,0,0,0,2,2,2,0,2,2,2,0,0,0,1,1,1,1,1,1,0,2,2,2},
    {2,2,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,2,2,2},
    {2,2,2,2,2,2,2,2,3,3,0,0,0,0,0,9,0,0,0,0,3,3,2,2,2,2,2,2,2,2,2,2},
    {2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2},
    {2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2},
    {2,2,0,5,5,5,0,0,0,0,0,5,5,5,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,0,6,6,6,0,0,0,0,0,6,6,6,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,0,6,7,6,0,8,8,0,0,6,7,6,0,8,8,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,0,0,0,5,5,5,5,0,0,0,0,0,0,0,0,0,0,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,0,0,0,6,6,6,6,0,0,0,0,9,0,0,0,8,8,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,0,0,0,6,7,6,6,0,0,0,0,0,0,0,0,8,8,0,0,4,4,4,4,4,4,2,2,2,2,2},
    {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}
}

--------------------------------------------------------------------------------
-- DRONEDEX & MOVES DATABASE
--------------------------------------------------------------------------------

local DRONEDEX = {
    WHOOPY   = { type = "MICRO", hp = 22, atk = 13, def = 9,  spd = 16, spr = "WHOOPY",  moves = { "THROTTLE PUNCH", "PROP CHOP", "TURTLE MODE" } },
    BEAST5   = { type = "ACRO",  hp = 26, atk = 16, def = 12, spd = 12, spr = "BEAST5",  moves = { "POWER LOOP", "PROP CHOP", "BEEPER BLAST" } },
    TOOTHY   = { type = "RACE",  hp = 20, atk = 14, def = 8,  spd = 18, spr = "TOOTHY",  moves = { "THROTTLE PUNCH", "YAW SPIN", "TURTLE MODE" } },
    CINEMAX  = { type = "CINE",  hp = 28, atk = 11, def = 15, spd = 9,  spr = "CINEMAX", moves = { "DUST BLOW", "PROP CHOP", "SMOOTH ROLL" } },
    MOBULA7  = { type = "MICRO", hp = 18, atk = 11, def = 8,  spd = 14, spr = "MOBULA7", moves = { "PROP CHOP", "YAW SPIN" } },
    NAZGUL5  = { type = "ACRO",  hp = 24, atk = 15, def = 11, spd = 13, spr = "NAZGUL5", moves = { "POWER LOOP", "PROP CHOP", "BEEPER BLAST" } },
    PHANTOM  = { type = "GPS",   hp = 30, atk = 10, def = 16, spd = 7,  spr = "PHANTOM", moves = { "RETURN HOME", "DUST BLOW" } }
}

local MOVES = {
    THROTTLE_PUNCH = { power = 14, type = "ACRO",  pp = 25 },
    PROP_CHOP      = { power = 10, type = "MICRO", pp = 30 },
    POWER_LOOP     = { power = 15, type = "ACRO",  pp = 20 },
    YAW_SPIN       = { power = 11, type = "RACE",  pp = 25 },
    SMOOTH_ROLL    = { power = 12, type = "CINE",  pp = 25 },
    DUST_BLOW      = { power = 8,  type = "CINE",  pp = 30 },
    RETURN_HOME    = { power = 14, type = "GPS",   pp = 15 },
    TURTLE_MODE    = { power = 0,  type = "MICRO", pp = 40 },
    BEEPER_BLAST   = { power = 0,  type = "ACRO",  pp = 40 }
}

--------------------------------------------------------------------------------
-- GAME STATE & VARIABLES
--------------------------------------------------------------------------------

local playerX = 14
local playerY = 19
local playerFacing = "DOWN"
local hangar = {}
local activeDroneIdx = 1
local bag = { packets = 5, lipos = 3 }

local starterKeys = { "WHOOPY", "BEAST5", "TOOTHY", "CINEMAX" }
local starterLabels = { "WHOOPY", "5\"BEAST", "TOOTHY", "CINEMAX" }
local starterSel = 1

local menuItems = { "HANGAR", "GEAR", "SAVE", "EXIT" }
local menuSel = 1

local enemyDrone = nil
local battleMenuSel = 0  -- 0: FIGHT, 1: BAG, 2: HANGAR, 3: DISARM
local battleMoveSel = 1
local battleBagSel = 1

local catchStep = 0
local catchTimer = 0
local catchWiggles = 0
local catchSuccess = false

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function createDrone(key, level)
    local base = DRONEDEX[key]
    local hpMax = base.hp + (level * 3)
    local movesCopy = {}
    for i = 1, #base.moves do
        movesCopy[i] = base.moves[i]
    end
    return {
        key = key,
        name = (key == "BEAST5" and "5\"BEAST") or (key == "MOBULA7" and "MOBULA 7") or (key == "NAZGUL5" and "NAZGUL 5") or key,
        level = level,
        hp = hpMax,
        maxHp = hpMax,
        atk = base.atk + (level * 2),
        def = base.def + (level * 2),
        spd = base.spd + (level * 2),
        type = base.type,
        spr = base.spr,
        moves = movesCopy,
        exp = 0,
        nextExp = level * 15
    }
end

local function triggerDialogue(msg, nextState, duration)
    battleMsg = msg
    afterMsgState = nextState
    gameState = STATE_BATTLE_DIALOGUE
    msgTimer = getTime() + (duration or 140)
end

local function drawSprite8x8(x, y, rows)
    for r = 1, 8 do
        local row = rows[r]
        local py = y + r - 1
        if py >= 0 and py < LCD_H then
            for c = 1, 8 do
                local px = x + c - 1
                if px >= 0 and px < LCD_W then
                    if string.byte(row, c) == 35 then
                        lcd.drawPoint(px, py)
                    end
                end
            end
        end
    end
end

local function drawSprite24x24(x, y, rows)
    for r = 1, 24 do
        local row = rows[r]
        local py = y + r - 1
        if py >= 0 and py < LCD_H then
            for c = 1, 24 do
                local px = x + c - 1
                if px >= 0 and px < LCD_W then
                    if string.byte(row, c) == 35 then
                        lcd.drawPoint(px, py)
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- SAVE & LOAD
--------------------------------------------------------------------------------

local SAVE_PATH = "/SCRIPTS/TOOLS/POCKETMON/save.dat"

local function saveGame()
    local f = io.open(SAVE_PATH, "w")
    if f then
        f:write(string.format("%d,%d,%d,%d\n", playerX, playerY, bag.packets, bag.lipos))
        f:write(string.format("%d\n", #hangar))
        for i = 1, #hangar do
            local p = hangar[i]
            f:write(string.format("%s,%d,%d,%d,%d,%d\n", p.key, p.level, p.hp, p.maxHp, p.atk, p.exp))
        end
        io.close(f)
        playSfx("catch.wav")
        triggerDialogue("HANGAR SAVED SAFELY!", STATE_OVERWORLD, 150)
    end
end

local function loadGame()
    local f = io.open(SAVE_PATH, "r")
    if f then
        local line1 = io.readline(f)
        if line1 then
            local parts = {}
            for val in string.gmatch(line1, "[^,]+") do
                parts[#parts + 1] = tonumber(val)
            end
            if #parts >= 4 then
                playerX = parts[1]
                playerY = parts[2]
                bag.packets = parts[3]
                bag.lipos = parts[4]
            end
            local lineCount = io.readline(f)
            local pCount = tonumber(lineCount) or 0
            hangar = {}
            for i = 1, pCount do
                local pLine = io.readline(f)
                if pLine then
                    local pParts = {}
                    for v in string.gmatch(pLine, "[^,]+") do
                        pParts[#pParts + 1] = v
                    end
                    if #pParts >= 6 then
                        local dKey = pParts[1]
                        local pLvl = tonumber(pParts[2]) or 5
                        local pk = createDrone(dKey, pLvl)
                        pk.hp = tonumber(pParts[3]) or pk.maxHp
                        pk.maxHp = tonumber(pParts[4]) or pk.maxHp
                        pk.atk = tonumber(pParts[5]) or pk.atk
                        pk.exp = tonumber(pParts[6]) or 0
                        hangar[#hangar + 1] = pk
                    end
                end
            end
        end
        io.close(f)
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- INPUT DETECTION
--------------------------------------------------------------------------------

local function isEnter(event)
    if not event or event == 0 then return false end
    return event == EVT_ENTER_BREAK or event == EVT_VIRTUAL_ENTER or event == EVT_ROT_BREAK
end

local function isExit(event)
    if not event or event == 0 then return false end
    return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

local function isNext(event)
    if not event or event == 0 then return false end
    return event == EVT_ROT_RIGHT or event == EVT_PAGE_BREAK
end

local function isPrev(event)
    if not event or event == 0 then return false end
    return event == EVT_ROT_LEFT or event == EVT_PAGE_LONG
end

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

local function getStickMove()
    -- Dedicated to Right Gimbal (AIL = X, ELE = Y)
    local ail = getValue("ail") or getValue("AIL") or 0
    local ele = getValue("ele") or getValue("ELE") or 0

    local DEADZONE = 200

    if math.abs(ail) > DEADZONE or math.abs(ele) > DEADZONE then
        if math.abs(ail) > math.abs(ele) then
            return (ail > 0) and 1 or -1, 0  -- Right (+), Left (-)
        else
            return 0, (ele > 0) and -1 or 1  -- Up (-1), Down (+1)
        end
    end
    return 0, 0
end

--------------------------------------------------------------------------------
-- BATTLE MECHANICS
--------------------------------------------------------------------------------

local function triggerWildEncounter()
    playSfx("battle.wav")
    local r = math.random(1, 100)
    local eKey = "MOBULA7"
    local eLvl = math.random(2, 4)

    if r <= 45 then
        eKey = "MOBULA7"
        eLvl = math.random(2, 4)
    elseif r <= 80 then
        eKey = "NAZGUL5"
        eLvl = math.random(2, 4)
    elseif r <= 94 then
        eKey = "TOOTHY"
        eLvl = math.random(2, 3)
    else
        eKey = "PHANTOM"
        eLvl = math.random(4, 6)
    end

    enemyDrone = createDrone(eKey, eLvl)
    triggerDialogue("Rogue " .. enemyDrone.name .. " buzzed in!", STATE_BATTLE_MENU, 150)
end

local function executeTurn(pMoveName)
    local player = hangar[activeDroneIdx]
    local enemy = enemyDrone
    local mKey = string.gsub(pMoveName, " ", "_")
    local pMove = MOVES[mKey] or { power = 10, type = "ACRO" }

    playSfx("hit.wav")
    screenShake = 3

    local dmg = math.max(1, math.floor(pMove.power * (player.atk / enemy.def) * (0.85 + math.random() * 0.3)))
    if (pMove.type == "ACRO" and enemy.type == "GPS") or
       (pMove.type == "RACE" and enemy.type == "ACRO") or
       (pMove.type == "CINE" and enemy.type == "RACE") or
       (pMove.type == "MICRO" and enemy.type == "CINE") then
        dmg = math.floor(dmg * 1.5)
    end

    enemy.hp = math.max(0, enemy.hp - dmg)

    if enemy.hp == 0 then
        playSfx("faint.wav")
        local expGain = enemy.level * 8
        player.exp = player.exp + expGain
        if player.exp >= player.nextExp then
            player.level = player.level + 1
            player.maxHp = player.maxHp + 3
            player.hp = player.maxHp
            player.atk = player.atk + 2
            player.def = player.def + 2
            player.spd = player.spd + 2
            player.nextExp = player.level * 15
            playSfx("levelup.wav")
            triggerDialogue(player.name .. " tuned to Lv " .. player.level .. "!", STATE_OVERWORLD, 160)
        else
            triggerDialogue("Rogue " .. enemy.name .. " crashed!", STATE_OVERWORLD, 150)
        end
        return
    end

    local eMoveName = enemy.moves[math.random(1, #enemy.moves)]
    local eKey = string.gsub(eMoveName, " ", "_")
    local eMove = MOVES[eKey] or { power = 10, type = "ACRO" }
    playSfx("hit.wav")
    local eDmg = math.max(1, math.floor(eMove.power * (enemy.atk / player.def) * (0.85 + math.random() * 0.3)))
    player.hp = math.max(0, player.hp - eDmg)

    if player.hp == 0 then
        playSfx("faint.wav")
        for i = 1, #hangar do
            hangar[i].hp = hangar[i].maxHp
        end
        playerX = 14
        playerY = 19
        triggerDialogue(player.name .. " crashed! Repaired at Paddock!", STATE_OVERWORLD, 170)
        return
    end

    triggerDialogue(player.name .. " hit " .. dmg .. "! Rogue used " .. eMoveName .. "!", STATE_BATTLE_MENU, 150)
end

local function startBindAttempt()
    gameState = STATE_CATCH_ANIM
    catchStep = 1
    catchTimer = getTime() + 60
    catchWiggles = 0
    local hpRatio = enemyDrone.hp / enemyDrone.maxHp
    local chance = 0.85 - (hpRatio * 0.5)
    catchSuccess = (math.random() < chance)
end

--------------------------------------------------------------------------------
-- RENDERING ROUTINES (128x64)
--------------------------------------------------------------------------------

local function drawTitle()
    lcd.clear()
    lcd.drawText(16, 10, "POCKETMON", MIDSIZE)
    lcd.drawText(24, 26, "DRONE EDITION", SMLSIZE)
    
    local bobY = 38 + math.floor(math.sin(getTime() / 15) * 2)
    drawSprite8x8(60, bobY, BIND_SPRITE)

    if (math.floor(getTime() / 40) % 2 == 0) then
        lcd.drawText(18, 52, "PRESS [ENT] TO ARM", SMLSIZE)
    end
end

local function drawStarterSelect()
    lcd.clear()
    lcd.drawFilledRectangle(0, 0, LCD_W, 11)
    lcd.drawText(6, 2, "CHOOSE YOUR FIRST QUAD!", INVERS + SMLSIZE)

    local choiceKey = starterKeys[starterSel]
    local label = starterLabels[starterSel]
    local sprKey = DRONEDEX[choiceKey].spr
    local spr = SPRITES_24[sprKey]
    if spr then
        drawSprite24x24(52, 15, spr)
    end

    lcd.drawText(30, 42, "< " .. label .. " >", SMLSIZE)
    local base = DRONEDEX[choiceKey]
    lcd.drawText(6, 53, string.format("T:%s HP:%d ATK:%d SPD:%d", base.type, base.hp, base.atk, base.spd), SMLSIZE)
end

local function drawOverworld()
    lcd.clear()
    local camX = math.max(0, math.min(MAP_W - 16, playerX - 8))
    local camY = math.max(0, math.min(MAP_H - 8, playerY - 4))

    for ty = 0, 7 do
        for tx = 0, 15 do
            local mx = camX + tx + 1
            local my = camY + ty + 1
            local tRow = MAP_DATA[my]
            if tRow then
                local tIdx = tRow[mx] or 0
                local tSpr = TILES[tIdx]
                if tSpr then
                    drawSprite8x8(tx * 8, ty * 8, tSpr)
                end
            end
        end
    end

    local px = (playerX - camX) * 8
    local py = (playerY - camY) * 8
    local pSpr = PLAYER_SPRITES[playerFacing] or PLAYER_SPRITES.DOWN
    drawSprite8x8(px, py, pSpr)
end

local function drawStartMenu()
    drawOverworld()
    local mx = 78
    local my = 2
    local mw = 48
    local mh = 58
    lcd.drawFilledRectangle(mx, my, mw, mh, ERASE)
    lcd.drawRectangle(mx, my, mw, mh)

    for i = 1, #menuItems do
        local y = my + 4 + (i - 1) * 13
        local pfx = (i == menuSel) and ">" or " "
        lcd.drawText(mx + 4, y, pfx .. menuItems[i], SMLSIZE)
    end
end

local function drawBattle()
    lcd.clear()
    local offX = 0
    if screenShake > 0 then
        offX = math.random(-screenShake, screenShake)
        screenShake = screenShake - 1
    end

    local enemy = enemyDrone
    lcd.drawText(4 + offX, 2, enemy.name .. " Lv" .. enemy.level, SMLSIZE)
    lcd.drawRectangle(4, 11, 46, 5)
    local ePct = math.max(0, math.min(1, enemy.hp / enemy.maxHp))
    local eFill = math.floor(ePct * 44)
    if eFill > 0 then
        lcd.drawFilledRectangle(5, 12, eFill, 3)
    end

    if gameState == STATE_CATCH_ANIM and catchStep >= 1 then
        local wigOff = (catchWiggles % 2 == 1) and -2 or 2
        drawSprite8x8(86 + wigOff, 12, BIND_SPRITE)
    else
        local eSpr = SPRITES_24[enemy.spr]
        if eSpr then
            drawSprite24x24(80 + offX, 2, eSpr)
        end
    end

    local player = hangar[activeDroneIdx]
    local pSpr = SPRITES_24[player.spr]
    if pSpr then
        drawSprite24x24(6, 18, pSpr)
    end

    lcd.drawText(68, 20, player.name .. " Lv" .. player.level, SMLSIZE)
    lcd.drawRectangle(68, 29, 54, 5)
    local pPct = math.max(0, math.min(1, player.hp / player.maxHp))
    local pFill = math.floor(pPct * 52)
    if pFill > 0 then
        lcd.drawFilledRectangle(69, 30, pFill, 3)
    end
    lcd.drawText(68, 36, string.format("HP:%d/%d", player.hp, player.maxHp), SMLSIZE)

    lcd.drawFilledRectangle(0, 44, LCD_W, 20, ERASE)
    lcd.drawRectangle(0, 44, LCD_W, 20)

    if gameState == STATE_BATTLE_DIALOGUE then
        lcd.drawText(4, 50, battleMsg, SMLSIZE)

    elseif gameState == STATE_CATCH_ANIM then
        local wTxt = (catchWiggles > 0) and ("Binding... Packet " .. catchWiggles) or "Sending ELRS Bind phrase!"
        lcd.drawText(4, 50, wTxt, SMLSIZE)

    elseif gameState == STATE_BATTLE_MENU then
        local opts = { "FIGHT", "BAG", "HANGAR", "DISARM" }
        local coords = { { 6, 48 }, { 64, 48 }, { 6, 56 }, { 64, 56 } }
        for i = 1, 4 do
            local pfx = (i - 1 == battleMenuSel) and ">" or " "
            lcd.drawText(coords[i][1], coords[i][2], pfx .. opts[i], SMLSIZE)
        end

    elseif gameState == STATE_BATTLE_MOVES then
        local moves = player.moves
        for i = 1, math.min(2, #moves) do
            local pfx = (i == battleMoveSel) and ">" or " "
            lcd.drawText(4, 46 + (i - 1) * 8, pfx .. moves[i], SMLSIZE)
        end
        lcd.drawText(94, 50, "[RTN]", SMLSIZE)

    elseif gameState == STATE_BATTLE_BAG then
        local bPfx = (battleBagSel == 1) and ">" or " "
        local pPfx = (battleBagSel == 2) and ">" or " "
        lcd.drawText(4, 46, string.format("%sPACKET x%d", bPfx, bag.packets), SMLSIZE)
        lcd.drawText(4, 54, string.format("%sLIPO 4S x%d", pPfx, bag.lipos), SMLSIZE)
        lcd.drawText(94, 50, "[RTN]", SMLSIZE)
    end
end

--------------------------------------------------------------------------------
-- MAIN LIFECYCLE
--------------------------------------------------------------------------------

local function init()
    math.randomseed(getTime())
    playSfx("intro.wav")
    startupIgnoreUntil = getTime() + 40
    lastStepTime = getTime()

    local loaded = loadGame()
    if loaded and #hangar > 0 then
        gameState = STATE_OVERWORLD
    else
        gameState = STATE_TITLE
    end
end

local function run(event)
    local now = getTime()

    if gameState == STATE_BATTLE_DIALOGUE then
        if now > msgTimer then
            if afterMsgState then
                gameState = afterMsgState
                afterMsgState = nil
            end
        end
    end

    if gameState == STATE_CATCH_ANIM then
        if now >= catchTimer then
            if catchStep <= 3 then
                catchWiggles = catchWiggles + 1
                playSfx("select.wav")
                catchStep = catchStep + 1
                catchTimer = now + 50
            else
                if catchSuccess then
                    playSfx("catch.wav")
                    hangar[#hangar + 1] = enemyDrone
                    triggerDialogue("Telemetry Bound! " .. enemyDrone.name .. " in Hangar!", STATE_OVERWORLD, 160)
                else
                    playSfx("faint.wav")
                    triggerDialogue("Signal lost! Quad failed to bind!", STATE_BATTLE_MENU, 150)
                end
            end
        end
    end

    if gameState == STATE_OVERWORLD and (now > lastStepTime) then
        local sx, sy = getStickMove()
        if sx ~= 0 or sy ~= 0 then
            if sx > 0 then playerFacing = "RIGHT"
            elseif sx < 0 then playerFacing = "LEFT"
            elseif sy > 0 then playerFacing = "DOWN"
            elseif sy < 0 then playerFacing = "UP"
            end

            local nx = playerX + sx
            local ny = playerY + sy
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                local tRow = MAP_DATA[ny]
                if tRow then
                    local tile = tRow[nx]
                    if tile ~= 2 and tile ~= 3 and tile ~= 4 and tile ~= 5 and tile ~= 6 and tile ~= 9 then
                        playerX = nx
                        playerY = ny
                        lastStepTime = now + 18

                        if tile == 1 and math.random(1, 100) <= 18 then
                            triggerWildEncounter()
                        end
                    else
                        lastStepTime = now + 15
                    end
                end
            end
        end
    end

    if checkSeSwitch() and gameState == STATE_OVERWORLD then
        for i = 1, #hangar do
            hangar[i].hp = hangar[i].maxHp
        end
        playSfx("levelup.wav")
    end

    if now > startupIgnoreUntil then
        if isNext(event) then
            if gameState == STATE_OVERWORLD then
                local dx, dy = 0, 0
                if playerFacing == "RIGHT" then dx = 1
                elseif playerFacing == "LEFT" then dx = -1
                elseif playerFacing == "DOWN" then dy = 1
                elseif playerFacing == "UP" then dy = -1
                end
                local nx, ny = playerX + dx, playerY + dy
                if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                    local tRow = MAP_DATA[ny]
                    if tRow and tRow[nx] ~= 2 and tRow[nx] ~= 3 and tRow[nx] ~= 4 and tRow[nx] ~= 5 and tRow[nx] ~= 6 and tRow[nx] ~= 9 then
                        playerX = nx
                        playerY = ny
                        lastStepTime = now + 18
                        if tRow[nx] == 1 and math.random(1, 100) <= 18 then
                            triggerWildEncounter()
                        end
                    end
                end
            elseif gameState == STATE_STARTER_SELECT then
                starterSel = (starterSel % #starterKeys) + 1
                playSfx("select.wav")
            elseif gameState == STATE_START_MENU then
                menuSel = (menuSel % #menuItems) + 1
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MENU then
                battleMenuSel = (battleMenuSel + 1) % 4
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MOVES then
                local player = hangar[activeDroneIdx]
                battleMoveSel = (battleMoveSel % #player.moves) + 1
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_BAG then
                battleBagSel = (battleBagSel == 1) and 2 or 1
                playSfx("select.wav")
            end

        elseif isPrev(event) then
            if gameState == STATE_OVERWORLD then
                if playerFacing == "DOWN" then playerFacing = "UP"
                elseif playerFacing == "UP" then playerFacing = "DOWN"
                elseif playerFacing == "LEFT" then playerFacing = "RIGHT"
                elseif playerFacing == "RIGHT" then playerFacing = "LEFT"
                end
            elseif gameState == STATE_STARTER_SELECT then
                starterSel = starterSel - 1
                if starterSel < 1 then starterSel = #starterKeys end
                playSfx("select.wav")
            elseif gameState == STATE_START_MENU then
                menuSel = menuSel - 1
                if menuSel < 1 then menuSel = #menuItems end
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MENU then
                battleMenuSel = (battleMenuSel + 3) % 4
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MOVES then
                local player = hangar[activeDroneIdx]
                battleMoveSel = battleMoveSel - 1
                if battleMoveSel < 1 then battleMoveSel = #player.moves end
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_BAG then
                battleBagSel = (battleBagSel == 1) and 2 or 1
                playSfx("select.wav")
            end

        elseif isEnter(event) then
            if gameState == STATE_TITLE then
                playSfx("select.wav")
                if #hangar == 0 then
                    gameState = STATE_STARTER_SELECT
                else
                    gameState = STATE_OVERWORLD
                end

            elseif gameState == STATE_STARTER_SELECT then
                local choiceKey = starterKeys[starterSel]
                hangar[1] = createDrone(choiceKey, 5)
                activeDroneIdx = 1
                playSfx("catch.wav")
                gameState = STATE_OVERWORLD

            elseif gameState == STATE_START_MENU then
                local item = menuItems[menuSel]
                if item == "EXIT" or item == "HANGAR" then
                    gameState = STATE_OVERWORLD
                elseif item == "SAVE" then
                    saveGame()
                end

            elseif gameState == STATE_BATTLE_DIALOGUE then
                if afterMsgState then
                    gameState = afterMsgState
                    afterMsgState = nil
                end

            elseif gameState == STATE_BATTLE_MENU then
                if battleMenuSel == 0 then  -- FIGHT
                    battleMoveSel = 1
                    gameState = STATE_BATTLE_MOVES
                    playSfx("select.wav")
                elseif battleMenuSel == 1 then  -- BAG
                    battleBagSel = 1
                    gameState = STATE_BATTLE_BAG
                    playSfx("select.wav")
                elseif battleMenuSel == 2 then  -- HANGAR
                    triggerDialogue("Only 1 Quad in Hangar!", STATE_BATTLE_MENU, 120)
                elseif battleMenuSel == 3 then  -- DISARM
                    playSfx("run.wav")
                    triggerDialogue("Disarmed & flew away safely!", STATE_OVERWORLD, 140)
                end

            elseif gameState == STATE_BATTLE_MOVES then
                local player = hangar[activeDroneIdx]
                local mName = player.moves[battleMoveSel]
                executeTurn(mName)

            elseif gameState == STATE_BATTLE_BAG then
                if battleBagSel == 1 then
                    if bag.packets > 0 then
                        bag.packets = bag.packets - 1
                        startBindAttempt()
                    else
                        triggerDialogue("No BIND PACKETS!", STATE_BATTLE_BAG, 120)
                    end
                else
                    if bag.lipos > 0 then
                        bag.lipos = bag.lipos - 1
                        local player = hangar[activeDroneIdx]
                        player.hp = math.min(player.maxHp, player.hp + 20)
                        playSfx("levelup.wav")
                        triggerDialogue("Swapped LiPo! +20 mAh to " .. player.name .. "!", STATE_BATTLE_MENU, 140)
                    else
                        triggerDialogue("No LIPO PACKS!", STATE_BATTLE_BAG, 120)
                    end
                end
            end

        elseif isExit(event) then
            if gameState == STATE_OVERWORLD then
                gameState = STATE_START_MENU
                menuSel = 1
                playSfx("select.wav")
            elseif gameState == STATE_START_MENU then
                gameState = STATE_OVERWORLD
            elseif gameState == STATE_BATTLE_MOVES or gameState == STATE_BATTLE_BAG then
                gameState = STATE_BATTLE_MENU
                playSfx("select.wav")
            elseif gameState == STATE_TITLE then
                return 2
            end
        end
    end

    if gameState == STATE_TITLE then
        drawTitle()
    elseif gameState == STATE_STARTER_SELECT then
        drawStarterSelect()
    elseif gameState == STATE_OVERWORLD then
        drawOverworld()
    elseif gameState == STATE_START_MENU then
        drawStartMenu()
    elseif gameState >= STATE_BATTLE_INTRO and gameState <= STATE_CATCH_ANIM then
        drawBattle()
    end

    return 0
end

return { init = init, run = run }
