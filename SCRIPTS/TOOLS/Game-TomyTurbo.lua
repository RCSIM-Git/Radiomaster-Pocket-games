--[[
  ========================================================================
  Game-TomyTurbo.lua - Tomy Turnin' Turbo Dashboard for RadioMaster MT12
  Nostalgiczna gra retro inspirowana legendarną zabawką z lat 80.
  "Tomy Turnin' Turbo Dashboard / Turbo Racing Dashboard"!
  
  Sterowanie na aparaturze MT12:
  - KIEROWNICA : Sterowanie bolidem na ruchomej jezdni (CH1 / RUD / AIL / ST)
  - SPUST GAZU : Pociągnięcie = Gaz, Pchnięcie = Hamulec (CH2 / THR / ELE / TH)
  - PRZEŁĄCZNIK SB: Skrzynia biegów: GÓRA [LOW] (0-60 km/h), DÓŁ [HIGH] (do 160 km/h!)
  - ROLKA [ENT]: Start silnika / Restart / Stacyjka zapłonu
  - Klawisz RTN: Wyjście z gry (EVT_EXIT_BREAK / EVT_VIRTUAL_EXIT)
  
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local state = "OFF" -- "OFF", "RUNNING", "CRASH", "NO_FUEL"
local playerX = 64
local speed = 0
local targetSpeed = 0
local gear = 1 -- 1: LOW, 2: HIGH
local fuel = 100
local odometer = 0
local engineSoundTimer = 0

-- Geometria zakrętów jezdni (imitacja bębna mechanicznego)
local curveAngle = 0
local roadCurveTarget = 0
local nextCurveChange = 0
local roadYOffset = 0

-- Obiekty na torze
local obstacles = {}
local fuelCans = {}
local lastSpawn = 0

-- Bezpieczne operacje na tablicach bez biblioteki standardowej 'table'
local function removeAt(t, index)
  local len = #t
  for j = index, len - 1 do
    t[j] = t[j + 1]
  end
  t[len] = nil
end

local function isEnter(event)
  if not event or event == 0 then return false end
  return event == EVT_ENTER_BREAK or event == EVT_VIRTUAL_ENTER or event == EVT_ROT_BREAK
end

local function isExit(event)
  if not event or event == 0 then return false end
  return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

local function getSteering()
  local val = getValue("ST")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("ch1")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("st")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("rud")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("ail")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("ST")
  if val and type(val) == "number" then return val / 1024 end
  val = getValue("ch1")
  if val and type(val) == "number" then return val / 1024 end
  return 0
end

local function getThrottle()
  local val = getValue("TH")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("ch2")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("th")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("thr")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("ele")
  if val and type(val) == "number" and math.abs(val) > 8 then return val / 1024 end
  val = getValue("TH")
  if val and type(val) == "number" then return val / 1024 end
  val = getValue("ch2")
  if val and type(val) == "number" then return val / 1024 end
  return 0
end

local function initGame()
  playerX = 64
  speed = 0
  fuel = 100
  odometer = 0
  obstacles = {}
  fuelCans = {}
  curveAngle = 0
  roadCurveTarget = 0
  state = "RUNNING"
  playTone(600, 100, 30)
  playTone(1200, 150, 0)
end

local function spawnItems()
  local now = getTime()
  if now - lastSpawn > 40 then
    lastSpawn = now

    -- Auto przeciwnika na losowym pasie
    if math.random() > 0.4 then
      local laneOffset = math.random(-22, 22)
      obstacles[#obstacles + 1] = {
        relX = laneOffset,
        y = -8,
        speed = math.random(25, 65),
        w = 11,
        h = 7
      }
    end

    -- Kanister z paliwem [F]
    if math.random() > 0.65 and fuel < 75 then
      local fOffset = math.random(-20, 20)
      fuelCans[#fuelCans + 1] = { relX = fOffset, y = -6 }
    end
  end
end

local function drawPlayerCar(x, y)
  local ix = math.floor(x - 6)
  local iy = math.floor(y)

  -- Koła
  lcd.drawFilledRectangle(ix - 1, iy + 1, 2, 3, 1)
  lcd.drawFilledRectangle(ix + 11, iy + 1, 2, 3, 1)
  lcd.drawFilledRectangle(ix - 1, iy + 5, 2, 3, 1)
  lcd.drawFilledRectangle(ix + 11, iy + 5, 2, 3, 1)

  -- Karoseria
  lcd.drawFilledRectangle(ix + 1, iy, 10, 8, 1)
  lcd.drawFilledRectangle(ix + 3, iy + 2, 6, 3, 0)
  lcd.drawFilledRectangle(ix + 2, iy + 7, 8, 1, 0)
end

local function run(event)
  if isExit(event) then return 2 end

  lcd.clear()
  local now = getTime()

  local st = getSteering()
  local th = getThrottle()
  local sa = getValue("sa") or -1024
  local sb = getValue("sb") or 0

  if isEnter(event) then
    if state == "OFF" or state == "CRASH" or state == "NO_FUEL" then
      initGame()
    end
  end

  if state == "OFF" then
    lcd.drawFilledRectangle(0, 0, 128, 11, 1)
    lcd.drawText(10, 2, "TOMY TURBO DASHBOARD", INVERS + BOLD)

    lcd.drawText(6, 16, "KULTOWA GRA WYSCIGOWA 80s", SMLSIZE + BOLD)
    lcd.drawText(6, 26, "- Rolka [ENT] / Spust: Start", SMLSIZE)
    lcd.drawText(6, 35, "- Skrzynia [SB]: LOW / HIGH", SMLSIZE)
    lcd.drawText(6, 44, "- Kierownica: Sterowanie", SMLSIZE)
    lcd.drawText(6, 53, "- Spust: Gaz i Hamulec", SMLSIZE)

    if sa > 200 or th > 0.3 then
      initGame()
    end
    return 0

  elseif state == "CRASH" then
    lcd.drawFilledRectangle(12, 10, 104, 42, 0)
    lcd.drawRectangle(12, 10, 104, 42)
    lcd.drawFilledRectangle(13, 11, 102, 10, 1)
    lcd.drawText(36, 12, "! CRASH !", INVERS + BOLD)

    lcd.drawText(20, 25, "DYSTANS: " .. math.floor(odometer) .. " KM", BOLD)
    lcd.drawText(16, 38, "[Rolka / Gaz] Restartuj", SMLSIZE)

    if isEnter(event) or th > 0.4 then
      initGame()
    end
    return 0

  elseif state == "NO_FUEL" then
    lcd.drawFilledRectangle(12, 10, 104, 42, 0)
    lcd.drawRectangle(12, 10, 104, 42)
    lcd.drawFilledRectangle(13, 11, 102, 10, 1)
    lcd.drawText(36, 12, "! BRAK PALIWA !", INVERS + BOLD)

    lcd.drawText(24, 25, "WYNIK: " .. math.floor(odometer) .. " KM", BOLD)
    lcd.drawText(18, 38, "[Rolka / Gaz] Zatankuj", SMLSIZE)

    if isEnter(event) or th > 0.4 then
      initGame()
    end
    return 0
  end

  -- Skrzynia biegów z przełącznika SB (góra = LOW, dół = HIGH)
  gear = (sb > 0) and 2 or 1
  local maxGearSpeed = (gear == 1) and 65 or 155

  if th > 0.05 then
    targetSpeed = math.floor(th * maxGearSpeed)
  elseif th < -0.1 then
    targetSpeed = 0
  else
    targetSpeed = 15
  end

  if speed < targetSpeed then
    speed = speed + ((gear == 1) and 2.5 or 1.5)
  elseif speed > targetSpeed then
    speed = speed - 3.5
  end
  if speed < 0 then speed = 0 end

  if speed > 10 and (now - engineSoundTimer > 12) then
    engineSoundTimer = now
    local pitch = 250 + math.floor(speed * 8)
    if gear == 2 then pitch = pitch + 300 end
    playTone(pitch, 25, 0)
  end

  fuel = fuel - (speed / 1800)
  if fuel <= 0 then
    fuel = 0
    state = "NO_FUEL"
    playTone(500, 300, 0)
    return 0
  end

  odometer = odometer + (speed / 3000)

  -- Zakręty jezdni
  if now > nextCurveChange then
    nextCurveChange = now + math.random(80, 160)
    roadCurveTarget = math.random(-18, 18)
  end
  curveAngle = curveAngle + (roadCurveTarget - curveAngle) * 0.04

  playerX = playerX + (st * (speed / 25))

  local roadCenter = 64 + curveAngle
  local roadHalfWidth = 28
  local minX = roadCenter - roadHalfWidth + 6
  local maxX = roadCenter + roadHalfWidth - 6

  if playerX < minX or playerX > maxX then
    playTone(350, 250, 0)
    state = "CRASH"
    return 0
  end

  roadYOffset = (roadYOffset + (speed / 12)) % 10

  -- Krawędzie drogi
  for y = 0, 42, 2 do
    local factor = (y / 42)
    local curRoadX = 64 + (curveAngle * factor)
    lcd.drawPoint(math.floor(curRoadX - roadHalfWidth), y)
    lcd.drawPoint(math.floor(curRoadX + roadHalfWidth), y)
  end

  -- Pasy środkowe
  for y = -8, 42, 8 do
    local dy = math.floor(y + roadYOffset)
    if dy >= 0 and dy <= 40 then
      local curRoadX = 64 + (curveAngle * (dy / 42))
      lcd.drawLine(math.floor(curRoadX), dy, math.floor(curRoadX), dy + 3, SOLID, 1)
    end
  end

  spawnItems()

  -- Kanistry
  for i = #fuelCans, 1, -1 do
    local fc = fuelCans[i]
    fc.y = fc.y + (speed / 18)
    if fc.y > 42 then
      removeAt(fuelCans, i)
    else
      local curRoadX = 64 + (curveAngle * (fc.y / 42))
      local fx = math.floor(curRoadX + fc.relX)
      lcd.drawRectangle(fx - 2, math.floor(fc.y) - 2, 5, 5)
      lcd.drawText(fx - 1, math.floor(fc.y) - 2, "F", SMLSIZE)

      if math.abs(playerX - fx) < 7 and math.abs(33 - fc.y) < 5 then
        fuel = math.min(100, fuel + 30)
        playTone(2200, 80, 0)
        removeAt(fuelCans, i)
      end
    end
  end

  -- Auta przeciwników
  for i = #obstacles, 1, -1 do
    local obs = obstacles[i]
    local relSpd = (speed - obs.speed) / 18
    obs.y = obs.y + relSpd

    if obs.y > 44 or obs.y < -20 then
      removeAt(obstacles, i)
    else
      local curRoadX = 64 + (curveAngle * (obs.y / 42))
      local ox = math.floor(curRoadX + obs.relX)
      local oy = math.floor(obs.y)

      lcd.drawRectangle(ox - 5, oy - 2, 10, 6)
      lcd.drawFilledRectangle(ox - 3, oy - 1, 6, 4, 1)

      if math.abs(playerX - ox) < 8 and math.abs(33 - obs.y) < 5 then
        playTone(300, 300, 0)
        state = "CRASH"
        return 0
      end
    end
  end

  drawPlayerCar(playerX, 33)

  -- DASHBOARD
  lcd.drawLine(0, 43, 127, 43, SOLID, 1)
  lcd.drawFilledRectangle(0, 44, 128, 20, 0)

  local gearStr = (gear == 1) and "LO" or "HI"
  lcd.drawFilledRectangle(1, 46, 24, 16, 1)
  lcd.drawText(4, 47, "GEAR", INVERS + SMLSIZE)
  lcd.drawText(5, 54, gearStr, INVERS + BOLD)

  local spdStr = string.format("%d", math.floor(speed))
  lcd.drawText(30, 45, "SPEED", SMLSIZE)
  lcd.drawText(30, 52, spdStr, BOLD)
  lcd.drawText(50, 56, "KMH", SMLSIZE)

  lcd.drawRectangle(68, 46, 26, 6)
  local spdW = math.floor((speed / 160) * 24)
  if spdW > 0 then
    lcd.drawFilledRectangle(69, 47, spdW, 4, 1)
  end

  lcd.drawText(68, 54, "FUEL", SMLSIZE)
  lcd.drawRectangle(88, 55, 38, 5)
  local fuelW = math.floor((fuel / 100) * 36)
  if fuelW > 0 then
    lcd.drawFilledRectangle(89, 56, fuelW, 3, 1)
  end

  local odoStr = string.format("%03dKM", math.floor(odometer))
  lcd.drawText(96, 45, odoStr, SMLSIZE)

  return 0
end

return { run = run, init = initGame }
