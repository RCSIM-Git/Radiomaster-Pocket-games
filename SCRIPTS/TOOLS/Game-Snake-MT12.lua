--[[
  ========================================================================
  Game-Snake-MT12.lua - Retro Classic Snake for RadioMaster MT12
  Sterowanie:
  - KIEROWNICA (ST) / ROLKA : Skręt w lewo / w prawo
  - SPUST GAZU (TH)         : Pociągnięcie = Turbo Boost!
  - ROLKA [ENT]             : Restart po kolizji
  - Klawisz RTN [EXIT]      : Wyjście z gry
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local snake = {}
local dir = 0 -- 0: Prawo, 1: Dół, 2: Lewo, 3: Góra
local foodX, foodY = 15, 8
local score = 0
local hiScore = 0
local isGameOver = false
local isStarted = false
local lastStep = 0
local prevWheelTurn = 0

-- Bezpieczne operacje na tablicach bez biblioteki 'table'
local function insertHead(t, newElem)
  for i = #t, 1, -1 do
    t[i + 1] = t[i]
  end
  t[1] = newElem
end

local function removeTail(t)
  if #t > 0 then
    t[#t] = nil
  end
end

local function isEnter(event)
  if not event or event == 0 then return false end
  return event == EVT_ENTER_BREAK or event == EVT_ROT_BREAK or event == EVT_VIRTUAL_ENTER
end

local function isExit(event)
  if not event or event == 0 then return false end
  return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

local function getSteering()
  local val = getValue("ST")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("ch1")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("st")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("rud")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("ail")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("ST")
  if val and type(val) == "number" then return val end
  val = getValue("ch1")
  if val and type(val) == "number" then return val end
  return 0
end

local function getThrottle()
  local val = getValue("TH")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("ch2")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("th")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("thr")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("ele")
  if val and type(val) == "number" and math.abs(val) > 8 then return val end
  val = getValue("TH")
  if val and type(val) == "number" then return val end
  val = getValue("ch2")
  if val and type(val) == "number" then return val end
  return 0
end

local function spawnFood()
  foodX = math.random(2, 29)
  foodY = math.random(2, 13)
end

local function init()
  snake = {
    { x = 10, y = 8 },
    { x = 9, y = 8 },
    { x = 8, y = 8 }
  }
  dir = 0
  score = 0
  isGameOver = false
  isStarted = false
  lastStep = getTime()
  prevWheelTurn = 0
  spawnFood()
end

local function run(event)
  if isExit(event) then return 2 end

  lcd.clear()

  -- Ekran startowy
  if not isStarted then
    lcd.drawFilledRectangle(0, 0, 128, 11, 1)
    lcd.drawText(4, 2, "SNAKE MT12", INVERS + BOLD)
    lcd.drawText(80, 2, "by RCSIM", INVERS + SMLSIZE)

    lcd.drawText(6, 16, "RETRO CLASSIC SNAKE", SMLSIZE + BOLD)
    lcd.drawText(6, 26, "- Kierownica/Rolka: Skret lewo/prawo", SMLSIZE)
    lcd.drawText(6, 35, "- Spust gazu: Turbo Boost!", SMLSIZE)
    lcd.drawText(6, 44, "- Klawisz RTN: Wyjscie", SMLSIZE)

    lcd.drawLine(0, 53, 127, 53, SOLID, 1)
    lcd.drawText(10, 55, "[Rolka / Gaz / ENT] START", SMLSIZE + BOLD)

    local th = getThrottle()
    if isEnter(event) or th > 300 then
      isStarted = true
      playTone(1800, 100, 0)
    end
    return 0
  end

  local now = getTime()

  local th = getThrottle()

  if isGameOver then
    lcd.drawFilledRectangle(20, 15, 88, 34, 0)
    lcd.drawRectangle(20, 15, 88, 34)
    lcd.drawFilledRectangle(21, 16, 86, 9, 1)
    lcd.drawText(36, 17, "GAME OVER", INVERS + BOLD)
    lcd.drawText(28, 28, "WYNIK: " .. score, BOLD)
    lcd.drawText(24, 38, "[Rolka/ENT] Zagraj znowu", SMLSIZE)

    if isEnter(event) or th > 400 then
      init()
    end
    return 0
  end

  -- Odczyt sterowania MT12 (kierownica lub kółko scrolla)
  local st = getSteering()

  -- Detekcja skrętu kołem kierownicy lub rolką
  if event == EVT_ROT_LEFT or (st < -350 and prevWheelTurn >= -350) then
    -- Skręt w lewo
    dir = (dir + 3) % 4
    playTone(1600, 30, 0)
    prevWheelTurn = -1
  elseif event == EVT_ROT_RIGHT or (st > 350 and prevWheelTurn <= 350) then
    -- Skręt w prawo
    dir = (dir + 1) % 4
    playTone(1600, 30, 0)
    prevWheelTurn = 1
  elseif math.abs(st) < 200 then
    prevWheelTurn = 0
  end

  -- Szybkość gry (Turbo przy pociągnięciu spustu gazu)
  local stepInterval = (th > 200) and 8 or 16
  if now - lastStep >= stepInterval then
    lastStep = now

    -- Nowa głowa węża
    local head = snake[1]
    local newX = head.x
    local newY = head.y

    if dir == 0 then newX = newX + 1
    elseif dir == 1 then newY = newY + 1
    elseif dir == 2 then newX = newX - 1
    elseif dir == 3 then newY = newY - 1
    end

    -- Kolizja ze ścianą
    if newX < 1 or newX > 30 or newY < 1 or newY > 14 then
      isGameOver = true
      playTone(600, 200, 0)
      if score > hiScore then hiScore = score end
      return 0
    end

    -- Kolizja ze swoim ciałem
    for i = 1, #snake do
      if snake[i].x == newX and snake[i].y == newY then
        isGameOver = true
        playTone(600, 200, 0)
        if score > hiScore then hiScore = score end
        return 0
      end
    end

    insertHead(snake, { x = newX, y = newY })

    -- Zjedzenie jabłka
    if newX == foodX and newY == foodY then
      score = score + 10
      playTone(2200, 60, 0)
      spawnFood()
    else
      removeTail(snake)
    end
  end

  -- Rysowanie planszy (siatka 30x14 pól o wielkości 4x4 px)
  -- Ramka boiska
  lcd.drawRectangle(2, 2, 124, 58)

  -- Jedzenie
  lcd.drawFilledRectangle(foodX * 4, foodY * 4, 3, 3, 1)

  -- Wąż
  for i = 1, #snake do
    local seg = snake[i]
    if i == 1 then
      -- Głowa
      lcd.drawFilledRectangle(seg.x * 4, seg.y * 4, 4, 4, 1)
    else
      -- Ciało
      lcd.drawFilledRectangle(seg.x * 4 + 1, seg.y * 4 + 1, 2, 2, 1)
    end
  end

  -- Wynik na dole
  local scoreStr = string.format("PKT:%d", score)
  lcd.drawText(6, 4, scoreStr, SMLSIZE)

  if th > 200 then
    lcd.drawText(90, 4, "!TURBO!", SMLSIZE + INVERS)
  end

  return 0
end

return { run = run, init = init }
