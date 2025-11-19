--[[
  Universal Moon Engine (UME) - Core

  Calendar-agnostic moon phase engine for Fantasy Grounds Unity.

  Design goals:
    * Do not depend on any specific calendar implementation.
    * Only use public calendar data in the campaign database.
    * Provide a simple, predictable per-moon configuration.
    * Expose helper functions to be called from XML window scripts.
]]

UniversalMoonEngine = UniversalMoonEngine or {};

local PHASES = {
  [1] = { name = "New Moon",          icon = "ume_moon_phase_1" },
  [2] = { name = "Evening Crescent",  icon = "ume_moon_phase_2" },
  [3] = { name = "First Quarter",     icon = "ume_moon_phase_3" },
  [4] = { name = "Waxing Gibbous",    icon = "ume_moon_phase_4" },
  [5] = { name = "Full Moon",         icon = "ume_moon_phase_5" },
  [6] = { name = "Waning Gibbous",    icon = "ume_moon_phase_6" },
  [7] = { name = "Last Quarter",      icon = "ume_moon_phase_7" },
  [8] = { name = "Morning Crescent",  icon = "ume_moon_phase_8" },
};

local function log(s)
  if not s or s == "" then
    return;
  end
  if ChatManager and ChatManager.SystemMessage then
    ChatManager.SystemMessage("[UME] " .. s);
  else
    print("[UME] " .. s);
  end
end

-------------------------------------------------------------------
-- DB helpers
-------------------------------------------------------------------

function UniversalMoonEngine.ensureConfigRoot()
  local nodeCalendar = DB.createNode("calendar");
  local nodeUme = DB.createChild(nodeCalendar, "ume");
  local nodeMoons = DB.createChild(nodeUme, "moons");
  return nodeMoons;
end

function UniversalMoonEngine.getMoonsNode()
  local nodeMoons = DB.findNode("calendar.ume.moons");
  if not nodeMoons and Session.IsHost then
    nodeMoons = UniversalMoonEngine.ensureConfigRoot();
  end
  return nodeMoons;
end

function UniversalMoonEngine.getMoonList()
  local nodeMoons = UniversalMoonEngine.getMoonsNode();
  local tResults = {};
  if not nodeMoons then
    return tResults;
  end

  for _, nodeMoon in ipairs(DB.getChildList(nodeMoons)) do
    table.insert(tResults, nodeMoon);
  end

  table.sort(tResults, function(a, b)
    local sa = DB.getValue(a, "name", "");
    local sb = DB.getValue(b, "name", "");
    return sa:lower() < sb:lower();
  end);

  return tResults;
end

function UniversalMoonEngine.getPrimaryMoon()
  local tMoons = UniversalMoonEngine.getMoonList();
  if #tMoons == 0 then
    return nil;
  end

  for _, nodeMoon in ipairs(tMoons) do
    if DB.getValue(nodeMoon, "primary", 0) ~= 0 then
      return nodeMoon;
    end
  end

  return tMoons[1];
end

-------------------------------------------------------------------
-- Calendar math helpers
-------------------------------------------------------------------

local function safeInt(n, nDefault)
  if type(n) ~= "number" then
    return nDefault or 0;
  end
  return math.floor(n + 0.0000001);
end

local function getMonthVarCalcFunc()
  local sMonthVarCalc = DB.getValue("calendar.data.periodvarcalc", "");
  if (sMonthVarCalc or "") == "" then
    return nil;
  end

  -- Support known calculators explicitly first
  if sMonthVarCalc == "gregorian" and CalendarManager.calcGregorianMonthVar then
    return CalendarManager.calcGregorianMonthVar;
  end
  if sMonthVarCalc == "golarion" and CalendarManager.calcGolarionMonthVar then
    return CalendarManager.calcGolarionMonthVar;
  end

  -- Fallback to naming convention: calc<Name>MonthVar
  local sFirst = sMonthVarCalc:sub(1, 1);
  local sRest = sMonthVarCalc:sub(2);
  local sFuncName = "calc" .. string.upper(sFirst) .. sRest .. "MonthVar";
  local f = CalendarManager[sFuncName];
  if type(f) == "function" then
    return f;
  end

  return nil;
end

local function getDaysInMonthForYear(nYear, nMonth)
  nYear = safeInt(nYear, 1);
  nMonth = safeInt(nMonth, 1);

  local nDaysBase = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);
  local nVar = 0;

  local fMonthVar = getMonthVarCalcFunc();
  if fMonthVar then
    local ok, nExtra = pcall(fMonthVar, nYear, nMonth);
    if ok and type(nExtra) == "number" then
      nVar = nExtra;
    end
  end

  return safeInt(nDaysBase + nVar, 0);
end

local function getDaysInYear(nYear)
  local nMonths = CalendarManager.getMonthsInYear();
  local nTotal = 0;

  for nMonth = 1, nMonths do
    nTotal = nTotal + getDaysInMonthForYear(nYear, nMonth);
  end

  return nTotal;
end

function UniversalMoonEngine.calculateEpochDay(sEpoch, nYear, nMonth, nDay)
  -- We intentionally ignore sEpoch for arithmetic; we only care about
  -- a stable ordering. If a ruleset supports multiple epochs, they will
  -- still advance monotonically within each epoch.
  nYear = safeInt(nYear, 1);
  nMonth = safeInt(nMonth, 1);
  nDay = safeInt(nDay, 1);

  if nYear < 1 then
    nYear = 1;
  end
  if nMonth < 1 then
    nMonth = 1;
  end
  local nMaxMonths = CalendarManager.getMonthsInYear();
  if nMonth > nMaxMonths then
    nMonth = nMaxMonths;
  end

  local nEpochDay = 0;

  -- Sum full years
  for y = 1, (nYear - 1) do
    nEpochDay = nEpochDay + getDaysInYear(y);
  end

  -- Sum full months in the current year
  for m = 1, (nMonth - 1) do
    nEpochDay = nEpochDay + getDaysInMonthForYear(nYear, m);
  end

  -- Add days in current month (0-based)
  nEpochDay = nEpochDay + (nDay - 1);

  return nEpochDay;
end

-------------------------------------------------------------------
-- Phase helpers
-------------------------------------------------------------------

function UniversalMoonEngine.getPhaseDef(nIndex)
  local rPhase = PHASES[nIndex];
  if not rPhase then
    rPhase = PHASES[1];
  end
  return rPhase;
end

function UniversalMoonEngine.getPhaseForMoon(nodeMoon, nEpochDay)
  if not nodeMoon then
    return nil;
  end

  nEpochDay = safeInt(nEpochDay, 0);

  local nCycle = safeInt(DB.getValue(nodeMoon, "cycle", 0), 0);
  if nCycle <= 0 then
    return nil;
  end

  local nOffset = safeInt(DB.getValue(nodeMoon, "offset", 0), 0);
  local nPhaseCount = safeInt(DB.getValue(nodeMoon, "phasecount", 8), 8);
  if nPhaseCount < 2 then
    nPhaseCount = 2;
  end

  -- Position within cycle (0 .. nCycle-1)
  local nPos = (nEpochDay + nOffset) % nCycle;

  local nStep = nCycle / nPhaseCount;
  if nStep <= 0 then
    nStep = 1;
  end

  local nIndex = math.floor(nPos / nStep) + 1;
  if nIndex < 1 then
    nIndex = 1;
  elseif nIndex > nPhaseCount then
    nIndex = nPhaseCount;
  end

  local rBase = UniversalMoonEngine.getPhaseDef(nIndex);

  return {
    index = nIndex,
    name = rBase.name,
    icon = rBase.icon,
    position = nPos,
    cycle = nCycle,
  };
end

function UniversalMoonEngine.getCurrentPhase(nEpochDay)
  local nodeMoon = UniversalMoonEngine.getPrimaryMoon();
  if not nodeMoon then
    return nil;
  end
  return UniversalMoonEngine.getPhaseForMoon(nodeMoon, nEpochDay);
end

-------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------

function onInit()
  if Session.IsHost then
    UniversalMoonEngine.ensureConfigRoot();
    log("Universal Moon Engine initialized.");
  end
end

function onClose()
  -- Nothing to tear down yet; DB handlers are attached by the
  -- calendar merge script, not here.
end
