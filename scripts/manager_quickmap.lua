--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

FILL_SIZE_SMALL = 15;
FILL_SIZE_STANDARD = 27;
FILL_SIZE_LARGE = 51;

ZONE_PADDING = 5;
ZONE_SIZE = 40;

DEFAULT_ENEMY_ZONE = 2;
DEFAULT_PARTY_ZONE = 8;

--
--	WINDOW UI
--

function openWindow()
	return Interface.openWindow("quickmap", "");
end
function openWindowWithAsset(sAsset)
	local w = QuickMapManager.openWindow();
	if (sAsset or "") ~= "" then
		QuickMapManager.setAsset(w, sAsset);
	end
end
function openWindowWithBattle(sPath)
	local w = QuickMapManager.openWindow();
	QuickMapManager.setBattle(w, sPath);
end

function populate(w)
	QuickMapManager.createGrid(w, true);
	QuickMapManager.createGrid(w);
	QuickMapManager.updatePartyZones(w);
	QuickMapManager.toggleEnemyZone(w, QuickMapManager.DEFAULT_ENEMY_ZONE);
end
-- Zone Numbers: nw = 1, n = 2, ne = 3, w = 4, c = 5, e = 6, sw = 7, s = 8, se = 9
function createGrid(w, bParty)
	if not w then
		return;
	end

	local wSub;
	if bParty then
		wSub = w.sub_party.subwindow;
	else
		wSub = w.sub_enemy.subwindow;
	end

	local nLeftCenterOffset = -(QuickMapManager.ZONE_SIZE + QuickMapManager.ZONE_PADDING + (QuickMapManager.ZONE_SIZE / 2));
	local nTopOffset = QuickMapManager.ZONE_PADDING;
	local nZoneAdvance = (QuickMapManager.ZONE_SIZE + QuickMapManager.ZONE_PADDING);
	local i = 1;
	for y = 1, 3 do
		for x = 1, 3 do
			local sZone = string.format("zone_%d", i);
			local cZone;
			if bParty then
				cZone = wSub.createControl("quickmap_formation_party_zone", sZone);
				cZone.setColor(ColorManager.getButtonIconColor());
			else
				cZone = wSub.createControl("quickmap_formation_enemy_zone", sZone);
			end

			cZone.setAnchor("top", "contentanchor", "bottom", "current", nTopOffset + ((y - 1) * nZoneAdvance));
			cZone.setAnchor("left", "contentanchor", "center", "absolute", nLeftCenterOffset + ((x - 1) * nZoneAdvance));
			cZone.setAnchoredWidth(QuickMapManager.ZONE_SIZE);
			cZone.setAnchoredHeight(QuickMapManager.ZONE_SIZE);

			i = i + 1;
		end
	end
end
function updatePartyZones(w, nPos)
	if not w then
		return;
	end

	local wParty = w.sub_party.subwindow;
	local i = 1;
	for _ = 1, 3 do
		for _ = 1, 3 do
			local sZone = string.format("zone_%d", i);
			if i == (nPos or QuickMapManager.DEFAULT_PARTY_ZONE) then
				wParty[sZone].setValue(1);
			else
				wParty[sZone].setValue(0);
			end
			i = i + 1;
		end
	end

	QuickMapManager.updateEnemyZones(w);
end
function updateEnemyZones(w)
	if not w then
		return
	end

	local tData = {};
	QuickMapManager.collectPartyLoc(w, tData);

	local wEnemy = w.sub_enemy.subwindow;
	local i = 1;
	for _ = 1, 3 do
		for _ = 1, 3 do
			local sZone = string.format("zone_%d", i);
			local cZone = wEnemy[sZone];
			local bParty = (tData.nParty == i);
			if bParty then
				cZone.setColor(ColorManager.getButtonIconColor());
				cZone.setValue(0);
				cZone.setStateIcons(0, "crossed");
			else
				cZone.setColor(ColorManager.getButtonIconColor());
				cZone.setStateIcons(0, "");
			end

			i = i + 1;
		end
	end
end
function getZoneNumber(c)
	return tonumber(c.getName():match("%d+")) or 5;
end
function toggleEnemyZone(w, n)
	local tData = {};
	QuickMapManager.collectPartyLoc(w, tData);
	if n == tData.nParty then
		return;
	end

	local sZone = string.format("zone_%d", n);
	local cZone = w.sub_enemy.subwindow[sZone];
	local nValue = cZone.getValue();
	if nValue > 0 then
		cZone.setValue(0);
	else
		local tData = {};
		QuickMapManager.collectEnemyLoc(w, tData);

		local tValueSet = {};
		for _,v in ipairs(tData.tEnemyLoc) do
			tValueSet[v.priority] = true;
		end
		for i = 1,8 do
			if not tValueSet[i] then
				cZone.setValue(i);
				break;
			end
		end
	end
	QuickMapManager.updateEnemyZones(w);
end

function handleDrop(w, draginfo)
	if not w or not draginfo then
		return;
	end
	if not draginfo.isType("shortcut") then
		return false;
	end
	local sClass, sPath = draginfo.getShortcutData();
	local sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
	if sRecordType == "battle" then
		return QuickMapManager.setBattle(w, sPath);
	elseif sRecordType == "image" then
		local sAsset = DB.getText(DB.getPath(sPath, "image"), "");
		return QuickMapManager.setAsset(w, sAsset);
	end
	return false;
end
function onAssetClick()
	Interface.openWindow("tokenbag", "");
end
function onBattleClick()
	RecordManager.openRecordIndex("battle");
end
function onPartyZoneClick(cZone)
	if not cZone then
		return;
	end
	QuickMapManager.updatePartyZones(WindowManager.getTopWindow(cZone.window), QuickMapManager.getZoneNumber(cZone));
end
function onEnemyZoneClick(cZone)
	if not cZone then
		return;
	end
	QuickMapManager.toggleEnemyZone(WindowManager.getTopWindow(cZone.window), QuickMapManager.getZoneNumber(cZone));
end
function onSubmitClick(w)
	QuickMapManager.buildQuickMap(w);
end

--
--	DATA
--

function setAsset(w, sAsset)
	if not w then
		return false;
	end
	w.sub_asset.subwindow.asset.setValue(sAsset);
	return true;
end
function setBattle(w, sPath)
	if not w then
		return false;
	end
	w.sub_battle.subwindow.battle_path.setValue(sPath);
	return true;
end

function collectAsset(w, tData)
	tData.tAsset = {};
	tData.tAsset.sAsset = "";

	if not w then
		return;
	end
	local sAsset = w.sub_asset.subwindow.asset.getValue();
	if (sAsset or "") == "" then
		return;
	end
	tData.tAsset.nAssetSizeW, tData.tAsset.nAssetSizeH = Interface.getAssetSize(sAsset);
	if (tData.tAsset.nAssetSizeW == 0) or (tData.tAsset.nAssetSizeH == 0) then
		return;
	end

	tData.tAsset.sAsset = sAsset;
	tData.tAsset.nAssetGridW, tData.tAsset.nAssetGridH = Interface.getAssetGridSize(tData.tAsset.sAsset);

	tData.tAsset.bAssetFill = (w.sub_asset.subwindow.button_fill.getValue() == 1);
	if tData.tAsset.bAssetFill then
		local nSize = QuickMapManager.FILL_SIZE_STANDARD;
		for _,v in ipairs({ "small", "large" }) do
			if w.sub_asset.subwindow["button_size_" .. v].getValue() == 1 then
				nSize = QuickMapManager["FILL_SIZE_" .. v:upper()];
				break
			end
		end
		tData.tAsset.nFillGridUnitsW = nSize;
		tData.tAsset.nFillGridUnitsH = nSize;
	end
end
function collectBattle(w, tData)
	tData.sBattle = "";

	if not w then
		return;
	end

	tData.sBattle = w.sub_battle.subwindow.battle_path.getValue();
end
function collectPartyLoc(w, tData)
	tData.nParty = QuickMapManager.DEFAULT_PARTY_ZONE;

	if not w then
		return;
	end

	local wParty = w.sub_party.subwindow;
	local i = 1;
	for _ = 1, 3 do
		for _ = 1, 3 do
			local sZone = string.format("zone_%d", i);
			if wParty[sZone].getValue() > 0 then
				tData.nParty = i;
				return;
			end
			i = i + 1;
		end
	end
end
function collectEnemyLoc(w, tData)
	tData.tEnemyLoc = {};

	if not w then
		return
	end

	local wEnemy = w.sub_enemy.subwindow;
	for i = 1, 9 do
		local sZone = string.format("zone_%d", i);
		local nValue = wEnemy[sZone].getValue();
		if nValue > 0 then
			table.insert(tData.tEnemyLoc, { zone = i, priority = nValue });
		end
	end
end

--
--	BUILD
--

function buildQuickMap(w)
	local tData = {};

	QuickMapManager.collectAsset(w, tData)
	if (tData.tAsset.sAsset or "") == "" then
		ChatManager.SystemMessage(Interface.getString("quickmap_error_missingasset"));
		return;
	end
	QuickMapManager.collectBattle(w, tData)
	QuickMapManager.collectPartyLoc(w, tData);
	QuickMapManager.collectEnemyLoc(w, tData);
	QuickMapManager.addBattle(tData);
	QuickMapManager.getFactionRecords(tData);

	QuickMapManager.createImageRecord(tData);
	QuickMapManager.calculateZones(tData);
	QuickMapManager.addPartyToImage(tData);
	QuickMapManager.addEnemyToImage(tData);
	QuickMapManager.openImageRecord(tData);

	w.close();
end
function addBattle(tData)
	if (tData.sBattle or "") ~= "" then
		CombatRecordManager.onRecordTypeEvent("battle", { sRecordType = "battle", nodeRecord = DB.findNode(tData.sBattle), });
	end
end
function getFactionRecords(tData)
	tData.tParty = {};
	tData.tEnemy = {};

	-- Combat Tracker Actors
	local tPartyFormation = PartyFormationManager.getFormation();
	for _,nodeActor in pairs(CombatManager.getCombatantNodes()) do
		local sFaction = CombatManager.getFactionFromCT(nodeActor);
		local sClass, sRecord = DB.getValue(nodeActor, "link", "", "");
		local tActorData = { sClass = sClass, sRecord = sRecord };
		if sFaction == "foe" then
			tActorData.sRecord = DB.getPath(nodeActor);
			table.insert(tData.tEnemy, tActorData);
		else
			if not ActorManager.isPC(nodeActor) then
				tActorData.sClass = "ct";
				tActorData.sRecord = DB.getPath(nodeActor);
			end
			if tPartyFormation[sRecord] then
				tActorData.tSlotPos = tPartyFormation[sRecord];
			end
			table.insert(tData.tParty, tActorData);
		end
	end

	-- Fill Non-Group Members
	CombatFormationManager.fillFactionFormationSlots("friend", tData.tParty, "");
end
function createImageRecord(tData)
	tData.tImage = {};
	tData.tImage.nodeRecord = DB.createChild(RecordDataManager.getDataPathRoot("image"));
	if tData.tAsset.bAssetFill then
		QuickMapManager.createFillImage(tData);
	else
		QuickMapManager.createFullImage(tData);
	end
	DB.setValue(tData.tImage.nodeRecord, "name", "string", QuickMapManager.getUniqueMapName());
	tData.tImage.nImageW, tData.tImage.nImageH = Image.getSize(tData.tImage.nodeImage);
end
function createFillImage(tData)
	tData.tImage.nodeImage = DB.createChild(tData.tImage.nodeRecord, "image", "image");

	tData.tImage.nImageGridW, tData.tImage.nImageGridH = Image.getGridSize(tData.tImage.nodeImage);
	tData.tImage.nGridOffsetX, tData.tImage.nGridOffsetY = Image.getGridOffset(tData.tImage.nodeImage);

	local tLayer = {
		name = "Base",
	};
	local nLayerID = Image.addLayer(tData.tImage.nodeImage, "paint", tLayer);

	local tStroke = {
		fill = {
			asset = tData.tAsset.sAsset,
			w = tData.tAsset.nAssetSizeW / tData.tAsset.nAssetGridW,
			h = tData.tAsset.nAssetSizeH / tData.tAsset.nAssetGridH,
		},
		path = {
			{ x = 0, y = 0 },
			{ x = tData.tAsset.nFillGridUnitsW * tData.tImage.nImageGridW, y = 0 },
			{ x = tData.tAsset.nFillGridUnitsH * tData.tImage.nImageGridW, y = tData.tAsset.nFillGridUnitsH * tData.tImage.nImageGridH },
			{ x = 0, y = tData.tAsset.nFillGridUnitsH * tData.tImage.nImageGridW },
		},
	};
	Image.addLayerPaintStroke(tData.tImage.nodeImage, nLayerID, tStroke);
end
function createFullImage(tData)
	tData.tImage.nodeImage = DB.createChild(tData.tImage.nodeRecord, "image", "image");
	Image.setGridSize(tData.tImage.nodeImage, tData.tAsset.nAssetGridW, tData.tAsset.nAssetGridH);

	tData.tImage.nImageGridW, tData.tImage.nImageGridH = Image.getGridSize(tData.tImage.nodeImage);
	tData.tImage.nGridOffsetX, tData.tImage.nGridOffsetY = Image.getGridOffset(tData.tImage.nodeImage);

	local tLayer = {
		name = "Base",
		asset = tData.tAsset.sAsset,
		x = (tData.tAsset.nAssetSizeW / 2),
		y = (tData.tAsset.nAssetSizeH / 2),
	};
	Image.addLayer(tData.tImage.nodeImage, "image", tLayer);
end
function getUniqueMapName()
	local nNameHigh = 0
	local aMatchesWithNumber = {};
	local aMatchesToNumber = {};
	local sNameLocal = Interface.getString("quickmap_window_title");
	local tMappings = RecordDataManager.getDataPaths("image");
	for _,sMapping in ipairs(tMappings) do
		for _,vNode in ipairs(DB.getChildrenGlobal(sMapping)) do
			local sEntryName = DB.getValue(vNode, "name", "");
			local sTemp, sNumber = CombatManager.stripCreatureNumber(sEntryName);
			if sTemp == sNameLocal then
				local nNumber = tonumber(sNumber) or 0;
				if nNumber > 0 then
					nNameHigh = math.max(nNameHigh, nNumber);
					table.insert(aMatchesWithNumber, vNode);
				else
					table.insert(aMatchesToNumber, vNode);
				end
			end
		end
	end

	local nNameCount = #aMatchesWithNumber + #aMatchesToNumber;
	for _,v in ipairs(aMatchesToNumber) do
		local sEntryName = DB.getValue(v, "name", "");
		nNameHigh = nNameHigh + 1;
		DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
	end

	if nNameCount > 0 then
		nNameHigh = nNameHigh + 1;
		sNameLocal = sNameLocal .. " " .. nNameHigh;
	end

	return sNameLocal;
end
-- Calculates topleft to topright by rows into grid zones
function calculateZones(tData)
	local nImageW = tData.tImage.nImageW;
	local nImageH = tData.tImage.nImageH;
	local nImageSixthX = (nImageW * 0.166);
	local nImageSixthY = (nImageH * 0.166);
	local nImageHalfX = (nImageW * 0.5);
	local nImageHalfY = (nImageH * 0.5);

	tData.tZones = {};
	-- Top Left
	local nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, nImageSixthX, nImageSixthY);
	tData.tZones[1] = { x = nZoneX, y = nZoneY };

	-- Top Center
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, nImageHalfX, nImageSixthY);
	tData.tZones[2] = { x = nZoneX, y = nZoneY };

	-- Top Right
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, (nImageW - nImageSixthX), nImageSixthY);
	tData.tZones[3] = { x = nZoneX, y = nZoneY };

	-- Left
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, nImageSixthX, nImageHalfY);
	tData.tZones[4] = { x = nZoneX, y = nZoneY };

	-- Center
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, nImageHalfX, nImageHalfY);
	tData.tZones[5] = { x = nZoneX, y = nZoneY };

	-- Right
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, (nImageW - nImageSixthX), nImageHalfY);
	tData.tZones[6] = { x = nZoneX, y = nZoneY };

	-- Bottom Left
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, nImageSixthX, (nImageH - nImageSixthY));
	tData.tZones[7] = { x = nZoneX, y = nZoneY };

	-- Bottom Center
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, nImageHalfX, (nImageH - nImageSixthY));
	tData.tZones[8] = { x = nZoneX, y = nZoneY };

	-- Bottom Right
	nZoneX,nZoneY = QuickMapManager.snapZoneToGridCenter(tData, (nImageW - nImageSixthX), (nImageH - nImageSixthY));
	tData.tZones[9] = { x = nZoneX, y = nZoneY };
end
function snapZoneToGridCenter(tData, x, y)
	local nX = (math.floor((x - tData.tImage.nGridOffsetX) / tData.tImage.nImageGridW) * tData.tImage.nImageGridW) + tData.tImage.nGridOffsetX + (tData.tImage.nImageGridW / 2);
	local nY = (math.floor((y - tData.tImage.nGridOffsetY) / tData.tImage.nImageGridH) * tData.tImage.nImageGridH) + tData.tImage.nGridOffsetY + (tData.tImage.nImageGridH / 2);
	return nX, nY;
end
function addPartyToImage(tData)
	-- Add Party
	local nodeImage = tData.tImage.nodeImage;
	local nPartyZone = tData.nParty;
	local tZone = tData.tZones[nPartyZone];

	-- Calculate Facing
	local nPartyColumn = ((nPartyZone - 1) % 3) + 1;
	local nPartyRow = math.floor((nPartyZone - 1) * .333) + 1;
	local nPartyFacing = 0;
	if nPartyColumn == 1 then
		nPartyFacing = 1;
	elseif nPartyColumn == 3 then
		nPartyFacing = 3;
	else
		if nPartyRow == 1 then
			nPartyFacing = 2;
		end
	end

	-- Figure out rotation
	local nCurrentFacing = PartyFormationManager.getFormationFacing();
	if nCurrentFacing ~= nPartyFacing then
		local nRotation = nCurrentFacing - nPartyFacing;
		local bRight = false;
		if nRotation < 0 then
			nRotation = nRotation * -1;
			bRight = true;
		end

		for _ = 1, nRotation do
			for _,v in ipairs(tData.tParty) do
				if bRight then
					v.tSlotPos = { x = v.tSlotPos.y, y = -v.tSlotPos.x };
				else
					v.tSlotPos = { x = -v.tSlotPos.y, y = v.tSlotPos.x };
				end
			end
		end
	end

	-- Calculate zone positions
	CombatFormationManager.fillSlotsBySpiral(tData.tParty, {}, nPartyFacing);

	local nCenterX = tZone.x;
	local nCenterY = tZone.y;
	for _,tActor in pairs(tData.tParty) do
		-- Place on map at calculated positions
		local sRecord = tActor.sRecord;
		local nodeCT = ActorManager.getCTNode(sRecord);
		if not nodeCT then
			local sEntryRecordType = RecordDataManager.getRecordTypeFromRecordPath(sRecord);
			if CombatRecordManager.hasRecordTypeCallback(sEntryRecordType) then
				CombatRecordManager.onRecordTypeEvent(sEntryRecordType, tActor);
			end
			nodeCT = tActor.nodeCT;
		end

		local nTokenX = nCenterX + (tData.tImage.nImageGridW * tActor.tSlotPos.x);
		local nTokenY = nCenterY + (tData.tImage.nImageGridH * -tActor.tSlotPos.y);
		local tokenMap = CombatManager.addTokenFromCT(nodeImage, nodeCT, nTokenX, nTokenY);
		if tokenMap then
			if OptionsManager.isOption("TFAC", "on") then
				tokenMap.setOrientation(nPartyFacing * 2);
			end
			CombatManager.replaceCombatantToken(nodeCT, tokenMap);
		end
	end
end
function addEnemyToImage(tData)
	if #tData.tEnemy == 0 then
		return
	end

	-- need to collect number of zones and sort based off priority
	local tSortedEnemyZones = {};
	for i = 1, 8 do
		for _,v in ipairs(tData.tEnemyLoc) do
			if v.priority == i then
				tSortedEnemyZones[#tSortedEnemyZones + 1] = { zone = v.zone, tEnemy = {} };
				break;
			end
		end
	end
	if #tSortedEnemyZones == 0 then
		return
	end

	-- Break Enemy into even buckets based off number of zones
	local nMaxPerZone = math.ceil(#tData.tEnemy / #tSortedEnemyZones);
	local nSortedEnemyZone = 1;
	local tEnemyZone = tSortedEnemyZones[nSortedEnemyZone];
	for _,tActor in ipairs(tData.tEnemy) do
		if not tEnemyZone then
			break;
		end
		table.insert(tEnemyZone.tEnemy, tActor);

		if #(tEnemyZone.tEnemy) >= nMaxPerZone then
			nSortedEnemyZone = nSortedEnemyZone + 1;
			tEnemyZone = tSortedEnemyZones[nSortedEnemyZone];
		end
	end

	-- Add Enemy
	local nodeImage = tData.tImage.nodeImage;
	local nPartyZone = tData.nParty;
	local nPartyColumn = ((nPartyZone - 1) % 3) + 1;
	local nPartyRow = math.floor((nPartyZone - 1) * .333) + 1;
	for _,v in pairs(tSortedEnemyZones) do
		local tZone = tData.tZones[tonumber(v.zone)];
		if not v.tEnemy and not tZone then
			break;
		end

		-- Calculate Facing
		local nEnemyColumn = ((v.zone - 1) % 3) + 1;
		local nEnemyFacing = 0;
		if nEnemyColumn < nPartyColumn then
			nEnemyFacing = 1;
		elseif nEnemyColumn > nPartyColumn then
			nEnemyFacing = 3;
		else
			local nEnemyRow = math.floor((v.zone - 1) * .333) + 1;
			if nEnemyRow < nPartyRow then
				nEnemyFacing = 2;
			end
		end

		-- Calculate for Zone Positions
		CombatFormationManager.fillSlotsBySpiral(v.tEnemy, {}, nEnemyFacing);

		-- Place on map at calculated positions
		local nCenterX = tZone.x;
		local nCenterY = tZone.y;
		for _,vActor in ipairs(v.tEnemy) do
			local sRecord = vActor.sRecord;
			local nodeCT = ActorManager.getCTNode(sRecord);
			if not nodeCT then
				local sEntryRecordType = RecordDataManager.getRecordTypeFromRecordPath(sRecord);
				if CombatRecordManager.hasRecordTypeCallback(sEntryRecordType) then
					CombatRecordManager.onRecordTypeEvent(sEntryRecordType, vActor);
				end
				nodeCT = vActor.nodeCT;
			end

			local nTokenX = nCenterX + (tData.tImage.nImageGridW * vActor.tSlotPos.x);
			local nTokenY = nCenterY + (tData.tImage.nImageGridH * -vActor.tSlotPos.y);
			local tokenMap = CombatManager.addTokenFromCT(nodeImage, nodeCT, nTokenX, nTokenY);
			if tokenMap then
				if OptionsManager.isOption("TFAC", "on") then
					tokenMap.setOrientation(nEnemyFacing * 2);
				end
				CombatManager.replaceCombatantToken(nodeCT, tokenMap);
			end
		end
	end
end
function openImageRecord(tData)
	local wImage = RecordManager.openRecordWindow("image", tData.tImage.nodeRecord);
	wImage.getImage().zoomToFit();
end
