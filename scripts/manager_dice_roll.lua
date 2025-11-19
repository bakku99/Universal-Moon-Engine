--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	NOTES
--
--	Format for tColor data:
--		diceskin = int
--		dicebodycolor = string [hex color]
--		dicetextcolor = string [hex color]
--
--	Format for _tDefaultsData data:
--		table (string, tColor)
--
--	Format for _tActionData data:
--		bSkipDefault = bool
--		sDefaultKey = string [name of default key to use]
--		tModesAllowed = table (numerical index, string)
--		tModesCustom = table (string, tColor) ["" as key is default mode]
--
--	Format for _tActorTypeData and _tActorSystemData data:
--		bSkipDefault = bool
--		sDefaultKey = string [name of default key to use]
--		tCustom = tColor
--
--	Format for _tActorCustomData data:
--		tCustom = tColor
--

function onTabletopInit()
	DiceRollManager.loadSettings();
end
function onTabletopClose()
	DiceRollManager.saveSettings();
end

function loadSettings()
	if not GlobalRegistry or not GlobalRegistry.colordicerolls then
		return;
	end
	local tData = GlobalRegistry.colordicerolls[Session.RulesetName];
	if not tData then
		return;
	end

	if DiceRollManager.hasActions() then
		for k,tModes in pairs(tData.custombymode or {}) do
			for sMode,v in pairs(tModes) do
				DiceRollManager.setActionModeSkin(k, sMode, v);
			end
		end
		for k,v in pairs(tData.skipdefault or {}) do
			DiceRollManager.setActionSkipDefault(k, v);
		end
	end

	for k,v in pairs(tData.actortype or {}) do
		DiceRollManager.setActorTypeSkipDefault(k, v.bSkipDefault);
		DiceRollManager.setActorTypeSkin(k, v.tCustom);
	end
	for k,v in pairs(tData.actorsystem or {}) do
		DiceRollManager.setActorSystemSkipDefault(k, v.bSkipDefault);
		DiceRollManager.setActorSystemSkin(k, v.tCustom);
	end
	for k,v in pairs(tData.actorcustom or {}) do
		DiceRollManager.setActorCustom(k, v);
	end
end
function saveSettings()
	if not GlobalRegistry then
		return;
	end

	-- Save custom color information
	local tData = {};

	local tCustomModeColors = {};
	local tCustomSkip = {};
	for k,v in pairs(DiceRollManager.getActionData()) do
		for sMode,v2 in pairs(v.tModesCustom or {}) do
			tCustomModeColors[k] = tCustomModeColors[k] or {};
			tCustomModeColors[k][sMode] = v2;
		end
		if v.bSkipDefault then
			tCustomSkip[k] = true;
		end
	end
	if next(tCustomModeColors) then
		tData.custombymode = tCustomModeColors;
	end
	if next(tCustomSkip) then
		tData.skipdefault = tCustomSkip;
	end

	local tActorType = {};
	for k,v in pairs(DiceRollManager.getActorTypeData()) do
		if v.bSkipDefault or v.tCustom then
			tActorType[k] = { bSkipDefault = v.bSkipDefault, tCustom = v.tCustom, };
		end
	end
	if next(tActorType) then
		tData.actortype = tActorType;
	end
	local tActorSystem = {};
	for k,v in pairs(DiceRollManager.getActorSystemData()) do
		if v.bSkipDefault or v.tCustom then
			tActorSystem[k] = { bSkipDefault = v.bSkipDefault, tCustom = v.tCustom, };
		end
	end
	if next(tActorSystem) then
		tData.actorsystem = tActorSystem;
	end
	local tActorCustom = DiceRollManager.getActorCustomData();
	if next(tActorCustom) then
		tData.actorcustom = tActorCustom;
	end

	if next(tData) then
		GlobalRegistry.colordicerolls = GlobalRegistry.colordicerolls or {};
		GlobalRegistry.colordicerolls[Session.RulesetName] = tData;
	else
		if GlobalRegistry.colordicerolls and GlobalRegistry.colordicerolls[Session.RulesetName] then
			GlobalRegistry.colordicerolls[Session.RulesetName] = nil;
		end
	end
end

--
--	DICE TABLE ADDITIONS
--

function helperAddDice(tTargetDice, tSourceDice, tData, tDiceSkin)
	for kDie,sDie in ipairs(tSourceDice) do
		local tDie = DiceRollManager.helperBuildDie(sDie, tData, tDiceSkin);
		if tDie then
			if tData and tData.index then
				table.insert(tTargetDice, tData.index + kDie - 1, tDie);
			else
				table.insert(tTargetDice, tDie);
			end
		end
	end
end
function helperBuildDie(sDie, tData, tDiceSkin)
	if (sDie or "") == "" then
		return nil;
	end
	local tDie = { type = sDie };
	DiceRollManager.helperModDie(tDie, tData, tDiceSkin);
	return tDie;
end
function helperModDie(tDie, tData, tDiceSkin)
	if not tDie then
		return;
	end
	if tData and tData.iconcolor and tDie.type then
		if tData.iconcolor == "FF00FF" then
			if tDie.type:sub(1,1) == "-" then
				tDie.type = "-p" .. tDie.type:sub(3);
			else
				tDie.type = "p" .. tDie.type:sub(2);
			end
		elseif tData.iconcolor == "00FF00" then
			if tDie.type:sub(1,1) == "-" then
				tDie.type = "-g" .. tDie.type:sub(3);
			else
				tDie.type = "g" .. tDie.type:sub(2);
			end
		else
			tDie.iconcolor = tData.iconcolor;
		end
	end
	if tDiceSkin then
		tDie.diceskin = tDiceSkin.diceskin;
		tDie.dicebodycolor = tDiceSkin.dicebodycolor;
		tDie.dicetextcolor = tDiceSkin.dicetextcolor;
	end
end

--
--	DAMAGE DICE TABLE ADDITIONS
--

local _tDamageModes = {};
function registerDamageTypeMode(sMode)
	if not StringManager.contains(_tDamageModes) then
		table.insert(_tDamageModes, sMode);
	end
end

function registerDamageKey(sDefaultKey)
	DiceRollManager.setAction("damage", { sDefaultKey = sDefaultKey, tModesAllowed = _tDamageModes });
end
function registerDamageTypeKey(sDamageType, sDefaultKey)
	if (sDamageType or "") == "" then
		return;
	end
	DiceRollManager.setAction("damage-type-" .. sDamageType:gsub("%s", "-"), { sDefaultKey = sDefaultKey, tModesAllowed = _tDamageModes });
end

function addDamageDice(tTargetDice, tSourceDice, tData)
	local tActionDiceSkin = DiceRollManager.getDamageActionDiceSkin(tData);
	DiceRollManager.helperAddDice(tTargetDice, tSourceDice, tData, tActionDiceSkin);
end
function getDamageActionDiceSkin(tData)
	local tActionDiceSkin;
	local sMode;
	if tData and tData.dmgtype then
		local tDamageTypes = StringManager.split(tData.dmgtype, ",", true);
		for _,s in ipairs(tDamageTypes) do
			if StringManager.contains(_tDamageModes, s) then
				sMode = s;
				break;
			end
		end
		for _,s in ipairs(tDamageTypes) do
			tActionDiceSkin = DiceRollManager.resolveAction("damage-type-" .. s:gsub("%s", "-"), sMode);
			if tActionDiceSkin then
				break;
			end
		end
	end

	if not tActionDiceSkin then
		tActionDiceSkin = DiceRollManager.resolveAction("damage", sMode);
	end
	return tActionDiceSkin;
end

--
--	HEAL DICE TABLE ADDITIONS
--

function registerHealKey(sDefaultKey)
	DiceRollManager.setAction("heal", { sDefaultKey = sDefaultKey });
end
function registerHealTypeKey(sHealType, sDefaultKey)
	if (sHealType or "") == "" then
		return;
	end
	DiceRollManager.setAction("heal-type-" .. sHealType:gsub("%s", "-"), { sDefaultKey = sDefaultKey });
end

function addHealDice(tTargetDice, tSourceDice, tData)
	local tActionDiceSkin = DiceRollManager.getHealActionDiceSkin(tData);
	DiceRollManager.helperAddDice(tTargetDice, tSourceDice, tData, tActionDiceSkin);
end
function getHealActionDiceSkin(tData)
	local tActionDiceSkin;
	if tData and tData.healtype then
		tActionDiceSkin = DiceRollManager.resolveAction("heal-type-" .. tData.healtype:gsub("%s", "-"));
	end
	if not tActionDiceSkin then
		tActionDiceSkin = DiceRollManager.resolveAction("heal");
	end
	return tActionDiceSkin;
end

--
--	DICE SKIN KEY DEFAULTS
--

local _tDefaultsData = {
	["arcane"] = {
		{ diceskin = 60 }, { diceskin = 70 }, { diceskin = 30 }, { diceskin = 40 },
		{ diceskin = 50 }, { diceskin = 10 }, { diceskin = 20 }, { diceskin = 80 },
		{ diceskin = 94 },
		{ diceskin = 0, dicebodycolor="FF00FF", dicetextcolor="FFFFFF" },
	},
	["earth"] = {
		{ diceskin = 61 }, { diceskin = 71 }, { diceskin = 31 }, { diceskin = 41 },
		{ diceskin = 51 }, { diceskin = 11 }, { diceskin = 21 }, { diceskin = 81 },
		{ diceskin = 95 },
		{ diceskin = 0, dicebodycolor="8B4513", dicetextcolor="FFFFFF" },
	},
	["fire"] = {
		{ diceskin = 62 }, { diceskin = 72 }, { diceskin = 32 }, { diceskin = 42 },
		{ diceskin = 52 }, { diceskin = 12 }, { diceskin = 22 }, { diceskin = 82 },
		{ diceskin = 96 },
		{ diceskin = 0, dicebodycolor="FF0000", dicetextcolor="FFFFFF" },
	},
	["frost"] = {
		{ diceskin = 63 }, { diceskin = 73 }, { diceskin = 33 }, { diceskin = 43 },
		{ diceskin = 53 }, { diceskin = 13 }, { diceskin = 23 }, { diceskin = 83 },
		{ diceskin = 97 },
		{ diceskin = 0, dicebodycolor="00BFFF", dicetextcolor="000000" },
	},
	["life"] = {
		{ diceskin = 64 }, { diceskin = 74 }, { diceskin = 34 }, { diceskin = 44 },
		{ diceskin = 54 }, { diceskin = 14 }, { diceskin = 24 }, { diceskin = 84 },
		{ diceskin = 98 },
		{ diceskin = 0, dicebodycolor="00FF00", dicetextcolor="000000" },
	},
	["light"] = {
		{ diceskin = 65 }, { diceskin = 75 }, { diceskin = 35 }, { diceskin = 45 },
		{ diceskin = 55 }, { diceskin = 15 }, { diceskin = 25 }, { diceskin = 85 },
		{ diceskin = 99 },
		{ diceskin = 0, dicebodycolor="FFFF00", dicetextcolor="0000FF" },
	},
	["lightning"] = {
		{ diceskin = 66 }, { diceskin = 76 }, { diceskin = 36 }, { diceskin = 46 },
		{ diceskin = 56 }, { diceskin = 16 }, { diceskin = 26 }, { diceskin = 86 },
		{ diceskin = 100 },
		{ diceskin = 0, dicebodycolor="FFFF00", dicetextcolor="000000" },
	},
	["shadow"] = {
		{ diceskin = 67 }, { diceskin = 77 }, { diceskin = 37 }, { diceskin = 47 },
		{ diceskin = 57 }, { diceskin = 17 }, { diceskin = 27 }, { diceskin = 87 },
		{ diceskin = 101 },
		{ diceskin = 0, dicebodycolor="4B0082", dicetextcolor="000000" },
	},
	["storm"] = {
		{ diceskin = 68 }, { diceskin = 78 }, { diceskin = 38 }, { diceskin = 48 },
		{ diceskin = 58 }, { diceskin = 18 }, { diceskin = 28 }, { diceskin = 88 },
		{ diceskin = 102 },
		{ diceskin = 0, dicebodycolor="B0C4DE", dicetextcolor="000000" },
	},
	["water"] = {
		{ diceskin = 69 }, { diceskin = 79 }, { diceskin = 39 }, { diceskin = 49 },
		{ diceskin = 59 }, { diceskin = 19 }, { diceskin = 29 }, { diceskin = 89 },
		{ diceskin = 103 },
		{ diceskin = 0, dicebodycolor="0000FF", dicetextcolor="000000" },
	},
};

function getDiceSkinDefaults(sKey)
	if (sKey or "") == "" then
		return nil;
	end
	return _tDefaultsData[sKey];
end
function setDiceSkinDefaults(sKey, tDefaults)
	if (sKey or "") == "" then
		return;
	end
	_tDefaultsData[sKey] = tDefaults;
end
function resolveDiceSkinDefaults(sKey)
	local tDefaults = DiceRollManager.getDiceSkinDefaults(sKey);
	if tDefaults then
		for _,v in ipairs(tDefaults) do
			if DiceSkinManager.isDiceSkinOwned(v) then
				return v;
			end
		end
	end
	return nil;
end

--
--	ACTION DICE SKIN KEY MANAGEMENT
--

local _tActionData = {};
function hasActions()
	return (next(_tActionData) ~= nil);
end
function getActionData()
	return _tActionData;
end
function getAction(sKey)
	if not sKey then
		return nil;
	end
	return _tActionData[sKey];
end
function setAction(sKey, tData)
	if not sKey then
		return;
	end
	_tActionData[sKey] = tData;
end
function getActionDefault(sKey)
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return nil;
	end
	return t.sDefaultKey
end
function setActionDefault(sKey, sDefaultKey)
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return;
	end
	t.sDefaultKey = sDefaultKey;
end
function getActionSkipDefault(sKey)
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return false;
	end
	return t.bSkipDefault;
end
function setActionSkipDefault(sKey, bSkipDefault)
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return;
	end
	t.bSkipDefault = bSkipDefault and true or nil;
end
function getActionSkin(sKey)
	return DiceRollManager.getActionModeSkin(sKey, "");
end
function setActionSkin(sKey, tCustom)
	DiceRollManager.setActionModeSkin(sKey, "", tCustom);
end
function getActionModeSkin(sKey, sMode)
	if not sMode then
		return nil;
	end
	local t = DiceRollManager.getAction(sKey);
	if not t or not t.tModesCustom then
		return nil;
	end
	return t.tModesCustom[sMode];
end
function setActionModeSkin(sKey, sMode, tCustom)
	if not sMode then
		return;
	end
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return;
	end
	if (sMode ~= "") and not StringManager.contains(t.tModesAllowed, sMode) then
		return;
	end
	t.tModesCustom = t.tModesCustom or {};
	t.tModesCustom[sMode] = tCustom;
end
function getActionAllowedModes(sKey)
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return nil;
	end
	return t.tModesAllowed;
end

function resolveAction(sKey, sMode)
	local t = DiceRollManager.getAction(sKey);
	if not t then
		return nil;
	end

	local tCustom = t.tModesCustom;
	if tCustom then
		if sMode and tCustom[sMode] then
			return tCustom[sMode];
		end
		if tCustom[""] then
			return tCustom[""];
		end
	end
	if not t.bSkipDefault and t.sDefaultKey then
		return DiceRollManager.resolveDiceSkinDefaults(t.sDefaultKey);
	end
	return nil;
end
function resolveActionDefault(sKey)
	local t = DiceRollManager.getAction(sKey);
	if t and t.sDefaultKey then
		return DiceRollManager.resolveDiceSkinDefaults(t.sDefaultKey);
	end
	return nil;
end

--
--	ACTOR DICE TABLE ADDITIONS
--

function getActorDice(tSourceDice, rActor, tData)
	local t = {};
	DiceRollManager.addActorDice(t, tSourceDice, rActor, tData);
	return t;
end
function getActorDiceFromExpr(sExpr, rActor, tData)
	local tDice = Utility.convertStringToDice(sExpr);
	DiceRollManager.applyActorDice(tDice, rActor, tData);
	return tDice;
end
function addActorDice(tTargetDice, tSourceDice, rActor, tData)
	local t = DiceRollManager.getActorDiceSkin(rActor);
	DiceRollManager.helperAddDice(tTargetDice, tSourceDice, tData, t);
end
function applyActorDice(tDice, rActor, tData)
	if not tDice then
		return;
	end
	local t = DiceRollManager.getActorDiceSkin(rActor);
	for k, v in ipairs(tDice) do
		if type(v) == "table" then
			DiceRollManager.helperModDie(v, tData, t);
		else
			tDice[k] = DiceRollManager.helperBuildDie(tostring(v) or "", tData, t);
		end
	end
end
function getActorDiceSkin(rActor)
	if not rActor then
		return nil;
	end
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end

	-- Check to see if actor has custom die specified
	local tDiceSkin = DiceSkinManager.convertStringToTable(DB.getValue(nodeActor, "customdie", ""));
	if tDiceSkin then
		return tDiceSkin;
	end

	if ActorManager.getRecordType(rActor) == "npc" then
		local sName = DB.getValue(nodeActor, "name", "");

		-- Check custom NPC name rules
		tDiceSkin = DiceRollManager.resolveActorCustom(sName);
		if tDiceSkin then
			return tDiceSkin;
		end

		-- Check built-in NPC name rules
		tDiceSkin = DiceRollManager.resolveActorSystem(sName);
		if tDiceSkin then
			return tDiceSkin;
		end

		-- Check creature type
		local fn = DiceRollManager.getActorTypeFunction();
		if fn then
			local sType = fn(rActor);
			tDiceSkin = DiceRollManager.resolveActorType(sType);
			if tDiceSkin then
				return tDiceSkin;
			end
		end
	end

	return nil;
end

local _fnGetType;
function setActorTypeFunction(fn)
	_fnGetType = fn;
end
function getActorTypeFunction()
	return _fnGetType;
end

--
--	ACTOR DICE SKIN KEY MANAGEMENT
--

function registerActorSupportDnD()
	DiceRollManager.registerStandardActorTypeData();
	DiceRollManager.setActorTypeFunction(ActorCommonManager.getCreatureTypeDnD);
end
function registerStandardActorTypeData()
	for _,sKey in ipairs(DataCommon and DataCommon.creaturetype or {}) do
		DiceRollManager.setActorType(sKey, { sDefaultKey = sKey });
	end
end

local _tActorTypeData = {};
function getActorTypeData()
	return _tActorTypeData;
end
function getActorType(sKey)
	if (sKey or "") == "" then
		return nil;
	end
	return _tActorTypeData[sKey];
end
function setActorType(sKey, tData)
	if (sKey or "") == "" then
		return;
	end
	_tActorTypeData[sKey] = tData;
end
function getActorTypeDefault(sKey)
	local t = DiceRollManager.getActorType(sKey);
	if not t then
		return "";
	end
	return t.sDefaultKey or "";
end
function getActorTypeSkipDefault(sKey)
	local t = DiceRollManager.getActorType(sKey);
	if not t then
		return false;
	end
	return t.bSkipDefault;
end
function setActorTypeSkipDefault(sKey, bSkipDefault)
	local t = DiceRollManager.getActorType(sKey);
	if not t then
		return;
	end
	t.bSkipDefault = bSkipDefault and true or nil;
end
function getActorTypeSkin(sKey)
	local t = DiceRollManager.getActorType(sKey);
	if not t then
		return nil;
	end
	return t.tCustom;
end
function setActorTypeSkin(sKey, tData)
	local t = DiceRollManager.getActorType(sKey);
	if not t then
		return;
	end
	t.tCustom = tData;
end
function getActorTypeDefaultSkin(sKey)
	return DiceRollManager.resolveDiceSkinDefaults(DiceRollManager.getActorTypeDefault(sKey));
end
function resolveActorType(sKey)
	local t = DiceRollManager.getActorTypeSkin(sKey);
	if t then
		return t;
	end
	return DiceRollManager.resolveActorTypeDefault(sKey);
end
function resolveActorTypeDefault(sKey)
	if DiceRollManager.getActorTypeSkipDefault(sKey) then
		return nil;
	end
	return DiceRollManager.getActorTypeDefaultSkin(sKey);
end

local _tActorSystemData = {};
function getActorSystemData()
	return _tActorSystemData;
end
function getActorSystem(sKey)
	if (sKey or "") == "" then
		return;
	end
	return _tActorSystemData[sKey];
end
function setActorSystem(sKey, tData)
	if (sKey or "") == "" then
		return;
	end
	_tActorSystemData[sKey] = tData;
end
function getActorSystemDefault(sKey)
	local t = DiceRollManager.getActorSystem(sKey);
	if not t then
		return "";
	end
	return t.sDefaultKey or "";
end
function getActorSystemSkipDefault(sKey)
	local t = DiceRollManager.getActorSystem(sKey);
	if not t then
		return false;
	end
	return t.bSkipDefault;
end
function setActorSystemSkipDefault(sKey, bSkipDefault)
	local t = DiceRollManager.getActorSystem(sKey);
	if not t then
		return;
	end
	t.bSkipDefault = bSkipDefault and true or nil;
end
function getActorSystemDefaultSkin(sKey)
	return DiceRollManager.resolveDiceSkinDefaults(DiceRollManager.getActorSystemDefault(sKey));
end
function getActorSystemSkin(sKey)
	local v = DiceRollManager.getActorSystem(sKey);
	if v then
		return v.tCustom;
	end
	return nil;
end
function setActorSystemSkin(sKey, tData)
	local t = DiceRollManager.getActorSystem(sKey);
	if not t then
		return;
	end
	t.tCustom = tData;
end
function resolveActorSystem(sKey)
	if not sKey then
		return nil;
	end
	local sStripKey = CombatManager.stripCreatureNumber(sKey);
	local sKeyLower = sStripKey:lower();
	for sDataKey,v in pairs(DiceRollManager.getActorSystemData()) do
		local tSplit = StringManager.splitByPattern((v.sName or ""):lower(), "|", true);
		for _,s in ipairs(tSplit) do
			if sKeyLower == s then
				local t = DiceRollManager.getActorSystemSkin(sDataKey);
				if t then
					return t;
				end
				if DiceRollManager.getActorSystemSkipDefault(sDataKey) then
					return nil;
				end
				return DiceRollManager.getActorSystemDefaultSkin(sDataKey);
			end
		end
	end
	return nil;
end

local _tActorCustomData = {};
function getActorCustomData()
	return _tActorCustomData;
end
function getActorCustom(sKey)
	return _tActorCustomData[sKey];
end
function setActorCustom(sKey, tData)
	if (sKey or "") == "" then
		return;
	end
	_tActorCustomData[sKey] = tData;
end
function addActorCustom(sKey)
	local sStripKey = CombatManager.stripCreatureNumber(sKey);
	local v = DiceRollManager.getActorCustom(sStripKey);
	if v then
		return nil;
	end
	_tActorCustomData[sStripKey] = {};
	return sStripKey;
end
function getActorCustomSkin(sKey)
	local sStripKey = CombatManager.stripCreatureNumber(sKey);
	local v = DiceRollManager.getActorCustom(sStripKey);
	if v then
		return v.tCustom;
	end
	return nil;
end
function setActorCustomSkin(sKey, tCustom)
	local v = DiceRollManager.getActorCustom(sKey);
	if v then
		v.tCustom = tCustom;
		return true;
	end
	return false;
end
function resolveActorCustom(sKey)
	if not sKey then
		return nil;
	end
	local sStripKey = CombatManager.stripCreatureNumber(sKey);
	local sKeyLower = sStripKey:lower();
	for k,v in pairs(DiceRollManager.getActorCustomData()) do
		if sKeyLower == k:lower() then
			return v.tCustom;
		end
	end
	for k,v in pairs(DiceRollManager.getActorCustomData()) do
		if StringManager.startsWith(sKeyLower, k:lower() .. " ") then
			return v.tCustom;
		end
	end
	return nil;
end

--
--	DEPRECATED (2024-10)
--

function setDiceSkinKey(sKey, v)
	DiceRollManager.setAction(sKey, v);
end
function resolveDiceSkinKey(sKey)
	return DiceRollManager.resolveAction(sKey);
end
