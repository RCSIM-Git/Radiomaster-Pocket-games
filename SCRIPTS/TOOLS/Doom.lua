--[[
    DOOM (Pocket Edition) for EdgeTX
    Classic 3D Raycasting FPS Engine for 128x64 Monochrome LCD
    Compatible with: RadioMaster Pocket, MT12, Boxer, TX12
    Author: EdgeTX Pair-Programmer & Mateusz
--]]

--------------------------------------------------------------------------------
-- GAME CONSTANTS & ENUMS
--------------------------------------------------------------------------------
local LCD_W = 128
local LCD_H = 64
local VIEW_H = 51 -- Viewport height (y: 0..51, HUD at y: 52..63)
local NUM_RAYS = 64 -- Slices (2px wide per slice for smooth 30 FPS)
local FOV = 1.047197 -- 60 degrees in radians (pi / 3)

local STATE_TITLE = 0
local STATE_PLAY = 1
local STATE_GAMEOVER = 2
local STATE_VICTORY = 3

local gameState = STATE_TITLE
local kills = 0
local totalMonsters = 5

--------------------------------------------------------------------------------
-- SOUND UTILITY
--------------------------------------------------------------------------------
local function playSfx(filename)
    if type(playFile) == "function" then
        pcall(playFile, "/SOUNDS/DOOM/" .. filename)
    end
end

local function safeAtan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    elseif math.atan then
        return math.atan(y, x)
    end
    if x == 0 then
        return (y > 0) and (math.pi / 2) or (-math.pi / 2)
    end
    local a = math.atan(y / x)
    if x < 0 then
        a = a + ((y >= 0) and math.pi or -math.pi)
    end
    return a
end

--------------------------------------------------------------------------------
-- MAP DEFINITION (16x16 UAC Maze)
-- 0: Empty, 1: Solid Wall, 2: Tech Pillar, 9: Exit Portal
--------------------------------------------------------------------------------
local MAP_W = 16
local MAP_H = 16
local map = {
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,
    1,0,1,0,1,0,1,1,1,0,1,1,1,1,0,1,
    1,0,1,0,0,0,1,0,0,0,1,0,0,1,0,1,
    1,0,1,1,1,0,1,0,2,0,1,0,0,0,0,1,
    1,0,0,0,1,0,0,0,0,0,1,0,1,1,0,1,
    1,1,1,0,1,1,1,0,1,1,1,0,1,0,0,1,
    1,0,0,0,0,0,1,0,1,0,0,0,1,0,1,1,
    1,0,2,0,2,0,1,0,1,0,2,0,0,0,0,1,
    1,0,0,0,0,0,0,0,1,0,0,0,1,1,0,1,
    1,1,1,0,1,1,1,0,1,1,1,0,1,0,0,1,
    1,0,0,0,1,0,0,0,0,0,1,0,1,0,1,1,
    1,0,1,1,1,0,1,1,1,0,1,0,0,0,0,1,
    1,0,0,0,0,0,1,0,0,0,1,1,1,0,9,1,
    1,0,1,0,1,0,0,0,1,0,0,0,0,0,9,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
}

local function getMapTile(mx, my)
    if mx < 0 or mx >= MAP_W or my < 0 or my >= MAP_H then
        return 1
    end
    return map[my * MAP_W + mx + 1] or 1
end

--------------------------------------------------------------------------------
-- PLAYER & WEAPON STATE
--------------------------------------------------------------------------------
local player = {
    x = 1.5,
    y = 1.5,
    angle = 0.0,
    health = 100,
    armor = 50,
    ammo = 24,
    hurtTimer = 0,
    walkTimer = 0
}

-- Weapon states: 0 = idle, 1 = fire blast, 2 = recoil down, 3 = reload up
local gunState = 0
local gunTimer = 0

--------------------------------------------------------------------------------
-- MONSTERS & ITEMS
--------------------------------------------------------------------------------
local entities = {}

local function resetEntities()
    entities = {}
    -- Type: 1 = Imp, 2 = Health Pack, 3 = Ammo Box
    -- Monsters
    entities[#entities + 1] = {x = 3.5, y = 3.5, type = 1, hp = 30, dead = false, hitTimer = 0}
    entities[#entities + 1] = {x = 7.5, y = 1.5, type = 1, hp = 30, dead = false, hitTimer = 0}
    entities[#entities + 1] = {x = 9.5, y = 5.5, type = 1, hp = 30, dead = false, hitTimer = 0}
    entities[#entities + 1] = {x = 5.5, y = 8.5, type = 1, hp = 30, dead = false, hitTimer = 0}
    entities[#entities + 1] = {x = 13.5, y = 11.5, type = 1, hp = 45, dead = false, hitTimer = 0}
    
    -- Pickups
    entities[#entities + 1] = {x = 1.5, y = 8.5, type = 2, dead = false} -- Medikit
    entities[#entities + 1] = {x = 13.5, y = 3.5, type = 3, dead = false} -- Ammo
    entities[#entities + 1] = {x = 7.5, y = 13.5, type = 2, dead = false} -- Medikit
end

local zBuffer = {}
for i = 1, NUM_RAYS do
    zBuffer[i] = 99.0
end

local showMinimap = true

--------------------------------------------------------------------------------
-- INPUT DETECTION
--------------------------------------------------------------------------------
local function getStickValue(name)
    local v = getValue(name)
    if v == nil or type(v) ~= "number" then return 0 end
    return v
end

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

-- Obsługa strzału pod przyciskiem/switchem SE (RadioMaster Pocket) oraz [ENT]
local lastSeState = 0
local lastSdState = 0

local function checkFireInput(event)
    -- 1. Przycisk / przełącznik SE (Pocket top shoulder button)
    local seVal = getValue("se")
    if seVal == nil or type(seVal) ~= "number" then
        seVal = getValue("SE") or 0
    end

    local seTriggered = false
    -- Wykrywanie zbocza (kliknięcie SE)
    if seVal > 200 and lastSeState <= 200 then
        seTriggered = true
    elseif seVal < -200 and lastSeState >= -200 and lastSeState ~= 0 then
        seTriggered = true
    end

    -- Ciągły ogień przy przytrzymaniu SE: jeśli SE wciśnięty i broń jest gotowa
    if seVal > 200 and gunState == 0 then
        seTriggered = true
    end
    lastSeState = seVal

    -- 2. Przełącznik SD (Pocket / MT12)
    local sdVal = getValue("sd") or getValue("SD") or 0
    if sdVal > 500 and lastSdState <= 500 then
        seTriggered = true
    end
    lastSdState = sdVal

    -- 3. Alternatywnie kliknięcie rolki (ENTER)
    local enterTriggered = isEnter(event)

    return seTriggered or enterTriggered
end

--------------------------------------------------------------------------------
-- GAME ACTIONS: SHOOTING & WEAPONS
--------------------------------------------------------------------------------
local function shootGun()
    if gunState > 0 then return end -- Already firing
    if player.ammo <= 0 then
        -- Click sound / dry fire
        playSfx("pistol.wav")
        return
    end

    player.ammo = player.ammo - 1
    gunState = 1
    gunTimer = getTime()
    playSfx("shotgun.wav")

    -- Raycast hitscan check for enemies in crosshair center
    local centerDist = zBuffer[math.floor(NUM_RAYS / 2)] or 99.0
    local hitMonster = nil
    local hitDist = 99.0

    for i = 1, #entities do
        local ent = entities[i]
        if ent.type == 1 and not ent.dead then
            local dx = ent.x - player.x
            local dy = ent.y - player.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- Angle to monster
            local angleToEnt = safeAtan2(dy, dx) - player.angle
            while angleToEnt > math.pi do angleToEnt = angleToEnt - 2 * math.pi end
            while angleToEnt < -math.pi do angleToEnt = angleToEnt + 2 * math.pi end

            -- In front and inside crosshair cone (within +/- 12 degrees)
            if math.abs(angleToEnt) < 0.22 and dist < centerDist and dist < hitDist then
                hitDist = dist
                hitMonster = ent
            end
        end
    end

    if hitMonster then
        hitMonster.hp = hitMonster.hp - 35
        hitMonster.hitTimer = getTime()
        if hitMonster.hp <= 0 then
            hitMonster.dead = true
            kills = kills + 1
            playSfx("monster.wav")
        else
            playSfx("monster.wav")
        end
    end
end

--------------------------------------------------------------------------------
-- 3D RAYCASTING ENGINE (DDA Algorithm)
--------------------------------------------------------------------------------
local function renderRaycast()
    local halfFov = FOV / 2.0
    local pAngle = player.angle
    local px = player.x
    local py = player.y

    for ray = 0, NUM_RAYS - 1 do
        local rayAngle = pAngle - halfFov + (ray / NUM_RAYS) * FOV
        local rDirX = math.cos(rayAngle)
        local rDirY = math.sin(rayAngle)

        if math.abs(rDirX) < 0.0001 then rDirX = 0.0001 end
        if math.abs(rDirY) < 0.0001 then rDirY = 0.0001 end

        local mapX = math.floor(px)
        local mapY = math.floor(py)

        local deltaX = math.abs(1.0 / rDirX)
        local deltaY = math.abs(1.0 / rDirY)

        local stepX, sideDistX
        if rDirX < 0 then
            stepX = -1
            sideDistX = (px - mapX) * deltaX
        else
            stepX = 1
            sideDistX = (mapX + 1.0 - px) * deltaX
        end

        local stepY, sideDistY
        if rDirY < 0 then
            stepY = -1
            sideDistY = (py - mapY) * deltaY
        else
            stepY = 1
            sideDistY = (mapY + 1.0 - py) * deltaY
        end

        local hit = 0
        local side = 0
        local steps = 18

        while hit == 0 and steps > 0 do
            steps = steps - 1
            if sideDistX < sideDistY then
                sideDistX = sideDistX + deltaX
                mapX = mapX + stepX
                side = 0
            else
                sideDistY = sideDistY + deltaY
                mapY = mapY + stepY
                side = 1
            end

            local tile = getMapTile(mapX, mapY)
            if tile > 0 then
                hit = tile
            end
        end

        -- Calculate perpendicular wall distance
        local perpDist
        if side == 0 then
            perpDist = (mapX - px + (1 - stepX) / 2.0) / rDirX
        else
            perpDist = (mapY - py + (1 - stepY) / 2.0) / rDirY
        end

        -- Fisheye correction
        perpDist = perpDist * math.cos(rayAngle - pAngle)
        if perpDist < 0.25 then perpDist = 0.25 end
        zBuffer[ray + 1] = perpDist

        -- Projected wall height
        local wallH = math.floor(28.0 / perpDist)
        local drawStart = math.floor(VIEW_H / 2 - wallH / 2)
        local drawEnd = math.floor(VIEW_H / 2 + wallH / 2)

        if drawStart < 0 then drawStart = 0 end
        if drawEnd >= VIEW_H then drawEnd = VIEW_H - 1 end

        local scrX = ray * 2

        -- Render Wall Column (Dithering & Shading)
        if hit == 9 then
            -- Exit Portal (Glowing checker / dotted lines)
            lcd.drawLine(scrX, drawStart, scrX, drawEnd, DOTTED, 0)
            lcd.drawLine(scrX + 1, drawStart + 1, scrX + 1, drawEnd - 1, SOLID, 0)
        elseif hit == 2 then
            -- Tech Pillar
            lcd.drawLine(scrX, drawStart, scrX, drawEnd, SOLID, 0)
            lcd.drawLine(scrX + 1, drawStart, scrX + 1, drawEnd, DOTTED, 0)
        else
            -- Standard Wall (X-side solid bright, Y-side shaded pattern)
            if side == 0 then
                lcd.drawFilledRectangle(scrX, drawStart, 2, drawEnd - drawStart + 1)
            else
                -- Vertical shaded hatch
                lcd.drawLine(scrX, drawStart, scrX, drawEnd, SOLID, 0)
                if perpDist < 3.5 then
                    lcd.drawLine(scrX + 1, drawStart, scrX + 1, drawEnd, DOTTED, 0)
                end
            end
        end

        -- Top and Bottom Horizon lines for 3D depth
        if drawStart > 0 and drawStart < VIEW_H then
            lcd.drawPoint(scrX, drawStart)
        end
        if drawEnd > 0 and drawEnd < VIEW_H then
            lcd.drawPoint(scrX, drawEnd)
        end
    end
end

--------------------------------------------------------------------------------
-- SPRITE RENDERING (Monsters & Pickups with Z-Buffer)
--------------------------------------------------------------------------------
local function renderEntities()
    local halfFov = FOV / 2.0

    for i = 1, #entities do
        local ent = entities[i]
        local dx = ent.x - player.x
        local dy = ent.y - player.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 0.4 and dist < 12.0 then
            -- Angle relative to player view
            local angleToEnt = safeAtan2(dy, dx) - player.angle
            while angleToEnt > math.pi do angleToEnt = angleToEnt - 2 * math.pi end
            while angleToEnt < -math.pi do angleToEnt = angleToEnt + 2 * math.pi end

            if math.abs(angleToEnt) < halfFov + 0.25 then
                local scrX = math.floor((angleToEnt / halfFov + 1.0) * (LCD_W / 2))
                local sprH = math.floor(26.0 / dist)
                local sprW = math.floor(sprH * 0.75)
                local sprY = math.floor(VIEW_H / 2 + 3 - sprH / 2)

                local rayIdx = math.floor(scrX / 2) + 1
                if rayIdx >= 1 and rayIdx <= NUM_RAYS and dist < zBuffer[rayIdx] then
                    if ent.type == 1 then
                        -- MONSTER (IMP)
                        if ent.dead then
                            -- Dead pool / carcass on floor
                            local baseY = math.min(VIEW_H - 3, sprY + sprH)
                            lcd.drawLine(scrX - 4, baseY, scrX + 4, baseY, SOLID, 0)
                            lcd.drawLine(scrX - 2, baseY - 1, scrX + 2, baseY - 1, SOLID, 0)
                        else
                            -- Living Imp
                            local isHurt = (getTime() - ent.hitTimer) < 15
                            if isHurt then
                                -- Pain flash: inverted block
                                lcd.drawFilledRectangle(scrX - sprW/2, sprY, sprW, sprH)
                            else
                                -- Imp body
                                lcd.drawFilledRectangle(scrX - 2, sprY + 3, 5, math.max(4, sprH - 6))
                                -- Horns / Spiky shoulders
                                lcd.drawLine(scrX - 3, sprY + 2, scrX - 3, sprY + 5, SOLID, 0)
                                lcd.drawLine(scrX + 3, sprY + 2, scrX + 3, sprY + 5, SOLID, 0)
                                -- Head
                                lcd.drawFilledRectangle(scrX - 2, sprY, 5, 3)
                            end
                        end
                    elseif ent.type == 2 and not ent.dead then
                        -- HEALTH PACK: Medical Cross [+]
                        local cy = math.floor(VIEW_H / 2 + 8)
                        lcd.drawFilledRectangle(scrX - 3, cy - 1, 7, 3)
                        lcd.drawFilledRectangle(scrX - 1, cy - 3, 3, 7)
                    elseif ent.type == 3 and not ent.dead then
                        -- AMMO BOX: [::]
                        local cy = math.floor(VIEW_H / 2 + 8)
                        lcd.drawRectangle(scrX - 4, cy - 3, 8, 6)
                        lcd.drawPoint(scrX - 2, cy)
                        lcd.drawPoint(scrX + 1, cy)
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- 2D WEAPON & SHOTGUN RENDERING
--------------------------------------------------------------------------------
local function renderWeapon()
    local now = getTime()
    local bobY = 0
    if player.walkTimer > 0 then
        bobY = math.floor(math.sin(player.walkTimer * 0.25) * 2)
    end

    local gunBaseX = 64
    local gunBaseY = 46 + bobY

    if gunState == 1 then
        -- MUZZLE FLASH BURST! (Frame 1)
        if now - gunTimer < 8 then
            -- Gun displaced by recoil
            gunBaseY = gunBaseY + 3
            -- Blast fire lines radiating from twin barrels
            lcd.drawLine(gunBaseX - 3, gunBaseY - 14, gunBaseX - 10, gunBaseY - 24, SOLID, 0)
            lcd.drawLine(gunBaseX, gunBaseY - 14, gunBaseX, gunBaseY - 26, SOLID, 0)
            lcd.drawLine(gunBaseX + 3, gunBaseY - 14, gunBaseX + 10, gunBaseY - 24, SOLID, 0)
            -- Muzzle flash core
            lcd.drawFilledRectangle(gunBaseX - 5, gunBaseY - 16, 11, 4)
        else
            gunState = 2
            gunTimer = now
        end
    elseif gunState == 2 then
        -- RECOIL KICK DOWN (Frame 2)
        if now - gunTimer < 12 then
            gunBaseY = gunBaseY + 6
        else
            gunState = 3
            gunTimer = now
        end
    elseif gunState == 3 then
        -- PUMP RELOAD UP (Frame 3)
        if now - gunTimer < 10 then
            gunBaseY = gunBaseY + 2
        else
            gunState = 0
        end
    end

    -- Draw Double-Barrel Shotgun
    -- Twin barrels
    lcd.drawFilledRectangle(gunBaseX - 4, gunBaseY - 12, 3, 14)
    lcd.drawFilledRectangle(gunBaseX + 1, gunBaseY - 12, 3, 14)
    -- Rib between barrels
    lcd.drawLine(gunBaseX, gunBaseY - 10, gunBaseX, gunBaseY + 1, SOLID, 0)
    -- Foregrip / Stock
    lcd.drawFilledRectangle(gunBaseX - 6, gunBaseY, 13, 6)
    -- Shading on grip
    lcd.drawPoint(gunBaseX - 4, gunBaseY + 2)
    lcd.drawPoint(gunBaseX + 4, gunBaseY + 2)

    -- Crosshair dot in screen center
    lcd.drawPoint(64, 25)
    lcd.drawPoint(64, 26)
end

--------------------------------------------------------------------------------
-- MINIMAP RADAR OVERLAY (Top-Right)
--------------------------------------------------------------------------------
local function renderMinimap()
    if not showMinimap then return end
    local mmX = 104
    local mmY = 1
    local mmSize = 22

    lcd.drawRectangle(mmX, mmY, mmSize, mmSize)

    -- Draw player position and heading
    local px = mmX + math.floor((player.x / MAP_W) * mmSize)
    local py = mmY + math.floor((player.y / MAP_H) * mmSize)

    lcd.drawFilledRectangle(px - 1, py - 1, 2, 2)
    local dirX = px + math.floor(math.cos(player.angle) * 4)
    local dirY = py + math.floor(math.sin(player.angle) * 4)
    lcd.drawLine(px, py, dirX, dirY, SOLID, 0)
end

--------------------------------------------------------------------------------
-- DOOM STATUS BAR (Classic HUD at y: 52..63)
--------------------------------------------------------------------------------
local function renderStatusBar()
    -- Border frame
    lcd.drawRectangle(0, 52, 128, 12)

    -- 1. AMMO (x: 2..32)
    lcd.drawText(2, 54, string.format("A:%02d", player.ammo), SMLSIZE)

    -- 2. HEALTH (x: 28..58)
    lcd.drawText(27, 54, string.format("H:%3d", player.health), SMLSIZE)

    -- 3. DOOM MARINE FACE (x: 60..68)
    local faceX = 60
    local faceY = 53
    lcd.drawRectangle(faceX, faceY, 9, 9)
    -- Hair
    lcd.drawLine(faceX + 1, faceY + 1, faceX + 7, faceY + 1, SOLID, 0)
    -- Eyes
    if gunState == 1 then
        -- Grinning when shooting!
        lcd.drawPoint(faceX + 2, faceY + 3)
        lcd.drawPoint(faceX + 6, faceY + 3)
        lcd.drawLine(faceX + 2, faceY + 6, faceX + 6, faceY + 6, SOLID, 0)
    elseif player.health <= 0 then
        -- Dead: X eyes
        lcd.drawPoint(faceX + 2, faceY + 3)
        lcd.drawPoint(faceX + 3, faceY + 4)
        lcd.drawPoint(faceX + 5, faceY + 4)
        lcd.drawPoint(faceX + 6, faceY + 3)
    elseif player.health < 35 then
        -- Bruised / bloody eyes
        lcd.drawPoint(faceX + 2, faceY + 4)
        lcd.drawPoint(faceX + 6, faceY + 4)
    else
        -- Standard alert eyes
        lcd.drawPoint(faceX + 2, faceY + 3)
        lcd.drawPoint(faceX + 6, faceY + 3)
        lcd.drawPoint(faceX + 4, faceY + 6) -- Mouth
    end

    -- 4. ARMOR (x: 72..98)
    lcd.drawText(72, 54, string.format("R:%2d", player.armor), SMLSIZE)

    -- 5. KILLS / EXIT (x: 99..126)
    lcd.drawText(98, 54, string.format("K:%d/%d", kills, totalMonsters), SMLSIZE)
end

--------------------------------------------------------------------------------
-- GAME UPDATE LOGIC (AI, Physics, Collisions)
--------------------------------------------------------------------------------
local function updateGame()
    -- 1. Analog Stick Inputs
    local ele = getStickValue("ele")
    local thr = getStickValue("thr")
    local ail = getStickValue("ail")
    local rud = getStickValue("rud")

    -- Move forward / backward (combine elevator & throttle)
    local moveFwd = 0
    if math.abs(ele) > 200 then
        moveFwd = -ele / 1024.0 -- Inverted stick standard
    elseif math.abs(thr) > 200 then
        moveFwd = thr / 1024.0
    end

    -- Turn left / right (combine rudder & aileron)
    local turnDir = 0
    if math.abs(rud) > 200 then
        turnDir = rud / 1024.0
    elseif math.abs(ail) > 200 then
        turnDir = ail / 1024.0
    end

    -- Update Player Angle
    player.angle = player.angle + turnDir * 0.08
    while player.angle > 2 * math.pi do player.angle = player.angle - 2 * math.pi end
    while player.angle < 0 do player.angle = player.angle + 2 * math.pi end

    -- Move Player with Wall Collision
    if math.abs(moveFwd) > 0.05 then
        local moveSpeed = moveFwd * 0.09
        local newX = player.x + math.cos(player.angle) * moveSpeed
        local newY = player.y + math.sin(player.angle) * moveSpeed

        -- Wall slide collision
        if getMapTile(math.floor(newX), math.floor(player.y)) == 0 then
            player.x = newX
        end
        if getMapTile(math.floor(player.x), math.floor(newY)) == 0 then
            player.y = newY
        end

        player.walkTimer = player.walkTimer + 1

        -- Check if stepped into Exit Portal
        if getMapTile(math.floor(player.x), math.floor(player.y)) == 9 then
            gameState = STATE_VICTORY
            playSfx("item.wav")
        end
    else
        player.walkTimer = 0
    end

    -- 2. Monster AI & Pickup Check
    for i = 1, #entities do
        local ent = entities[i]
        local dx = ent.x - player.x
        local dy = ent.y - player.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if ent.type == 1 and not ent.dead then
            -- Monster AI: Alert & Chase
            if dist < 8.0 and dist > 1.1 then
                -- Step toward player
                local spd = 0.035
                local stepX = ent.x - (dx / dist) * spd
                local stepY = ent.y - (dy / dist) * spd
                if getMapTile(math.floor(stepX), math.floor(ent.y)) == 0 then
                    ent.x = stepX
                end
                if getMapTile(math.floor(ent.x), math.floor(stepY)) == 0 then
                    ent.y = stepY
                end
            elseif dist <= 1.1 then
                -- Melee Attack Player!
                local now = getTime()
                if now - player.hurtTimer > 80 then
                    player.hurtTimer = now
                    local dmg = 12
                    if player.armor > 0 then
                        player.armor = math.max(0, player.armor - 6)
                        dmg = 6
                    end
                    player.health = player.health - dmg
                    playSfx("monster.wav")
                    if player.health <= 0 then
                        player.health = 0
                        gameState = STATE_GAMEOVER
                    end
                end
            end
        elseif ent.type == 2 and not ent.dead and dist < 0.8 then
            -- Pickup Health Pack
            if player.health < 100 then
                player.health = math.min(100, player.health + 25)
                ent.dead = true
                playSfx("item.wav")
            end
        elseif ent.type == 3 and not ent.dead and dist < 0.8 then
            -- Pickup Ammo
            player.ammo = player.ammo + 12
            ent.dead = true
            playSfx("item.wav")
        end
    end
end

--------------------------------------------------------------------------------
-- GAME LIFECYCLE & MAIN LOOP
--------------------------------------------------------------------------------
local function drawDoomLogo(ox, oy)
    -- D (Spine, serifs, bars, angled right edge)
    lcd.drawFilledRectangle(ox + 8, oy, 6, 19)
    lcd.drawFilledRectangle(ox + 5, oy, 4, 4)
    lcd.drawFilledRectangle(ox + 5, oy + 15, 4, 4)
    lcd.drawFilledRectangle(ox + 14, oy, 10, 4)
    lcd.drawFilledRectangle(ox + 14, oy + 15, 10, 4)
    lcd.drawFilledRectangle(ox + 22, oy + 3, 5, 13)
    lcd.drawLine(ox + 19, oy, ox + 26, oy + 4, SOLID, 0)
    lcd.drawLine(ox + 20, oy, ox + 26, oy + 3, SOLID, 0)
    lcd.drawLine(ox + 19, oy + 18, ox + 26, oy + 14, SOLID, 0)
    lcd.drawLine(ox + 20, oy + 18, ox + 26, oy + 15, SOLID, 0)
    lcd.drawFilledRectangle(ox + 26, oy, 2, 1, 0)
    lcd.drawFilledRectangle(ox + 26, oy + 18, 2, 1, 0)

    -- O #1 (Classic Octagonal Ring)
    lcd.drawFilledRectangle(ox + 33, oy + 2, 16, 15)
    lcd.drawFilledRectangle(ox + 31, oy + 5, 20, 9)
    lcd.drawFilledRectangle(ox + 37, oy + 6, 8, 7, 0)

    -- O #2 (Classic Octagonal Ring)
    lcd.drawFilledRectangle(ox + 57, oy + 2, 16, 15)
    lcd.drawFilledRectangle(ox + 55, oy + 5, 20, 9)
    lcd.drawFilledRectangle(ox + 61, oy + 6, 8, 7, 0)

    -- M (Outer pillars, bottom serifs, sharp center V)
    lcd.drawFilledRectangle(ox + 79, oy, 5, 19)
    lcd.drawFilledRectangle(ox + 77, oy + 15, 3, 4)
    lcd.drawFilledRectangle(ox + 98, oy, 5, 19)
    lcd.drawFilledRectangle(ox + 102, oy + 15, 3, 4)
    lcd.drawLine(ox + 83, oy, ox + 91, oy + 13, SOLID, 0)
    lcd.drawLine(ox + 84, oy, ox + 91, oy + 13, SOLID, 0)
    lcd.drawLine(ox + 85, oy, ox + 91, oy + 13, SOLID, 0)
    lcd.drawLine(ox + 98, oy, ox + 91, oy + 13, SOLID, 0)
    lcd.drawLine(ox + 97, oy, ox + 91, oy + 13, SOLID, 0)
    lcd.drawLine(ox + 96, oy, ox + 91, oy + 13, SOLID, 0)
    lcd.drawFilledRectangle(ox + 89, oy + 9, 5, 4)
end

local startupIgnoreUntil = 0

local function resetPlayerAndWorld()
    resetEntities()
    player.x = 1.5
    player.y = 1.5
    player.angle = 0.0
    player.health = 100
    player.armor = 50
    player.ammo = 24
    kills = 0
end

local function init()
    resetPlayerAndWorld()
    gameState = STATE_TITLE
    startupIgnoreUntil = getTime() + 40 -- 0.4s debounce na start
end

local function run(event)
    local now = getTime()
    lcd.clear()

    if gameState == STATE_TITLE then
        -- TITLE SCREEN: Autentyczne logo DOOM
        drawDoomLogo(10, 2)

        lcd.drawText(16, 26, "POCKET EDITION 3D", INVERS + SMLSIZE)
        lcd.drawText(4, 40, "MOVE: STICKS | FIRE: [SE] / [ENT]", SMLSIZE)

        local blink = (math.floor(now / 40) % 2 == 0)
        if blink then
            lcd.drawText(16, 53, ">> PRESS [SE] OR [ENT] <<", SMLSIZE)
        end

        if now > startupIgnoreUntil then
            if checkFireInput(event) then
                resetPlayerAndWorld()
                gameState = STATE_PLAY
                playSfx("shotgun.wav")
            elseif isExit(event) then
                return 2
            end
        end

    elseif gameState == STATE_PLAY then
        -- IN-GAME 3D WORLD
        updateGame()

        -- Shoot button
        if checkFireInput(event) then
            shootGun()
        end

        -- Roller wheel rotation support
        if isNext(event) then
            player.angle = player.angle + 0.15
        elseif isPrev(event) then
            player.angle = player.angle - 0.15
        elseif isExit(event) then
            gameState = STATE_TITLE
            startupIgnoreUntil = now + 30
        end

        -- Render Scene
        renderRaycast()
        renderEntities()
        renderWeapon()
        renderMinimap()
        renderStatusBar()

        -- Damage red flash / screen invert
        if (now - player.hurtTimer) < 8 then
            lcd.drawFilledRectangle(0, 0, LCD_W, VIEW_H)
        end

    elseif gameState == STATE_GAMEOVER then
        -- GAME OVER SCREEN
        lcd.drawFilledRectangle(0, 0, LCD_W, LCD_H)
        lcd.drawText(28, 14, "YOU DIED!", INVERS + DBLSIZE)
        lcd.drawText(20, 36, string.format("KILLED: %d DEMONS", kills), INVERS + SMLSIZE)
        lcd.drawText(16, 50, "[SE]/[ENT] TRY AGAIN", INVERS + SMLSIZE + BLINK)

        if checkFireInput(event) then
            resetPlayerAndWorld()
            gameState = STATE_PLAY
            playSfx("shotgun.wav")
        elseif isExit(event) then
            gameState = STATE_TITLE
            startupIgnoreUntil = now + 30
        end

    elseif gameState == STATE_VICTORY then
        -- VICTORY SCREEN
        lcd.drawRectangle(0, 0, LCD_W, LCD_H)
        lcd.drawText(22, 8, "LEVEL CLEARED!", DBLSIZE)
        lcd.drawText(18, 28, "UAC FACILITY SECURED", SMLSIZE)
        lcd.drawText(24, 40, string.format("KILLS: %d/%d  HP: %d%%", kills, totalMonsters, player.health), SMLSIZE)
        lcd.drawText(16, 52, "[SE]/[ENT] PLAY AGAIN", SMLSIZE + BLINK)

        if checkFireInput(event) then
            resetPlayerAndWorld()
            gameState = STATE_PLAY
            playSfx("shotgun.wav")
        elseif isExit(event) then
            gameState = STATE_TITLE
            startupIgnoreUntil = now + 30
        end
    end

    return 0
end

return {init = init, run = run}
