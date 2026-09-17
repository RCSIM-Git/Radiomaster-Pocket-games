--[[
  ========================================================================
  Game-RCRacer.lua - Retro Highway Racer for RadioMaster MT12
  Dedykowana gra wyścigowa dla aparatury pistoletowej MT12!
  Sterowanie:
  - KIEROWNICA : Płynny skręt autem lewo / prawo (CH1 / RUD / AIL / ST)
  - SPUST GAZU : Pociągnij = Gaz (do 220 km/h), Pchnij = Hamulec!
  - ROLKA [ENT]: Start gry / Restart (EVT_ROT_BREAK / EVT_ENTER_BREAK)
  - SWITCH SD  : Nitro Boost!
  - Klawisz RTN: Wyjście z gry (EVT_EXIT_BREAK / EVT_VIRTUAL_EXIT)
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local state = "MENU" -- "MENU", "PLAY", "GAMEOVER"
local score = 0
local hiScore = 0
local speed = 60
local distance = 0
local lives = 3
local playerX = 64
local roadOffset = 0
local nitroTime = 0

-- Tablice obiektów
local traffic = {}
local coins = {}
local lastSpawn = 0

-- Bezpieczne operacje na tablicach bez biblioteki standardowej 'table'
local function removeAt(t, index)
  local len = #t
  for j = index, len - 1 do
    t[j] = t[j + 1]
  end
  t[len] = nil
end

-- Detekcja przycisków
local function isEnter(event)
  if not event or event == 0 then return false end
  return event == EVT_ENTER_BREAK or event == EVT_VIRTUAL_ENTER or event == EVT_ROT_BREAK
end

local function isExit(event)
  if not event or event == 0 then return false end
  return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

local function getSteering()
  -- Sprawdzamy fizyczne pokrętło ST oraz kanał CH1
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
  -- Sprawdzamy fizyczny spust TH oraz kanał CH2
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
  score = 0
  speed = 60
  distance = 0
  lives = 3
  playerX = 64
  traffic = {}
  coins = {}
  lastSpawn = getTime()
  nitroTime = 0
  state = "PLAY"
  playTone(1800, 100, 0)
end

local function init()
  state = "MENU"
  score = 0
  speed = 60
  distance = 0
  lives = 3
  playerX = 64
  traffic = {}
  coins = {}
  nitroTime = 0
end

local function spawnEntities()
  local now = getTime()
  if now - lastSpawn > 35 then
    lastSpawn = now

    -- Losowe auto w ruchu
    if math.random() > 0.35 then
      local laneX = 26 + math.random(0, 3) * 19
      local tSpeed = math.random(30, 80)
      traffic[#traffic + 1] = { x = laneX, y = -10, speed = tSpeed, w = 12, h = 8 }
    end

    -- Losowa moneta
    if math.random() > 0.5 then
      local cLaneX = 28 + math.random(0, 3) * 19
      coins[#coins + 1] = { x = cLaneX, y = -8, r = 2 }
    end
  end
end

local function drawCar(x, y, isPlayer, isNitro)
  local ix = math.floor(x - 6)
  local iy = math.floor(y)

  -- Koła
  lcd.drawFilledRectangle(ix - 1, iy, 2, 3, 1)
  lcd.drawFilledRectangle(ix + 11, iy, 2, 3, 1)
  lcd.drawFilledRectangle(ix - 1, iy + 6, 2, 3, 1)
  lcd.drawFilledRectangle(ix + 11, iy + 6, 2, 3, 1)

  if isPlayer then
    if isNitro and ((math.floor(getTime() / 5) % 2) == 0) then
      lcd.drawRectangle(ix + 1, iy + 1, 10, 7)
    else
      lcd.drawFilledRectangle(ix + 1, iy + 1, 10, 7, 1)
      lcd.drawFilledRectangle(ix + 3, iy + 3, 6, 3, 0)
    end
    lcd.drawFilledRectangle(ix, iy + 8, 12, 1, 1)
  else
    lcd.drawRectangle(ix + 1, iy + 1, 10, 7)
    lcd.drawFilledRectangle(ix + 3, iy + 2, 6, 4, 1)
  end
end

local function run(event)
  if isExit(event) then return 2 end

  lcd.clear()
  local now = getTime()

  -- 1. EKRAN MENU
  if state == "MENU" then
    lcd.drawFilledRectangle(0, 0, 128, 11, 1)
    lcd.drawText(2, 2, "RC RACER 3D", INVERS + BOLD)
    lcd.drawText(80, 2, "by RCSIM", INVERS + SMLSIZE)

    lcd.drawText(6, 15, "RC RACER by RCSIM", SMLSIZE + BOLD)
    lcd.drawText(6, 24, "- Kierownica: Skret lewo/prawo", SMLSIZE)
    lcd.drawText(6, 33, "- Spust gazu: Pociagnij = Gaz", SMLSIZE)
    lcd.drawText(6, 42, "- Przelacznik SD: Nitro Boost!", SMLSIZE)

    lcd.drawLine(0, 52, 127, 52, SOLID, 1)
    lcd.drawText(8, 55, "[Wcisnij Rolke / Gaz] START", SMLSIZE + BOLD)

    local th = getThrottle()
    if isEnter(event) or th > 0.3 then
      initGame()
    end
    return 0

  -- 2. EKRAN KONIEC GRY
  elseif state == "GAMEOVER" then
    lcd.drawFilledRectangle(10, 10, 108, 44, 0)
    lcd.drawRectangle(10, 10, 108, 44)
    lcd.drawFilledRectangle(11, 11, 106, 10, 1)
    lcd.drawText(34, 12, "GAME OVER!", INVERS + BOLD)

    lcd.drawText(20, 25, "WYNIK: " .. score, BOLD)
    lcd.drawText(20, 35, "REKORD: " .. hiScore, SMLSIZE)

    lcd.drawText(14, 44, "[Rolka / Gaz] Zagraj znowu", SMLSIZE)

    local th = getThrottle()
    if isEnter(event) or th > 0.4 then
      initGame()
    end
    return 0
  end

  -- 3. STAN ROZGRYWKI (PLAY)
  local steer = getSteering()
  local thr = getThrottle()
  local sd = getValue("sd") or -1024

  local hasNitro = false
  if (sd > 400 or nitroTime > now) then
    hasNitro = true
  end

  local targetSpeed = 60
  if hasNitro then
    targetSpeed = 220
  elseif thr > 0.08 then
    targetSpeed = 60 + math.floor(thr * 130)
  elseif thr < -0.1 then
    targetSpeed = math.max(15, 60 + math.floor(thr * 50))
  end

  if speed < targetSpeed then
    speed = speed + 2
  elseif speed > targetSpeed then
    speed = speed - 3
  end

  -- Ruch gracza
  playerX = playerX + (steer * (speed / 32))
  if playerX < 24 then playerX = 24 end
  if playerX > 104 then playerX = 104 end

  roadOffset = (roadOffset + (speed / 15)) % 16
  distance = distance + (speed / 60)
  score = math.floor(distance)

  spawnEntities()

  -- Rysowanie jezdni
  lcd.drawLine(18, 0, 18, 63, SOLID, 1)
  lcd.drawLine(110, 0, 110, 63, SOLID, 1)

  for gy = 0, 63, 6 do
    local py = (gy + roadOffset) % 64
    lcd.drawPoint(8, py)
    lcd.drawPoint(120, py)
  end

  for y = -16, 64, 12 do
    local dy = math.floor(y + roadOffset)
    if dy >= 0 and dy <= 58 then
      lcd.drawLine(41, dy, 41, dy + 5, SOLID, 1)
      lcd.drawLine(64, dy, 64, dy + 5, SOLID, 1)
      lcd.drawLine(87, dy, 87, dy + 5, SOLID, 1)
    end
  end

  -- Obsługa monet
  for i = #coins, 1, -1 do
    local c = coins[i]
    c.y = c.y + (speed / 20)
    if c.y > 64 then
      removeAt(coins, i)
    else
      lcd.drawFilledRectangle(c.x - 1, c.y - 1, 3, 3, 1)
      if math.abs(playerX - c.x) < 8 and math.abs(52 - c.y) < 6 then
        score = score + 50
        distance = distance + 50
        playTone(2400, 60, 0)
        removeAt(coins, i)
      end
    end
  end

  -- Obsługa aut ruchu drogowego
  for i = #traffic, 1, -1 do
    local t = traffic[i]
    local relSpeed = (speed - t.speed) / 20
    t.y = t.y + relSpeed

    if t.y > 68 or t.y < -30 then
      removeAt(traffic, i)
    else
      drawCar(t.x, t.y, false, false)

      if math.abs(playerX - t.x) < 10 and math.abs(52 - t.y) < 7 then
        if hasNitro then
          playTone(1200, 80, 0)
          score = score + 100
          removeAt(traffic, i)
        else
          lives = lives - 1
          playTone(600, 200, 0)
          removeAt(traffic, i)
          if lives <= 0 then
            if score > hiScore then hiScore = score end
            state = "GAMEOVER"
          end
        end
      end
    end
  end

  -- Rysowanie auta gracza
  drawCar(playerX, 52, true, hasNitro)

  -- HUD
  local spdStr = string.format("%dkm/h", math.floor(speed))
  lcd.drawFilledRectangle(0, 0, 18, 64, 0)
  lcd.drawText(1, 2, spdStr, SMLSIZE)

  for l = 1, lives do
    lcd.drawFilledRectangle(2, 14 + (l * 6), 4, 4, 1)
  end

  lcd.drawFilledRectangle(111, 0, 17, 64, 0)
  lcd.drawText(112, 2, "PTS", SMLSIZE)
  local scStr = string.format("%d", score)
  lcd.drawText(112, 11, scStr, SMLSIZE)

  if hasNitro then
    lcd.drawText(112, 35, "!N2O!", SMLSIZE + INVERS)
  end

  return 0
end

return { run = run, init = init }
