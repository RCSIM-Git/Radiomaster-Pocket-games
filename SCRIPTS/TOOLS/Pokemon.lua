--[[
================================================================================
Pokemon Classic - EdgeTX 128x64 Monochrome LCD Edition
Authentic Gen 1 Game Boy Experience for RadioMaster Pocket / MT12
================================================================================
Controls:
  * Gimbals / Sticks (AIL/ELE/RUD) : 4-way D-Pad movement
  * Roller Scroll                   : Menu navigation (Up / Down / Left / Right)
  * Roller Click [ENT]              : Select / Confirm / Attack
  * [RTN] Button                    : Cancel / Back / Start Menu
  * [SE] Switch                     : Action / Quick Heal at Home
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
local STATE_PARTY_VIEW = 10

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
    playFile("/SOUNDS/POKEMON/" .. file)
end

--------------------------------------------------------------------------------
-- BITMAPS & SPRITES (1-bit ASCII strings for maximum portability)
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
    [8] = { "........","...#....","..###...","...#....","........","....#...","...###..","....#..." },
    [9] = { ".######.",".#....#.",".######.","...##...","...##...","...##...","...##...","........" }
}

local PLAYER_SPRITES = {
    DOWN  = { "..####..","..####..",".######.",".######.","..####..","..####..","..#..#..","..#..#.." },
    UP    = { "..####..","..####..",".######.",".######.","..####..","..####..","..#..#..","..#..#.." },
    LEFT  = { "..####..",".#####..","..####..",".#####..","..####..","..####..","..##....","..##...." },
    RIGHT = { "..####..","..#####.","..####..","..#####.","..####..","..####..","....##..","....##.." }
}

local POKEBALL_SPRITE = {
    "..####..",
    ".######.",
    "########",
    "###..###",
    "########",
    ".######.",
    "..####..",
    "........"
}

local SPRITES_24 = {
    PIKACHU = {
        "......##........##......",
        ".....####......####.....",
        ".....####......####.....",
        "......##........##......",
        ".......##########.......",
        "......############......",
        ".....##############.....",
        "....################....",
        "....###..######..###....",
        "....###..######..###....",
        "....################....",
        "....##.##########.##....",
        "....################....",
        ".....##############.....",
        "......############......",
        ".....##############.....",
        "....################....",
        "...##################...",
        "...####..######..####...",
        "...####..........####...",
        "...####..........####.##",
        "....###..........######.",
        ".....##..........####...",
        "......############......"
    },
    CHARMANDER = {
        "........######..........",
        ".......########.........",
        "......##########........",
        ".....############.......",
        ".....###..#######.......",
        ".....###..#######.......",
        ".....############.......",
        "......##########........",
        ".......########.........",
        "........######..........",
        ".......########.........",
        "......##########........",
        ".....############.......",
        ".....############.......",
        ".....############.....#.",
        "......##########.....###",
        "......##########....####",
        ".......########....#####",
        ".......########...######",
        "......##########.#####..",
        ".....####....########...",
        ".....####....#######....",
        "......##......#####.....",
        "...............###......"
    },
    SQUIRTLE = {
        "........######..........",
        "......##########........",
        ".....############.......",
        "....##############......",
        "....###..####..###......",
        "....###..####..###......",
        "....##############......",
        ".....############.......",
        "......##########........",
        "....##############......",
        "...################.....",
        "..##################....",
        "..######......######....",
        "..######......######....",
        "..##################..##",
        "...################..###",
        "....##############..####",
        ".....############..####.",
        "......##########..####..",
        ".....####....####.###...",
        "....######..######......",
        "....######..######......",
        ".....####....####.......",
        "........................"
    },
    BULBASAUR = {
        "........................",
        ".........####...........",
        "........######..........",
        ".......########.........",
        "......##########........",
        ".....############.......",
        ".....############.......",
        "....###..####..###......",
        "....###..####..###......",
        "....##############......",
        ".....############.......",
        "....##############......",
        "...################.....",
        "..##################....",
        "..##################....",
        "..##################....",
        "..##################....",
        "...################.....",
        "....##############......",
        "....####......####......",
        "...######....######.....",
        "...######....######.....",
        "....####......####......",
        "........................"
    },
    PIDGEY = {
        "...........####.........",
        "..........######........",
        ".........########.......",
        "........##########......",
        "........###..#####......",
        "........###..#####......",
        "........##########......",
        ".........########.......",
        ".......############.....",
        "......##############....",
        ".....################...",
        "....##################..",
        "....##################..",
        ".....#################..",
        "......################..",
        ".......##############...",
        "........############....",
        ".........##########.....",
        "..........########......",
        "...........######.......",
        "...........##..##.......",
        "..........###..###......",
        "..........###..###......",
        "...........##...##......"
    },
    RATTATA = {
        ".....##........##.......",
        "....####......####......",
        "....####......####......",
        ".....##........##.......",
        "......##########........",
        ".....############.......",
        "....##############......",
        "....###..####..###......",
        "....###..####..###......",
        "....##############......",
        ".....############.......",
        "....##############......",
        "...################.....",
        "..##################..##",
        "..##################.###",
        "..#####################.",
        "...###################..",
        "....################....",
        ".....##############.....",
        "....####........####....",
        "...######......######...",
        "...######......######...",
        "....####........####....",
        "........................"
    },
    CATERPIE = {
        "........#..#............",
        ".........##.............",
        ".......######...........",
        "......########..........",
        ".....##########.........",
        ".....###..#####.........",
        ".....##########.........",
        "......########..........",
        ".......######...........",
        "......########..........",
        ".....##########.........",
        ".....##########.........",
        "......########..........",
        ".......######...........",
        "........####............",
        ".........####...........",
        "..........####..........",
        "...........####.........",
        "............####........",
        ".............####.......",
        "..............###.......",
        "...............##.......",
        "................#.......",
        "........................"
    }
}

--------------------------------------------------------------------------------
-- OVERWORLD MAP (32 x 24 Tiles)
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
-- POKEDEX & MOVES DATABASE
--------------------------------------------------------------------------------

local POKEDEX = {
    PIKACHU    = { type = "ELEC",  hp = 22, atk = 14, def = 8,  spd = 15, moves = { "THUNDERSHOCK", "QUICK ATTACK", "TAIL WHIP" } },
    CHARMANDER = { type = "FIRE",  hp = 24, atk = 15, def = 9,  spd = 12, moves = { "EMBER", "SCRATCH", "GROWL" } },
    SQUIRTLE   = { type = "WATER", hp = 26, atk = 12, def = 14, spd = 10, moves = { "WATER GUN", "TACKLE", "TAIL WHIP" } },
    BULBASAUR  = { type = "GRASS", hp = 25, atk = 13, def = 12, spd = 11, moves = { "VINE WHIP", "TACKLE", "GROWL" } },
    PIDGEY     = { type = "FLY",   hp = 18, atk = 11, def = 7,  spd = 13, moves = { "GUST", "QUICK ATTACK" } },
    RATTATA    = { type = "NORM",  hp = 17, atk = 12, def = 7,  spd = 14, moves = { "TACKLE", "QUICK ATTACK", "TAIL WHIP" } },
    CATERPIE   = { type = "BUG",   hp = 15, atk = 9,  def = 8,  spd = 8,  moves = { "TACKLE", "STRING SHOT" } }
}

local MOVES = {
    THUNDERSHOCK = { power = 14, type = "ELEC",  pp = 25 },
    QUICK_ATTACK = { power = 10, type = "NORM",  pp = 30, prio = 1 },
    EMBER        = { power = 14, type = "FIRE",  pp = 25 },
    WATER_GUN    = { power = 14, type = "WATER", pp = 25 },
    VINE_WHIP    = { power = 14, type = "GRASS", pp = 20 },
    GUST         = { power = 12, type = "FLY",   pp = 30 },
    TACKLE       = { power = 10, type = "NORM",  pp = 35 },
    SCRATCH      = { power = 10, type = "NORM",  pp = 35 },
    GROWL        = { power = 0,  type = "NORM",  pp = 40 },
    TAIL_WHIP    = { power = 0,  type = "NORM",  pp = 40 },
    STRING_SHOT  = { power = 0,  type = "BUG",   pp = 40 }
}

--------------------------------------------------------------------------------
-- GAME VARIABLES & STATE
--------------------------------------------------------------------------------

local playerX = 14
local playerY = 19
local playerFacing = "DOWN"
local party = {}
local activePkmnIdx = 1
local bag = { balls = 5, potions = 3 }

local starterChoices = { "PIKACHU", "CHARMANDER", "SQUIRTLE", "BULBASAUR" }
local starterSel = 1

local menuItems = { "POKEMON", "BAG", "SAVE", "EXIT" }
local menuSel = 1

local enemyPkmn = nil
local battleMenuSel = 0  -- 0: FIGHT, 1: BAG, 2: PKMN, 3: RUN
local battleMoveSel = 1
local battleBagSel = 1

local catchStep = 0
local catchTimer = 0
local catchWiggles = 0
local catchSuccess = false

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function createPokemon(name, level)
    local base = POKEDEX[name]
    local hpMax = base.hp + (level * 3)
    local movesCopy = {}
    for i = 1, #base.moves do
        movesCopy[i] = base.moves[i]
    end
    return {
        name = name,
        level = level,
        hp = hpMax,
        maxHp = hpMax,
        atk = base.atk + (level * 2),
        def = base.def + (level * 2),
        spd = base.spd + (level * 2),
        type = base.type,
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
-- SAVE & LOAD SYSTEM
--------------------------------------------------------------------------------

local SAVE_PATH = "/SCRIPTS/TOOLS/POKEMON/save.dat"

local function saveGame()
    local f = io.open(SAVE_PATH, "w")
    if f then
        f:write(string.format("%d,%d,%d,%d\n", playerX, playerY, bag.balls, bag.potions))
        f:write(string.format("%d\n", #party))
        for i = 1, #party do
            local p = party[i]
            f:write(string.format("%s,%d,%d,%d,%d,%d\n", p.name, p.level, p.hp, p.maxHp, p.atk, p.exp))
        end
        io.close(f)
        playSfx("catch.wav")
        triggerDialogue("GAME SAVED SAFELY!", STATE_OVERWORLD, 150)
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
                bag.balls = parts[3]
                bag.potions = parts[4]
            end
            local lineCount = io.readline(f)
            local pCount = tonumber(lineCount) or 0
            party = {}
            for i = 1, pCount do
                local pLine = io.readline(f)
                if pLine then
                    local pParts = {}
                    for v in string.gmatch(pLine, "[^,]+") do
                        pParts[#pParts + 1] = v
                    end
                    if #pParts >= 6 then
                        local pName = pParts[1]
                        local pLvl = tonumber(pParts[2]) or 5
                        local pk = createPokemon(pName, pLvl)
                        pk.hp = tonumber(pParts[3]) or pk.maxHp
                        pk.maxHp = tonumber(pParts[4]) or pk.maxHp
                        pk.atk = tonumber(pParts[5]) or pk.atk
                        pk.exp = tonumber(pParts[6]) or 0
                        party[#party + 1] = pk
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
    local ail = getValue("ail") or getValue("AIL") or getValue("rud") or 0
    local ele = getValue("ele") or getValue("ELE") or 0
    if math.abs(ail) > 400 or math.abs(ele) > 400 then
        if math.abs(ail) > math.abs(ele) then
            return (ail > 0) and 1 or -1, 0
        else
            return 0, (ele > 0) and -1 or 1
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
    local eName = "PIDGEY"
    local eLvl = math.random(2, 4)

    if r <= 40 then
        eName = "PIDGEY"
        eLvl = math.random(2, 4)
    elseif r <= 75 then
        eName = "RATTATA"
        eLvl = math.random(2, 4)
    elseif r <= 92 then
        eName = "CATERPIE"
        eLvl = math.random(2, 3)
    else
        eName = "PIKACHU"
        eLvl = math.random(3, 5)
    end

    enemyPkmn = createPokemon(eName, eLvl)
    triggerDialogue("Wild " .. eName .. " appeared!", STATE_BATTLE_MENU, 150)
end

local function executeTurn(pMoveName)
    local player = party[activePkmnIdx]
    local enemy = enemyPkmn
    local mKey = string.gsub(pMoveName, " ", "_")
    local pMove = MOVES[mKey] or { power = 10, type = "NORM" }

    playSfx("hit.wav")
    screenShake = 3

    -- Damage math
    local dmg = math.max(1, math.floor(pMove.power * (player.atk / enemy.def) * (0.85 + math.random() * 0.3)))
    if (pMove.type == "ELEC" and enemy.type == "FLY") or
       (pMove.type == "WATER" and enemy.type == "FIRE") or
       (pMove.type == "FIRE" and enemy.type == "GRASS") or
       (pMove.type == "GRASS" and enemy.type == "WATER") then
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
            triggerDialogue(player.name .. " grew to Lv " .. player.level .. "!", STATE_OVERWORLD, 160)
        else
            triggerDialogue("Enemy " .. enemy.name .. " fainted!", STATE_OVERWORLD, 150)
        end
        return
    end

    -- Enemy attacks
    local eMoveName = enemy.moves[math.random(1, #enemy.moves)]
    local eKey = string.gsub(eMoveName, " ", "_")
    local eMove = MOVES[eKey] or { power = 10, type = "NORM" }
    playSfx("hit.wav")
    local eDmg = math.max(1, math.floor(eMove.power * (enemy.atk / player.def) * (0.85 + math.random() * 0.3)))
    player.hp = math.max(0, player.hp - eDmg)

    if player.hp == 0 then
        playSfx("faint.wav")
        for i = 1, #party do
            party[i].hp = party[i].maxHp
        end
        playerX = 14
        playerY = 19
        triggerDialogue(player.name .. " fainted! Respawned at home!", STATE_OVERWORLD, 170)
        return
    end

    triggerDialogue(player.name .. " hit " .. dmg .. "! Enemy used " .. eMoveName .. "!", STATE_BATTLE_MENU, 150)
end

local function startCatchAttempt()
    gameState = STATE_CATCH_ANIM
    catchStep = 1
    catchTimer = getTime() + 60
    catchWiggles = 0
    local hpRatio = enemyPkmn.hp / enemyPkmn.maxHp
    local chance = 0.85 - (hpRatio * 0.5)
    catchSuccess = (math.random() < chance)
end

--------------------------------------------------------------------------------
-- RENDERING ROUTINES (128x64 Optimized)
--------------------------------------------------------------------------------

local function drawTitle()
    lcd.clear()
    lcd.drawText(22, 10, "POKEMON", MIDSIZE)
    lcd.drawText(38, 26, "CLASSIC", SMLSIZE)
    
    local bobY = 38 + math.floor(math.sin(getTime() / 15) * 2)
    drawSprite8x8(60, bobY, POKEBALL_SPRITE)

    if (math.floor(getTime() / 40) % 2 == 0) then
        lcd.drawText(10, 52, "PRESS [ENT] TO START", SMLSIZE)
    end
end

local function drawStarterSelect()
    lcd.clear()
    lcd.drawFilledRectangle(0, 0, LCD_W, 11)
    lcd.drawText(6, 2, "CHOOSE YOUR STARTER!", INVERS + SMLSIZE)

    local choice = starterChoices[starterSel]
    local spr = SPRITES_24[choice]
    if spr then
        drawSprite24x24(52, 15, spr)
    end

    lcd.drawText(30, 42, "< " .. choice .. " >", SMLSIZE)
    local base = POKEDEX[choice]
    lcd.drawText(8, 53, string.format("T:%s  HP:%d  ATK:%d", base.type, base.hp, base.atk), SMLSIZE)
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

    -- 1. Enemy Box & Sprite (Top Right)
    local enemy = enemyPkmn
    lcd.drawText(4 + offX, 2, enemy.name .. " Lv" .. enemy.level, SMLSIZE)
    lcd.drawRectangle(4, 11, 46, 5)
    local ePct = math.max(0, math.min(1, enemy.hp / enemy.maxHp))
    local eFill = math.floor(ePct * 44)
    if eFill > 0 then
        lcd.drawFilledRectangle(5, 12, eFill, 3)
    end

    if gameState == STATE_CATCH_ANIM and catchStep >= 1 then
        local wigOff = (catchWiggles % 2 == 1) and -2 or 2
        drawSprite8x8(86 + wigOff, 12, POKEBALL_SPRITE)
    else
        local eSpr = SPRITES_24[enemy.name]
        if eSpr then
            drawSprite24x24(80 + offX, 2, eSpr)
        end
    end

    -- 2. Player Box & Sprite (Bottom Left)
    local player = party[activePkmnIdx]
    local pSpr = SPRITES_24[player.name]
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

    -- 3. Bottom Action Box (y = 44..63)
    lcd.drawFilledRectangle(0, 44, LCD_W, 20, ERASE)
    lcd.drawRectangle(0, 44, LCD_W, 20)

    if gameState == STATE_BATTLE_DIALOGUE then
        lcd.drawText(4, 50, battleMsg, SMLSIZE)

    elseif gameState == STATE_CATCH_ANIM then
        local wTxt = (catchWiggles > 0) and ("Wiggle " .. catchWiggles .. "...") or "Throwing Poke Ball!"
        lcd.drawText(4, 50, wTxt, SMLSIZE)

    elseif gameState == STATE_BATTLE_MENU then
        local opts = { "FIGHT", "BAG", "PKMN", "RUN" }
        local coords = { { 8, 48 }, { 68, 48 }, { 8, 56 }, { 68, 56 } }
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
        lcd.drawText(92, 50, "[RTN]", SMLSIZE)

    elseif gameState == STATE_BATTLE_BAG then
        local bPfx = (battleBagSel == 1) and ">" or " "
        local pPfx = (battleBagSel == 2) and ">" or " "
        lcd.drawText(4, 46, string.format("%sBALLS x%d", bPfx, bag.balls), SMLSIZE)
        lcd.drawText(4, 54, string.format("%sPOTION x%d", pPfx, bag.potions), SMLSIZE)
        lcd.drawText(92, 50, "[RTN]", SMLSIZE)
    end
end

--------------------------------------------------------------------------------
-- MAIN LIFECYCLE: INIT & RUN
--------------------------------------------------------------------------------

local function init()
    math.randomseed(getTime())
    playSfx("intro.wav")
    startupIgnoreUntil = getTime() + 40
    lastStepTime = getTime()

    -- Try loading save game
    local loaded = loadGame()
    if loaded and #party > 0 then
        gameState = STATE_OVERWORLD
    else
        gameState = STATE_TITLE
    end
end

local function run(event)
    local now = getTime()

    -- Auto-advance dialogue
    if gameState == STATE_BATTLE_DIALOGUE then
        if now > msgTimer then
            if afterMsgState then
                gameState = afterMsgState
                afterMsgState = nil
            end
        end
    end

    -- Catch animation state machine
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
                    party[#party + 1] = enemyPkmn
                    triggerDialogue("All right! " .. enemyPkmn.name .. " was caught!", STATE_OVERWORLD, 160)
                else
                    playSfx("faint.wav")
                    triggerDialogue("Oh no! The POKEMON broke free!", STATE_BATTLE_MENU, 150)
                end
            end
        end
    end

    -- Stick movement in Overworld
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
                    -- Non-solid check
                    if tile ~= 2 and tile ~= 3 and tile ~= 4 and tile ~= 5 and tile ~= 6 and tile ~= 9 then
                        playerX = nx
                        playerY = ny
                        lastStepTime = now + 20 -- 0.2s per step

                        -- Tall grass check (Tile 1)
                        if tile == 1 then
                            if math.random(1, 100) <= 18 then
                                triggerWildEncounter()
                            end
                        end
                    end
                end
            end
        end
    end

    -- Action [SE] Switch
    if checkSeSwitch() and gameState == STATE_OVERWORLD then
        for i = 1, #party do
            party[i].hp = party[i].maxHp
        end
        playSfx("levelup.wav")
    end

    -- Navigation via Roller / Buttons
    if now > startupIgnoreUntil then
        if isNext(event) then
            if gameState == STATE_STARTER_SELECT then
                starterSel = (starterSel % #starterChoices) + 1
                playSfx("select.wav")
            elseif gameState == STATE_START_MENU then
                menuSel = (menuSel % #menuItems) + 1
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MENU then
                battleMenuSel = (battleMenuSel + 1) % 4
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MOVES then
                local player = party[activePkmnIdx]
                battleMoveSel = (battleMoveSel % #player.moves) + 1
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_BAG then
                battleBagSel = (battleBagSel == 1) and 2 or 1
                playSfx("select.wav")
            end

        elseif isPrev(event) then
            if gameState == STATE_STARTER_SELECT then
                starterSel = starterSel - 1
                if starterSel < 1 then starterSel = #starterChoices end
                playSfx("select.wav")
            elseif gameState == STATE_START_MENU then
                menuSel = menuSel - 1
                if menuSel < 1 then menuSel = #menuItems end
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MENU then
                battleMenuSel = (battleMenuSel + 3) % 4
                playSfx("select.wav")
            elseif gameState == STATE_BATTLE_MOVES then
                local player = party[activePkmnIdx]
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
                if #party == 0 then
                    gameState = STATE_STARTER_SELECT
                else
                    gameState = STATE_OVERWORLD
                end

            elseif gameState == STATE_STARTER_SELECT then
                local choice = starterChoices[starterSel]
                party[1] = createPokemon(choice, 5)
                activePkmnIdx = 1
                playSfx("catch.wav")
                gameState = STATE_OVERWORLD

            elseif gameState == STATE_START_MENU then
                local item = menuItems[menuSel]
                if item == "EXIT" then
                    gameState = STATE_OVERWORLD
                elseif item == "SAVE" then
                    saveGame()
                elseif item == "POKEMON" then
                    gameState = STATE_OVERWORLD
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
                elseif battleMenuSel == 2 then  -- PKMN
                    triggerDialogue("No other PKMN!", STATE_BATTLE_MENU, 120)
                elseif battleMenuSel == 3 then  -- RUN
                    playSfx("run.wav")
                    triggerDialogue("Got away safely!", STATE_OVERWORLD, 140)
                end

            elseif gameState == STATE_BATTLE_MOVES then
                local player = party[activePkmnIdx]
                local mName = player.moves[battleMoveSel]
                executeTurn(mName)

            elseif gameState == STATE_BATTLE_BAG then
                if battleBagSel == 1 then
                    if bag.balls > 0 then
                        bag.balls = bag.balls - 1
                        startCatchAttempt()
                    else
                        triggerDialogue("No POKE BALLS!", STATE_BATTLE_BAG, 120)
                    end
                else
                    if bag.potions > 0 then
                        bag.potions = bag.potions - 1
                        local player = party[activePkmnIdx]
                        player.hp = math.min(player.maxHp, player.hp + 20)
                        playSfx("levelup.wav")
                        triggerDialogue("Healed 20 HP to " .. player.name .. "!", STATE_BATTLE_MENU, 140)
                    else
                        triggerDialogue("No POTIONS!", STATE_BATTLE_BAG, 120)
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

    -- Render according to state
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
