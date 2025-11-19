--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	if Session.IsHost and ImageDeathMarkerManager.isEnabled() then
		CombatManager.setCustomPreDeleteCombatantHandler(ImageDeathMarkerManager.onPreCombatantDelete);
		DB.addHandler("settings.imagedeathmarkerset.*.name", "onUpdate", ImageDeathMarkerManager.onSetNameUpdate);
		DB.addHandler("settings.imagedeathmarkerset", "onChildDeleted", ImageDeathMarkerManager.onSetDelete);

		ImageDeathMarkerData.registerDefaultSets();
		ImageDeathMarkerManager.loadSettings();
		OptionsManager.registerButton("option_label_imagedeathmarker", "imagedeathmarkerlist", "settings.imagedeathmarker");
	end
end
function onTabletopClose()
	if Session.IsHost and ImageDeathMarkerManager.isEnabled() then
		ImageDeathMarkerManager.saveSettings();
	end
end

local _bEnabled = false;
function isEnabled()
	return _bEnabled;
end
function setEnabled(bValue)
	_bEnabled = bValue;
end

function onPreCombatantDelete(nodeCT)
	if ActorHealthManager.isDyingOrDead(nodeCT) then
		ImageDeathMarkerManager.addMarker(nodeCT);
	end
end
function onSetNameUpdate()
	ImageDeathMarkerManager.refreshSetOptionsInCreatureTypesWindow();
end
function onSetDelete()
	ImageDeathMarkerManager.refreshSetOptionsInCreatureTypesWindow();
end
function refreshSetOptionsInCreatureTypesWindow()
	local w = Interface.findWindow("imagedeathmarkerlist", "settings.imagedeathmarker");
	if not w then
		return;
	end
	for _,wChild in ipairs(w.list.getWindows()) do
		wChild.updateSetOptions(true);
	end
end

--
--	REGISTRATIONS
--

function registerStandardDeathMarkersDnD()
	ImageDeathMarkerManager.setEnabled(true);

	ImageDeathMarkerManager.registerGetCreatureTypeFunction(ActorCommonManager.getCreatureTypeDnD);

	ImageDeathMarkerManager.registerCreatureTypes(DataCommon and DataCommon.creaturetype);
	ImageDeathMarkerManager.setCreatureTypeDefault("construct", "blood_black");
	ImageDeathMarkerManager.setCreatureTypeDefault("plant", "blood_green");
	ImageDeathMarkerManager.setCreatureTypeDefault("undead", "blood_violet");
end

-- Set Resolution
function getSetNames()
	-- Include empty string as "default" entry
	local tSetNames = {};
	table.insert(tSetNames, "");
	for _,nodeSet in ipairs(DB.getChildList("settings.imagedeathmarkerset")) do
		table.insert(tSetNames, DB.getValue(nodeSet, "name", ""));
	end
	return tSetNames;
end
function getSetMap()
	local tSetMap = { };
	for _,nodeSet in ipairs(DB.getChildList("settings.imagedeathmarkerset")) do
		local sName = DB.getValue(nodeSet, "name", "");
		local tSetData = {};
		for _,nodeAsset in ipairs(DB.getChildList(nodeSet, "assets")) do
			local sAsset = DB.getValue(nodeAsset, "value", "");
			if sAsset ~= "" then
				table.insert(tSetData, sAsset);
			end
		end
		local sTint = DB.getValue(nodeSet, "tint", "");
		if (sTint ~= "") then
			tSetData.tint = sTint;
		end
		tSetMap[sName] = tSetData;
	end
	return tSetMap;
end

-- Creature Type Resolution
local _fnGetCreatureType = nil;
function registerGetCreatureTypeFunction(f)
	_fnGetCreatureType = f;
end
function getCreatureType(nodeCT)
	if _fnGetCreatureType then
		return _fnGetCreatureType(nodeCT) or "";
	end
	return "";
end
function getCreatureTypeMap()
	local tCreatureTypeMap = { };
	for _,v in ipairs(DB.getChildList("settings.imagedeathmarker")) do
		local sID = DB.getValue(v, "id", "");
		tCreatureTypeMap[sID] = DB.getValue(v, "set", "");
	end
	return tCreatureTypeMap;
end

-- Default Creature Type Mapping (Ruleset)
local _tCreatureTypeDefaultMap = {};
function registerCreatureTypes(tCreatureTypes)
	if not tCreatureTypes then
		return;
	end
	for _,v in ipairs(tCreatureTypes) do
		_tCreatureTypeDefaultMap[v] = "";
	end
end
function setCreatureTypeDefault(sCreatureType, sDefaultSetKey)
	if not sCreatureType then
		return;
	end
	local sResolvedSetKey = ImageDeathMarkerManager.resolveDefaultSetName(sDefaultSetKey);
	_tCreatureTypeDefaultMap[sCreatureType] = sResolvedSetKey;
end
function getCreatureTypeSetDefaultMap()
	return _tCreatureTypeDefaultMap;
end

-- Default Sets (Global)
local _tDefaultSetMap = {};
function registerDefaultSet(sKey, tAssets)
	local sResolvedKey = ImageDeathMarkerManager.resolveDefaultSetName(sKey);
	_tDefaultSetMap[sResolvedKey] = tAssets;
end
function getDefaultSetMap()
	return _tDefaultSetMap;
end
function resolveDefaultSetName(sKey)
	if (sKey or "") == "" then
		return "";
	end
	local sResolvedKey = Interface.getString("imagedeathmarkerset_default_" .. sKey);
	if (sResolvedKey or "") == "" then
		return sKey;
	end
	return sResolvedKey;
end

--
--	LOAD/SAVE
--
--	NOTE: Settings information is stored in the global registry,
--		but loaded into the database for ease of access during play
--

function loadSettings()
	-- Remove any left over database info
	DB.deleteNode("settings.imagedeathmarkerset");
	DB.deleteNode("settings.imagedeathmarker");

	-- Create a fresh database location
	DB.createNode("settings.imagedeathmarkerset");
	DB.createNode("settings.imagedeathmarker");

	-- Load asset sets (if defined), or add defaults (once ever)
	local bHasSet = false;
	local tSetMap = {};
	if GlobalRegistry and GlobalRegistry.imagedeathmarkersets then
		for k,v in pairs(GlobalRegistry.imagedeathmarkersets) do
			tSetMap[k] = v;
			bHasSet = true;
		end
	end
	if not bHasSet then
		for k,v in pairs(ImageDeathMarkerManager.getDefaultSetMap()) do
			tSetMap[k] = v;
		end
	end
	for kSet,vSetData in pairs(tSetMap) do
		local nodeSet = DB.createChild("settings.imagedeathmarkerset");
		DB.setValue(nodeSet, "name", "string", kSet);
		if vSetData.tint then
			DB.setValue(nodeSet, "tint", "string", vSetData.tint);
		end
		local sAssetsPath = DB.getPath(nodeSet, "assets");
		for _,sAsset in ipairs(vSetData) do
			local nodeAsset = DB.createChild(sAssetsPath);
			DB.setValue(nodeAsset, "value", "string", sAsset);
		end
	end

	-- Load per ruleset creature type maps (if defined), or get defaults (from ruleset)
	local tCreatureTypeMap = {};
	if GlobalRegistry and GlobalRegistry.imagedeathmarkers and GlobalRegistry.imagedeathmarkers[Session.RulesetName] then
		for k,v in pairs(GlobalRegistry.imagedeathmarkers[Session.RulesetName]) do
			tCreatureTypeMap[k] = v;
		end
	end
	for k,v in pairs(ImageDeathMarkerManager.getCreatureTypeSetDefaultMap()) do
		if not tCreatureTypeMap[k] then
			tCreatureTypeMap[k] = v;
		end
	end
	for kCreatureType,sCreatureTypeSet in pairs(tCreatureTypeMap) do
		local nodeMap = DB.createChild("settings.imagedeathmarker");
		DB.setValue(nodeMap, "id", "string", kCreatureType);
		DB.setValue(nodeMap, "set", "string", sCreatureTypeSet);
	end
end
function saveSettings()
	if GlobalRegistry then
		-- Save asset set settings
		GlobalRegistry.imagedeathmarkersets = ImageDeathMarkerManager.getSetMap();

		-- Save per ruleset creature map settings
		if not GlobalRegistry.imagedeathmarkers then
			GlobalRegistry.imagedeathmarkers = {};
		end
		GlobalRegistry.imagedeathmarkers[Session.RulesetName] = ImageDeathMarkerManager.getCreatureTypeMap();
	end

	-- Remove database info
	DB.deleteNode("settings.imagedeathmarkerset");
	DB.deleteNode("settings.imagedeathmarker");
end

--
--	BEHAVIORS
--

function addMarker(nodeCT)
	if not nodeCT then
		return;
	end

	local token = CombatManager.getTokenFromCT(nodeCT);
	if not token then
		return;
	end

	local sAsset, sTint = ImageDeathMarkerManager.resolveMarker(nodeCT);
	if (sAsset or "") == "" then
		return;
	end
	if (sTint or "") == "" then
		sTint = "FFFFFFFF";
	end

	local sPath = DB.getPath(token.getContainerNode());
	local nLayerID = ImageDeathMarkerManager.getMarkerLayer(sPath, true);

	local x,y = token.getPosition();
	local nGridScaleX, nGridScaleY = token.getScale();
	Image.addLayerPaintStamp(sPath, nLayerID, { asset=sAsset, w=nGridScaleX, h=nGridScaleY or nGridScaleX, x=x, y=y, color=sTint });
end
function clearMarkers(nodeRecord)
	if not Session.IsHost then
		return;
	end

	local sPath = DB.getPath(nodeRecord, "image");
	local nLayerID = ImageDeathMarkerManager.getMarkerLayer(sPath);
	if nLayerID then
		Image.deleteLayer(sPath, nLayerID);
	end
end

function resolveMarker(nodeCT)
	local sType = ImageDeathMarkerManager.getCreatureType(nodeCT);
	local tCreatureTypeMap = ImageDeathMarkerManager.getCreatureTypeMap();

	local sSet = nil;
	if (sType or "") ~= "" then
		sSet = tCreatureTypeMap[sType];
	end
	if (sSet or "") == "" then
		sSet = tCreatureTypeMap[""];
	end
	if (sSet or "") == "" then
		return;
	end

	local tSets = ImageDeathMarkerManager.getSetMap();
	local tSet = tSets[sSet];
	if not tSet then
		tSet = tSets[""];
	end
	if not tSet then
		return "", nil;
	end

	return tSet[math.random(1, #tSet)], tSet.tint;
end
function getMarkerLayer(sPath, bCreate)
	local sLayer = Interface.getString("image_layer_deathmarkers");
	local nLayerID = Image.getLayerByName(sPath, sLayer);
	if not nLayerID and bCreate then
		nLayerID = Image.addLayer(sPath, "paint", { name = sLayer });
	end
	return nLayerID;
end
