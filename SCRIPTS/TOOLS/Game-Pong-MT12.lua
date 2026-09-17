--[[
  ========================================================================
  Game-Pong-MT12.lua - Retro Arcade Pong for RadioMaster MT12
  Sterowanie:
  - KIEROWNICA (ST) / ROLKA : Płynny ruch paletki góra / dół
  - SPUST (TH)              : Pociągnięcie = Smash! (podkręcenie piłki)
  - Klawisz RTN [EXIT]      : Wyjście z gry
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local ballX, ballY = 64, 32
local ballDx, ballDy = 2, 1
local playerY = 24
local aiY = 24
local paddleH = 16
local paddleW = 3
local scorePlayer = 0
local scoreAi = 0
local rallyCount = 0
local isStarted = false

local function isExit(event)
  if not event or event == 0 then return false end
  return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

local function isEnter(event)
  if not event or event == 0 then return false end
  return event == EVT_ENTER_BREAK or event == EVT_ROT_BREAK or event == EVT_VIRTUAL_ENTER
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

local function resetBall(toPlayer)
  ballX = 64
  ballY = 32
  ballDx = toPlayer and -2 or 2
  ballDy = (math.random(0, 1) == 0) and 1 or -1
  rallyCount = 0
end

local function init()
  scorePlayer = 0
  scoreAi = 0
  resetBall(false)
  isStarted = false
end

local function run(event)
  if isExit(event) then return 2 end

  lcd.clear()

  -- Ekran startowy
  if not isStarted then
    lcd.drawFilledRectangle(0, 0, 128, 11, 1)
    lcd.drawText(4, 2, "PONG MT12", INVERS + BOLD)
    lcd.drawText(80, 2, "by RCSIM", INVERS + SMLSIZE)

    lcd.drawText(6, 16, "RETRO ARCADE PONG", SMLSIZE + BOLD)
    lcd.drawText(6, 26, "- Kierownica/Rolka: Ruch paletki", SMLSIZE)
    lcd.drawText(6, 35, "- Spust gazu: Smash! (podkrecenie)", SMLSIZE)
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

  -- 1. Odczyt kierownicy MT12 do pozycji paletki
  local st = getSteering()
  local th = getThrottle()

  -- Kierownica: -1024 (lewo/góra) do +1024 (prawo/dół) -> mapujemy na pozycję Y paletki
  local targetY = math.floor(((st + 1024) / 2048) * (64 - paddleH))
  playerY = playerY + (targetY - playerY) * 0.4 -- płynne wygładzenie

  -- Kółko scrolla jako alternatywne sterowanie paletką
  if event == EVT_ROT_LEFT then
    playerY = playerY - 4
  elseif event == EVT_ROT_RIGHT then
    playerY = playerY + 4
  end

  if playerY < 0 then playerY = 0 end
  if playerY > 64 - paddleH then playerY = 64 - paddleH end

  -- 2. Prosta AI przeciwnika
  local aiCenter = aiY + (paddleH / 2)
  if aiCenter < ballY - 2 then
    aiY = aiY + 1.2
  elseif aiCenter > ballY + 2 then
    aiY = aiY - 1.2
  end
  if aiY < 0 then aiY = 0 end
  if aiY > 64 - paddleH then aiY = 64 - paddleH end

  -- 3. Fizyka piłki
  local smashBonus = (th > 300) and 1.3 or 1.0

  ballX = ballX + ballDx * smashBonus
  ballY = ballY + ballDy

  -- Odbicie od góry i dołu ekranu
  if ballY <= 1 then
    ballY = 1
    ballDy = -ballDy
    playTone(1200, 30, 0)
  elseif ballY >= 62 then
    ballY = 62
    ballDy = -ballDy
    playTone(1200, 30, 0)
  end

  -- Odbicie od paletki gracza (po lewej, x: 4)
  if ballX <= 4 + paddleW and ballX >= 4 then
    if ballY >= playerY - 2 and ballY <= playerY + paddleH + 2 then
      ballX = 4 + paddleW + 1
      ballDx = math.abs(ballDx)
      local hitOffset = (ballY - (playerY + paddleH / 2)) / (paddleH / 2)
      ballDy = hitOffset * 2.5
      rallyCount = rallyCount + 1
      playTone(1800, 40, 0)
    end

  -- Odbicie od paletki AI (po prawej, x: 120)
  elseif ballX >= 120 - paddleW and ballX <= 120 then
    if ballY >= aiY - 2 and ballY <= aiY + paddleH + 2 then
      ballX = 120 - paddleW - 1
      ballDx = -math.abs(ballDx)
      rallyCount = rallyCount + 1
      playTone(1600, 40, 0)
    end
  end

  -- Punktacja
  if ballX < 0 then
    -- Punkt dla AI
    scoreAi = scoreAi + 1
    playTone(700, 150, 0)
    resetBall(true)
  elseif ballX > 128 then
    -- Punkt dla Gracza
    scorePlayer = scorePlayer + 1
    playTone(2400, 150, 0)
    resetBall(false)
  end

  -- 4. Rysowanie elementów gry
  -- Siatka na środku
  for y = 0, 63, 6 do
    lcd.drawLine(64, y, 64, y + 3, SOLID, 1)
  end

  -- Wyniki
  local scoreStr = string.format("%d   %d", scorePlayer, scoreAi)
  lcd.drawText(54, 2, scoreStr, SMLSIZE + BOLD)

  -- Paletka gracza (lewa)
  lcd.drawFilledRectangle(4, math.floor(playerY), paddleW, paddleH, 1)

  -- Paletka AI (prawa)
  lcd.drawFilledRectangle(120, math.floor(aiY), paddleW, paddleH, 1)

  -- Piłka
  lcd.drawFilledRectangle(math.floor(ballX - 1), math.floor(ballY - 1), 3, 3, 1)

  -- Wskaźnik Smash na spuście
  if th > 300 then
    lcd.drawText(2, 54, "!SMASH!", SMLSIZE + INVERS)
  end

  return 0
end

return { run = run, init = init }
