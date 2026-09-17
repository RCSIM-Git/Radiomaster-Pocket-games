--[[
  ========================================================================
  CarTuner.lua - Surface RC Curve & Setup Visualizer for RadioMaster MT12
  Narzędzie diagnostyczno-pomocnicze do wizualizacji krzywych kierownicy,
  gazu, Expo, Dual-Rate oraz podglądu profili pod Buggy, Drift, Crawler, Rally
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local profiles = {
  {
    name = "BUGGY (Zmoto)",
    desc = "Offroad & Skoki",
    stExpo = -20,
    stDr = 90,
    thPunch = "PULSED ABS",
    limiter = "SB: 50/75/100%",
    tip = "Expo -20% stabilizuje kierunek przy duzej predkosci."
  },
  {
    name = "DRIFT (Strada)",
    desc = "RWD / CS Kontra",
    stExpo = -35,
    stDr = 100,
    thPunch = "MID-SMOOTH",
    limiter = "P1: Gyro 65%",
    tip = "Miekki srodek ulatwia plynne trzymanie kata w poslizgu."
  },
  {
    name = "CRAWLER (MN82)",
    desc = "Skaly & Przeprawa",
    stExpo = 0,
    stDr = 100,
    thPunch = "CRAWL-CURVE",
    limiter = "P2: DragBrake",
    tip = "Pierwsze 50% spustu daje tylko 20% mocy silnika."
  },
  {
    name = "RALLY (14303)",
    desc = "Hyper Go 3S Szuter",
    stExpo = -15,
    stDr = 85,
    thPunch = "ANTI-FLIP",
    limiter = "SB: 3-Power",
    tip = "Ograniczenie skretu przy pelnym gazie zapobiega rolkom."
  }
}

local currentProfile = 1
local viewMode = 1 -- 1: Profile & Curve, 2: Realtime Live Monitor

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

local function init()
  currentProfile = 1
  viewMode = 1
end

local function run(event)
  if isExit(event) then return 2 end

  lcd.clear()

  -- Obsługa klawiszy / kółka
  if event == EVT_ROT_RIGHT or event == EVT_DOWN_BREAK then
    currentProfile = currentProfile + 1
    if currentProfile > #profiles then currentProfile = 1 end
    playTone(1800, 50, 0)
  elseif event == EVT_ROT_LEFT or event == EVT_UP_BREAK then
    currentProfile = currentProfile - 1
    if currentProfile < 1 then currentProfile = #profiles end
    playTone(1800, 50, 0)
  elseif isEnter(event) then
    viewMode = 3 - viewMode -- przełącz między 1 a 2
    playTone(2200, 80, 0)
  end

  local prof = profiles[currentProfile]

  -- Odczyty na żywo z aparatury MT12
  local st = getSteering()
  local th = getThrottle()
  local p1 = getValue("P1") or getValue("p1") or 0
  local p2 = getValue("P2") or getValue("p2") or 0

  -- ====================================================================
  -- NAGŁÓWEK (y: 0 .. 9)
  -- ====================================================================
  lcd.drawFilledRectangle(0, 0, 128, 10, 1)
  lcd.drawText(2, 1, "CAR TUNER: " .. prof.name, INVERS + SMLSIZE)

  local modeLabel = (viewMode == 1) and "[PROFIL]" or "[LIVE-OSD]"
  lcd.drawText(86, 1, modeLabel, INVERS + SMLSIZE)

  if viewMode == 1 then
    -- ==================================================================
    -- WIDOK 1: PARAMETRY I KRZYWA PROFILU
    -- ==================================================================
    -- Lewa strona: parametry tekstowe
    lcd.drawText(2, 12, prof.desc, SMLSIZE + BOLD)
    lcd.drawText(2, 21, "St Expo: " .. prof.stExpo .. "%", SMLSIZE)
    lcd.drawText(2, 29, "St D/R : " .. prof.stDr .. "%", SMLSIZE)
    lcd.drawText(2, 37, "Th Type: " .. prof.thPunch, SMLSIZE)
    lcd.drawText(2, 45, "Control: " .. prof.limiter, SMLSIZE)

    -- Prawa strona: Mini wykres odpowiedzi kierownicy (Krzywa Expo)
    -- Ramka wykresu 36x36 (x: 88 .. 124, y: 13 .. 49)
    lcd.drawRectangle(88, 13, 37, 37)
    lcd.drawLine(88, 31, 124, 31, DOTTED, 1) -- Oś pozioma (neutral)
    lcd.drawLine(106, 13, 106, 49, DOTTED, 1) -- Oś pionowa (środek)

    -- Rysowanie przybliżonej krzywej Expo dla profilu
    local expoFactor = prof.stExpo / 100
    for px = -16, 16, 2 do
      local normX = px / 16
      -- Wzór przybliżonego Expo: y = x * (1 - expo) + x^3 * expo
      local normY = normX * (1 - expoFactor) + (normX * normX * normX) * expoFactor
      local py = math.floor(normY * 16)
      lcd.drawPoint(106 + px, 31 - py)
    end

    -- Kropka na żywo pokazująca bieżące wychylenie kierownicy użytkownika!
    local curNormX = math.min(1, math.max(-1, st / 1024))
    local curNormY = curNormX * (1 - expoFactor) + (curNormX * curNormX * curNormX) * expoFactor
    local dotX = math.floor(106 + curNormX * 16)
    local dotY = math.floor(31 - curNormY * 16)
    lcd.drawFilledRectangle(dotX - 1, dotY - 1, 3, 3, 1)

    -- Dolny pasek podpowiedzi
    lcd.drawLine(0, 52, 127, 52, SOLID, 1)
    lcd.drawText(2, 54, "[ROL] Zmien model  [ENT] Podglad", SMLSIZE)

  else
    -- ==================================================================
    -- WIDOK 2: LIVE MONITOR SYGNAŁÓW
    -- ==================================================================
    lcd.drawText(2, 12, "SYGNALY WEJSC / KANALOW:", SMLSIZE + BOLD)

    local stPct = math.floor((st / 1024) * 100)
    local thPct = math.floor((th / 1024) * 100)
    local p1Pct = math.floor(((p1 + 1024) / 2048) * 100)
    local p2Pct = math.floor(((p2 + 1024) / 2048) * 100)

    lcd.drawText(4, 23, "ST (Kier): " .. string.format("%+d%%", stPct), SMLSIZE)
    lcd.drawText(68, 23, "P1 (Gyr): " .. p1Pct .. "%", SMLSIZE)

    lcd.drawText(4, 34, "TH (Gaz) : " .. string.format("%+d%%", thPct), SMLSIZE)
    lcd.drawText(68, 34, "P2 (D/R): " .. p2Pct .. "%", SMLSIZE)

    -- Porada konfiguracji
    lcd.drawLine(0, 46, 127, 46, SOLID, 1)
    lcd.drawText(2, 49, prof.tip, SMLSIZE)
    lcd.drawText(2, 57, "[Rolka/ENT] Wroc do wykresu", SMLSIZE)
  end

  return 0
end

return { run = run, init = init }
