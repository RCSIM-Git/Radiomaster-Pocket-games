--[[
  ========================================================================
  LapTimer.lua - Surface RC Lap Timer & Race Tracker for RadioMaster MT12
  Precyzyjny stoper okrążeń z detekcją rekordu (PB) i sygnalizacją dźwiękową
  Obsługiwany przełącznikiem SD / SA lub kliknięciem rolki
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local laps = {}
local currentLapStart = 0
local sessionStart = 0
local isRunning = false
local bestLapTime = 0
local lastLapTime = 0
local prevTrigger = -1024
local newBestFlash = 0

local function isEnter(event)
  if not event or event == 0 then return false end
  return event == EVT_ENTER_BREAK or event == EVT_ROT_BREAK or event == EVT_VIRTUAL_ENTER
end

local function isExit(event)
  if not event or event == 0 then return false end
  return event == EVT_EXIT_BREAK or event == EVT_VIRTUAL_EXIT
end

local function formatTime(ticks)
  if ticks <= 0 then return "--:--.--" end
  local totalHundredths = ticks
  local hundredths = totalHundredths % 100
  local totalSeconds = math.floor(totalHundredths / 100)
  local seconds = totalSeconds % 60
  local minutes = math.floor(totalSeconds / 60)
  return string.format("%02d:%02d.%02d", minutes, seconds, hundredths)
end

local function init()
  laps = {}
  currentLapStart = 0
  sessionStart = 0
  isRunning = false
  bestLapTime = 0
  lastLapTime = 0
  prevTrigger = -1024
  newBestFlash = 0
end

local function triggerLap()
  local now = getTime()

  if not isRunning then
    -- Pierwsze kliknięcie: START sesji i okrążenia 1
    isRunning = true
    sessionStart = now
    currentLapStart = now
    playTone(1500, 150, 0)
    return
  end

  -- Zakończenie bieżącego okrążenia
  local lapDuration = now - currentLapStart
  currentLapStart = now
  lastLapTime = lapDuration

  -- Wstawiamy najnowsze na początek listy bez używania 'table'
  for i = #laps, 1, -1 do
    laps[i + 1] = laps[i]
  end
  laps[1] = lapDuration

  if #laps > 20 then
    laps[#laps] = nil
  end

  if bestLapTime == 0 or lapDuration < bestLapTime then
    bestLapTime = lapDuration
    newBestFlash = now + 150 -- miganie przez 1.5 sekundy
    playTone(2200, 200, 50)
    playTone(2600, 250, 0)
  else
    playTone(1800, 120, 0)
  end
end

local function getSwitchTrigger()
  local val = getValue("SD")
  if val and type(val) == "number" then return val end
  val = getValue("sd")
  if val and type(val) == "number" then return val end
  val = getValue("SA")
  if val and type(val) == "number" then return val end
  val = getValue("sa")
  if val and type(val) == "number" then return val end
  val = getValue("SB")
  if val and type(val) == "number" then return val end
  return -1024
end

local function run(event)
  local now = getTime()

  -- Klawisz wyjścia / resetu
  if isExit(event) then
    if isRunning then
      init()
      playTone(800, 200, 0)
      return 0
    else
      return 2
    end
  end

  lcd.clear()

  -- Odczyt wyzwalacza sprzętowego: przełącznik SD / SA / SB
  local triggerVal = getSwitchTrigger()

  -- Wykrycie zbocza narastającego (przełączenie / kliknięcie)
  if triggerVal > 400 and prevTrigger <= 400 then
    triggerLap()
  end
  prevTrigger = triggerVal

  -- Klawisze: Enter / Rolka = start/lap
  if isEnter(event) then
    triggerLap()
  end

  -- ====================================================================
  -- NAGŁÓWEK (y: 0 .. 9)
  -- ====================================================================
  lcd.drawFilledRectangle(0, 0, 128, 10, 1)
  lcd.drawText(2, 1, "LAP TIMER by RCSIM", INVERS + SMLSIZE)

  local lapNum = isRunning and (#laps + 1) or 0
  local lapStr = string.format("LAP %02d", lapNum)
  lcd.drawText(88, 1, lapStr, INVERS + SMLSIZE)

  -- ====================================================================
  -- CZAS BIEŻĄCEGO OKRĄŻENIA (Duży zegar)
  -- ====================================================================
  local curTicks = 0
  if isRunning then
    curTicks = now - currentLapStart
  end

  local curTimeStr = formatTime(curTicks)
  lcd.drawText(4, 13, curTimeStr, DBLSIZE)

  -- Flaga nowego rekordu (migający napis)
  if newBestFlash > now and ((math.floor(now / 15) % 2) == 0) then
    lcd.drawFilledRectangle(88, 13, 38, 11, 1)
    lcd.drawText(90, 14, "* NEW PB *", INVERS + SMLSIZE)
  end

  lcd.drawLine(0, 31, 127, 31, SOLID, 1)

  -- ====================================================================
  -- NAJLEPSZE I OSTATNIE OKRĄŻENIE (y: 33 .. 50)
  -- ====================================================================
  -- Lewa kolumna: BEST LAP
  lcd.drawText(2, 33, "BEST (PB):", SMLSIZE)
  local bestStr = (bestLapTime > 0) and formatTime(bestLapTime) or "--:--.--"
  lcd.drawText(2, 42, bestStr, SMLSIZE + BOLD)

  -- Prawa kolumna: LAST LAP + DELTA
  lcd.drawText(66, 33, "LAST LAP:", SMLSIZE)
  local lastStr = (lastLapTime > 0) and formatTime(lastLapTime) or "--:--.--"
  lcd.drawText(66, 42, lastStr, SMLSIZE)

  -- Delta względem PB
  if lastLapTime > 0 and bestLapTime > 0 and #laps > 1 then
    local delta = lastLapTime - bestLapTime
    local deltaStr = string.format("%+.2fs", delta / 100)
    lcd.drawText(106, 33, deltaStr, SMLSIZE)
  end

  -- ====================================================================
  -- DOLNY PASEK POMOCY (y: 54 .. 63)
  -- ====================================================================
  lcd.drawLine(0, 52, 127, 52, DOTTED, 1)
  if not isRunning then
    lcd.drawText(2, 54, "[SD/Rolka] Start  [EXIT] Wyjscie", SMLSIZE)
  else
    lcd.drawText(2, 54, "[SD/Rolka] Lap  [EXIT] Reset", SMLSIZE)
  end

  -- Łączny czas sesji
  if isRunning then
    local totalSec = math.floor((now - sessionStart) / 100)
    local totStr = string.format("TOT %02d:%02d", math.floor(totalSec / 60), totalSec % 60)
    lcd.drawText(85, 54, totStr, SMLSIZE)
  end

  return 0
end

return { run = run, init = init }
