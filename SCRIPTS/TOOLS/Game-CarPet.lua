--[[
  ========================================================================
  Game-CarPet.lua - MT12 Car Pet: Virtual RC Garage Edition
  Wirtualny zwierzak garażowy RC dla aparatury RadioMaster MT12!
  Zbuduj, dbaj, ładuj baterie LiPo, myj po szutrze i ewoluuj swój model!
  
  Sterowanie na MT12:
  - KIEROWNICA (ST) : Wybór opcji w menu (lewo / prawo) oraz sterowanie w mini-grze
  - SPUST GAZU (TH) : Pociągnięcie = Zatwierdź / Gaz w mini-grze
  - Klawisz ENTER   : Zatwierdź akcję
  - Klawisz EXIT    : Powrót / Wyjście
  
  Kompatybilny z EdgeTX 2.10+ (ekran 128x64 mono)
  ========================================================================
--]]

local LCD_W = 128
local LCD_H = 64

-- Ewolucje modelu (Od pudła Tamiya po ikony światowego modelarstwa RC!)
local STAGE_KIT = 0         -- TAMIYA BOX KIT (Gołe podwozie do złożenia)
local STAGE_STOCK = 1       -- ROLLING CHASSIS 1/16 (Podstawowy model)
local STAGE_TUNED = 2       -- CARBON PRO ROLLER (Włókno węglowe, alu, łożyska)
-- Ikoniczne ewolucje finałowe:
local STAGE_RC10 = 3        -- TEAM ASSOCIATED RC10 "GOLD TUB" (Legenda Buggy 1984)
local STAGE_YOKOMO = 4      -- YOKOMO YD-2 / SILVIA S15 (Król RWD Driftu)
local STAGE_TRX4 = 5        -- TRAXXAS TRX-4 DEFENDER (Król Przeprawy i Crawlera)
local STAGE_SUBARU_WRC = 6  -- SUBARU IMPREZA WRC '99 (Ikona Rajdów McRae 555)
local STAGE_INFRACTION = 7  -- ARRMA INFRACTION 8S (Potwór Street Bashingu 100+ mph)

local STAGE_NAMES = {
  [0] = "TAMIYA KIT",
  [1] = "STOCK CHASSIS",
  [2] = "CARBON PRO",
  [3] = "RC10 GOLD TUB",
  [4] = "YOKOMO YD-2",
  [5] = "TRX-4 CRAWLER",
  [6] = "SUBARU WRC 99",
  [7] = "INFRACTION 8S"
}

-- Ekrany gry
local MODE_MAIN = 0
local MODE_STATS = 1
local MODE_MINIGAME = 2
local MODE_ANIM = 3

local currentMode = MODE_MAIN
local animText = ""
local animTimer = 0
local animType = ""

-- Ikony akcji na górnym pasku
local ICONS = { "BATT", "RACE", "WASH", "TUNE", "STAT" }
local selectedIcon = 1
local prevWheelTurn = 0

-- Stan wirtualnego auta
local pet = {
  stage = STAGE_KIT,
  buildProgress = 0, -- 0..100 (dla etapu KIT)
  lipo = 100,        -- 0..100%
  cleanliness = 100, -- 0..100%
  tires = 100,       -- 0..100%
  happiness = 80,    -- 0..100%
  xp = 0,
  odometer = 0,      -- km
  racesWon = 0,
  lastTick = 0
}

-- Mini-gra (Dyno & Drift Test)
local mgX = 64
local mgScore = 0
local mgTimeLeft = 0

--------------------------------------------------------------------------------
-- ZAPIS I ODCZYT STANU Z KARTY SD
--------------------------------------------------------------------------------
local SAVE_PATH = "/SCRIPTS/TOOLS/CARPET/carpet.dat"

local function saveState()
  local f = io.open(SAVE_PATH, "w")
  if f then
    local line = string.format("%d,%d,%d,%d,%d,%d,%d,%d,%d",
      pet.stage, pet.buildProgress, pet.lipo, pet.cleanliness,
      pet.tires, pet.happiness, pet.xp, math.floor(pet.odometer), pet.racesWon)
    io.write(f, line)
    io.close(f)
  end
end

local function loadState()
  local f = io.open(SAVE_PATH, "r")
  if f then
    local line = io.read(f, 128)
    io.close(f)
    if line and #line > 5 then
      local parts = {}
      for v in string.gmatch(line, "([^,]+)") do
        parts[#parts + 1] = tonumber(v)
      end
      if #parts >= 9 then
        pet.stage = parts[1] or 0
        pet.buildProgress = parts[2] or 0
        pet.lipo = parts[3] or 100
        pet.cleanliness = parts[4] or 100
        pet.tires = parts[5] or 100
        pet.happiness = parts[6] or 80
        pet.xp = parts[7] or 0
        pet.odometer = parts[8] or 0
        pet.racesWon = parts[9] or 0
      end
    end
  end
end

local function triggerAnim(aType, text, duration)
  animType = aType
  animText = text
  animTimer = getTime() + duration
  currentMode = MODE_ANIM
end

--------------------------------------------------------------------------------
-- SPRAWDZENIE EWOLUCJI MODELU
--------------------------------------------------------------------------------
local function checkEvolution()
  if pet.stage == STAGE_KIT then
    if pet.buildProgress >= 100 then
      pet.stage = STAGE_STOCK
      pet.lipo = 100
      pet.tires = 100
      pet.cleanliness = 100
      pet.happiness = 100
      saveState()
      playTone(2000, 150, 50)
      playTone(2600, 200, 0)
      triggerAnim("EVO", "PODWOZIE ZLOZONE! Witaj w garazu!", 180)
    end

  elseif pet.stage == STAGE_STOCK then
    if pet.xp >= 120 and pet.odometer >= 4 then
      pet.stage = STAGE_TUNED
      saveState()
      playTone(2200, 150, 50)
      playTone(2800, 250, 0)
      triggerAnim("EVO", "PRO ROLLER! Karbon i lozyska!", 180)
    end

  elseif pet.stage == STAGE_TUNED then
    if pet.xp >= 350 and pet.odometer >= 12 then
      -- Wybór ścieżki ewolucji zależnie od stylu jazdy i serwisu
      if pet.tires < 35 then
        -- Dużo poślizgów, spalone opony -> Król RWD Driftu
        pet.stage = STAGE_YOKOMO
        triggerAnim("EVO", "EWOLUCJA: YOKOMO YD-2 DRIFT!", 220)
      elseif pet.racesWon >= 5 and pet.happiness >= 80 then
        -- Mistrz prób czasowych i czysty lakier -> Rajdowa Legenda 555
        pet.stage = STAGE_SUBARU_WRC
        triggerAnim("EVO", "EWOLUCJA: SUBARU IMPREZA WRC!", 220)
      elseif pet.cleanliness < 40 and pet.odometer >= 15 then
        -- Błoto, piasek, duży przebieg w terenie -> Król Przeprawy
        pet.stage = STAGE_TRX4
        triggerAnim("EVO", "EWOLUCJA: TRAXXAS TRX-4!", 220)
      elseif pet.xp >= 480 then
        -- Ekstremalne katowanie pełnego gazu -> 100+ mph Street Basher
        pet.stage = STAGE_INFRACTION
        triggerAnim("EVO", "EWOLUCJA: ARRMA INFRACTION 8S!", 220)
      else
        -- Zrównoważony, klasyczny styl wyścigowy -> Święty Graal Buggy
        pet.stage = STAGE_RC10
        triggerAnim("EVO", "EWOLUCJA: ASSOCIATED RC10!", 220)
      end
      saveState()
      playTone(2200, 150, 50)
      playTone(3000, 300, 0)
    end
  end
end

--------------------------------------------------------------------------------
-- RYSOWANIE MODELU W GARAŻU (Sprite Pixel Art)
--------------------------------------------------------------------------------
local function drawCarSprite(x, y, stage)
  local ix = math.floor(x)
  local iy = math.floor(y)

  if stage == STAGE_KIT then
    -- Pudło Tamiya Kit i goła rama
    lcd.drawRectangle(ix - 18, iy - 6, 36, 16)
    lcd.drawText(ix - 15, iy - 3, "TAMIYA", SMLSIZE)
    lcd.drawFilledRectangle(ix - 8, iy + 11, 16, 2, 1)

  elseif stage == STAGE_STOCK then
    -- Podstawowe małe podwozie 1/16
    lcd.drawFilledRectangle(ix - 14, iy + 6, 5, 4, 1)
    lcd.drawFilledRectangle(ix + 9, iy + 6, 5, 4, 1)
    lcd.drawFilledRectangle(ix - 12, iy, 24, 8, 1)
    lcd.drawFilledRectangle(ix - 6, iy + 1, 12, 4, 0)

  elseif stage == STAGE_TUNED then
    -- Carbon Pro Roller (obniżone zawieszenie, alu)
    lcd.drawFilledRectangle(ix - 16, iy + 7, 5, 4, 1)
    lcd.drawFilledRectangle(ix + 11, iy + 7, 5, 4, 1)
    lcd.drawFilledRectangle(ix - 15, iy + 1, 30, 7, 1)
    lcd.drawFilledRectangle(ix - 8, iy + 2, 16, 3, 0)
    lcd.drawFilledRectangle(ix + 12, iy - 2, 4, 3, 1)

  elseif stage == STAGE_RC10 then
    -- TEAM ASSOCIATED RC10 "GOLD TUB" (1984)
    -- Duże tylne koła talerzowe (Dish wheels)
    lcd.drawFilledRectangle(ix - 18, iy + 3, 7, 7, 1)
    -- Węższe przednie koła z żebrowaniem
    lcd.drawFilledRectangle(ix + 11, iy + 5, 4, 5, 1)
    -- Złota wanna podwozia (tapered gold tub)
    lcd.drawFilledRectangle(ix - 13, iy + 3, 25, 4, 1)
    -- Przednia wieża amortyzatorów (shock tower)
    lcd.drawLine(ix + 9, iy + 4, ix + 9, iy - 3, SOLID, 1)
    -- Kokpit z kierowcą w kasku
    lcd.drawFilledRectangle(ix - 6, iy, 12, 4, 0)
    lcd.drawPoint(ix - 1, iy + 1)
    -- Klasyczne wysokie skrzydło z lexanu na drucikach
    lcd.drawLine(ix - 16, iy + 3, ix - 16, iy - 4, SOLID, 1)
    lcd.drawFilledRectangle(ix - 20, iy - 5, 9, 2, 1)

  elseif stage == STAGE_YOKOMO then
    -- YOKOMO YD-2 / NISSAN SILVIA S15 (Drift King)
    -- Bardzo niska gleba i koła w negatywie (camber)
    lcd.drawFilledRectangle(ix - 17, iy + 7, 5, 4, 1)
    lcd.drawFilledRectangle(ix + 12, iy + 7, 5, 4, 1)
    -- Smukła karoseria z poszerzeniami Rocket Bunny
    lcd.drawFilledRectangle(ix - 16, iy + 2, 32, 6, 1)
    lcd.drawFilledRectangle(ix - 8, iy + 3, 16, 3, 0)
    -- Przedni splitter
    lcd.drawFilledRectangle(ix + 15, iy + 7, 3, 1, 1)
    -- Wielkie skrzydło GT na wysokich wspornikach
    lcd.drawLine(ix - 18, iy + 2, ix - 14, iy - 4, SOLID, 1)
    lcd.drawFilledRectangle(ix - 20, iy - 5, 10, 2, 1)

  elseif stage == STAGE_TRX4 then
    -- TRAXXAS TRX-4 DEFENDER (Ultimate Scaler)
    -- Ogromne opony terenowe z mostami portalowymi
    lcd.drawFilledRectangle(ix - 17, iy + 5, 7, 7, 1)
    lcd.drawFilledRectangle(ix + 11, iy + 5, 7, 7, 1)
    -- Wysokie, masywne nadwozie wyprawowe
    lcd.drawFilledRectangle(ix - 16, iy - 2, 33, 8, 1)
    lcd.drawFilledRectangle(ix - 7, iy - 2, 14, 4, 0) -- okna
    -- Bagażnik dachowy z listwą LED
    lcd.drawRectangle(ix - 13, iy - 6, 23, 3)
    lcd.drawFilledRectangle(ix + 7, iy - 6, 3, 3, 1)  -- szperacz
    -- Wyciągarka i stinger z przodu
    lcd.drawFilledRectangle(ix + 17, iy + 2, 3, 4, 1)

  elseif stage == STAGE_SUBARU_WRC then
    -- SUBARU IMPREZA WRC '99 (555 Rally Legend)
    -- Koła rajdowe ze złotymi felgami i chlapaczami
    lcd.drawFilledRectangle(ix - 16, iy + 6, 5, 5, 1)
    lcd.drawFilledRectangle(ix + 11, iy + 6, 5, 5, 1)
    -- Agresywny zderzak rajdowy z wielkimi halogenami
    lcd.drawFilledRectangle(ix - 15, iy + 1, 31, 6, 1)
    lcd.drawFilledRectangle(ix - 7, iy + 2, 15, 3, 0)
    lcd.drawFilledRectangle(ix + 15, iy + 2, 2, 4, 1) -- elektrownia rajdowa
    -- Wlot dachowy (roof scoop)
    lcd.drawFilledRectangle(ix - 2, iy - 2, 4, 2, 1)
    -- Pokaźne skrzydło WRC
    lcd.drawFilledRectangle(ix - 17, iy - 3, 4, 4, 1)

  else
    -- ARRMA INFRACTION 8S (Street Basher 100+ mph)
    -- Długa, niska sylwetka restomod muscle truck
    lcd.drawFilledRectangle(ix - 19, iy + 6, 5, 4, 1)
    lcd.drawFilledRectangle(ix + 13, iy + 6, 5, 4, 1)
    lcd.drawFilledRectangle(ix - 18, iy + 1, 36, 6, 1)
    lcd.drawFilledRectangle(ix - 8, iy + 2, 14, 3, 0)
    -- Wielki przedni splitter aero
    lcd.drawFilledRectangle(ix + 17, iy + 6, 4, 2, 1)
    -- Wydechy wyprowadzone bokiem / kominy w masce
    lcd.drawPoint(ix + 6, iy)
    -- Tylny duckbill i dyfuzor
    lcd.drawFilledRectangle(ix - 20, iy + 1, 3, 3, 1)
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

--------------------------------------------------------------------------------
-- GŁÓWNA PĘTLA PROGRAMU
--------------------------------------------------------------------------------
local function init()
  loadState()
  pet.lastTick = getTime()
end

local function run(event)
  lcd.clear()
  local now = getTime()

  -- Odczyty wejść MT12
  local st = getSteering()
  local th = getThrottle()

  -- 1. EKRAN ANIMACJI / KOMUNIKATU
  if currentMode == MODE_ANIM then
    lcd.drawFilledRectangle(10, 12, 108, 40, 0)
    lcd.drawRectangle(10, 12, 108, 40)
    lcd.drawFilledRectangle(11, 13, 106, 10, 1)
    lcd.drawText(38, 14, "! WARSZTAT !", INVERS + BOLD)

    lcd.drawText(14, 27, animText, SMLSIZE)
    lcd.drawText(24, 39, "[Czekaj...]", SMLSIZE)

    if now > animTimer or isEnter(event) or isExit(event) then
      currentMode = MODE_MAIN
    end
    return 0

  -- 2. EKRAN STATYSTYK (MODE_STATS)
  elseif currentMode == MODE_STATS then
    lcd.drawFilledRectangle(0, 0, 128, 10, 1)
    lcd.drawText(2, 1, "STATYSTYKI GARAZU MT12", INVERS + SMLSIZE)

    lcd.drawText(2, 13, "Model: " .. STAGE_NAMES[pet.stage], SMLSIZE + BOLD)
    lcd.drawText(2, 22, string.format("Przebieg: %d km", pet.odometer), SMLSIZE)
    lcd.drawText(2, 31, string.format("Doswiadczenie: %d XP", pet.xp), SMLSIZE)
    lcd.drawText(2, 40, string.format("Wygrane jazdy: %d", pet.racesWon), SMLSIZE)

    -- Odczyt baterii radia MT12 jako smaczek
    local txBt = (getValue("tx-voltage") or 74) / 10
    lcd.drawText(2, 49, string.format("Bateria MT12: %.1fV", txBt), SMLSIZE)

    lcd.drawLine(0, 56, 127, 56, SOLID, 1)
    lcd.drawText(2, 57, "[EXIT] Wroc do garazu", SMLSIZE)

    if isExit(event) or isEnter(event) then
      currentMode = MODE_MAIN
    end
    return 0

  -- 3. MINI-GRA: DYNO & DRIFT JOYRIDE
  elseif currentMode == MODE_MINIGAME then
    lcd.drawFilledRectangle(0, 0, 128, 10, 1)
    lcd.drawText(2, 1, "DYNO RUN: Utrzymaj obroty!", INVERS + SMLSIZE)

    mgTimeLeft = mgTimeLeft - 1

    -- Sterowanie autem w mini-grze
    local steerNorm = st / 1024
    mgX = mgX + steerNorm * 2.5
    if mgX < 20 then mgX = 20 end
    if mgX > 108 then mgX = 108 end

    -- Zielona strefa obrotów (x: 44..84)
    lcd.drawRectangle(44, 20, 40, 18)
    lcd.drawText(46, 22, "TARGET RPM", SMLSIZE)

    -- Auto gracza
    drawCarSprite(mgX, 40, pet.stage)

    -- Punktacja gdy jesteś w strefie i trzymasz gaz
    if mgX >= 44 and mgX <= 84 and th > 200 then
      mgScore = mgScore + 2
      lcd.drawText(52, 29, "!POWER!", SMLSIZE + INVERS)
      if (math.floor(now / 10) % 2) == 0 then
        playTone(1800, 30, 0)
      end
    end

    lcd.drawText(2, 54, "PUNKTY: " .. mgScore, SMLSIZE + BOLD)
    lcd.drawText(85, 54, "CZAS: " .. math.floor(mgTimeLeft / 15), SMLSIZE)

    if mgTimeLeft <= 0 then
      pet.xp = pet.xp + mgScore
      pet.odometer = pet.odometer + 1
      pet.lipo = math.max(0, pet.lipo - 15)
      pet.tires = math.max(0, pet.tires - 10)
      pet.cleanliness = math.max(0, pet.cleanliness - 12)
      pet.happiness = math.min(100, pet.happiness + 20)
      if mgScore > 60 then pet.racesWon = pet.racesWon + 1 end
      saveState()
      checkEvolution()
      triggerAnim("RACE", "JAZDA ZAKONCZONA! +" .. mgScore .. " XP!", 150)
    end
    return 0
  end

  -- ====================================================================
  -- EKRAN GŁÓWNY GARAŻU (MODE_MAIN)
  -- ====================================================================
  -- 1. Górny pasek menu (ikony akcji)
  lcd.drawFilledRectangle(0, 0, 128, 11, 0)
  for i = 1, #ICONS do
    local bx = (i - 1) * 25 + 2
    if i == selectedIcon then
      lcd.drawFilledRectangle(bx, 0, 24, 11, 1)
      lcd.drawText(bx + 2, 2, ICONS[i], INVERS + SMLSIZE)
    else
      lcd.drawRectangle(bx, 0, 24, 11)
      lcd.drawText(bx + 2, 2, ICONS[i], SMLSIZE)
    end
  end

  -- Nawigacja kierownicą lub kółkiem
  if event == EVT_ROT_LEFT or (st < -350 and prevWheelTurn >= -350) then
    selectedIcon = selectedIcon - 1
    if selectedIcon < 1 then selectedIcon = #ICONS end
    playTone(1600, 30, 0)
    prevWheelTurn = -1
  elseif event == EVT_ROT_RIGHT or (st > 350 and prevWheelTurn <= 350) then
    selectedIcon = selectedIcon + 1
    if selectedIcon > #ICONS then selectedIcon = 1 end
    playTone(1600, 30, 0)
    prevWheelTurn = 1
  elseif math.abs(st) < 200 then
    prevWheelTurn = 0
  end

  -- 2. Scena garażowa (Środek)
  lcd.drawLine(0, 48, 127, 48, SOLID, 1) -- Linia podłogi warsztatu

  -- Nazwa stadium i model
  lcd.drawText(4, 14, STAGE_NAMES[pet.stage], SMLSIZE + BOLD)

  -- Wyświetlanie auta
  drawCarSprite(64, 34, pet.stage)

  -- 3. Paski stanu (Bateria LiPo, Opony, Czystość)
  -- Prawa strona (x: 88..126)
  lcd.drawText(86, 14, "LIPO", SMLSIZE)
  lcd.drawRectangle(106, 15, 20, 5)
  local lpW = math.floor((pet.lipo / 100) * 18)
  if lpW > 0 then lcd.drawFilledRectangle(107, 16, lpW, 3, 1) end

  lcd.drawText(86, 23, "TIRE", SMLSIZE)
  lcd.drawRectangle(106, 24, 20, 5)
  local trW = math.floor((pet.tires / 100) * 18)
  if trW > 0 then lcd.drawFilledRectangle(107, 25, trW, 3, 1) end

  lcd.drawText(86, 32, "WASH", SMLSIZE)
  lcd.drawRectangle(106, 33, 20, 5)
  local clW = math.floor((pet.cleanliness / 100) * 18)
  if clW > 0 then lcd.drawFilledRectangle(107, 34, clW, 3, 1) end

  -- Komunikat statusu na dole
  lcd.drawLine(0, 49, 127, 49, DOTTED, 1)
  if pet.stage == STAGE_KIT then
    local buildStr = string.format("MONTAZ KITU: %d%% [Wcisnij Gaz!]", pet.buildProgress)
    lcd.drawText(2, 52, buildStr, SMLSIZE)
  else
    if pet.lipo < 20 then
      lcd.drawText(2, 52, "! ROZLADOWANY LIPO - Naladuj !", SMLSIZE + INVERS)
    elseif pet.cleanliness < 30 then
      lcd.drawText(2, 52, "! AUTO UBRUDZONE BLOTEM !", SMLSIZE)
    elseif pet.tires < 30 then
      lcd.drawText(2, 52, "! OPONY LYSE - Wymien w Tune !", SMLSIZE)
    else
      lcd.drawText(2, 52, "[Rolka/Gaz] Wybierz akcje", SMLSIZE)
    end
  end

  -- ====================================================================
  -- OBSŁUGA AKCJI (SPUST GAZU LUB ENTER)
  -- ====================================================================
  if isEnter(event) or th > 400 then
    if pet.stage == STAGE_KIT then
      -- Składanie podwozia
      pet.buildProgress = pet.buildProgress + 25
      playTone(1800, 60, 0)
      if pet.buildProgress >= 100 then
        checkEvolution()
      end
    else
      local action = ICONS[selectedIcon]

      if action == "BATT" then
        -- Ładowanie LiPo
        pet.lipo = 100
        saveState()
        playTone(2000, 100, 30)
        playTone(2400, 150, 0)
        triggerAnim("BATT", "LADOWANIE LIPO: 100% Naladowany!", 120)

      elseif action == "RACE" then
        -- Start mini-gry
        if pet.lipo >= 15 then
          mgScore = 0
          mgTimeLeft = 200
          currentMode = MODE_MINIGAME
          playTone(1500, 80, 0)
        else
          triggerAnim("ERR", "Rozladowany! Naladuj baterie!", 100)
        end

      elseif action == "WASH" then
        -- Mycie auta
        pet.cleanliness = 100
        pet.happiness = math.min(100, pet.happiness + 15)
        saveState()
        playTone(1800, 80, 20)
        playTone(2200, 120, 0)
        triggerAnim("WASH", "DETAILING: Lakier lsni jak nowy!", 120)

      elseif action == "TUNE" then
        -- Wymiana opon / serwis
        pet.tires = 100
        pet.xp = pet.xp + 20
        saveState()
        checkEvolution()
        playTone(1600, 100, 0)
        triggerAnim("TUNE", "SERWIS: Nowe opony zamontowane!", 120)

      elseif action == "STAT" then
        currentMode = MODE_STATS
      end
    end
  end

  if isExit(event) then
    return 2
  end

  return 0
end

return { run = run, init = init }
