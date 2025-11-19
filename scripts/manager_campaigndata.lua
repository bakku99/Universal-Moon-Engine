--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	CampaignDataManager.resetCharRecordLocks();

	DB.addEventHandler("onImport", CampaignDataManager.onImport);
	DB.addEventHandler("onExport", CampaignDataManager.onExport);
end

function resetCharRecordLocks()
	if not Session.IsHost then
		return;
	end
	if not RecordDataManager.getLockMode("charsheet") then
		return;
	end
	RecordManager.callForEachCampaignRecord("charsheet", CampaignDataManager.resetCharRecordLock)
end
function resetCharRecordLock(nodeChar)
	DB.setValue(nodeChar, "locked", "number", 1);
end

--
--	DROP HANDLING
--

function handleFileDrop(sTarget, draginfo)
	if not Session.IsHost then
		return;
	end

	if sTarget == "image" then
		CampaignDataManager.importImageFilePath(draginfo.getStringData(), true);
		return true;
	end
end

function handleImageAssetDrop(sTarget, draginfo)
	if not Session.IsHost then
		return;
	end

	if sTarget == "image" then
		local sAsset = draginfo.getTokenData();
		CampaignDataManager.createImageRecordFromAsset(sAsset, true);
	end
end
function handleDrop(sTarget, draginfo)
	if CampaignDataManager2 and CampaignDataManager2.handleDrop then
		if CampaignDataManager2.handleDrop(sTarget, draginfo) then
			return true;
		end
	end

	if not Session.IsHost then
		return;
	end

	if sTarget == "item" then
		ItemManager.handleAnyDrop(DB.createNode("item"), draginfo);
		return true;
	elseif sTarget == "combattracker" then
		return CombatDropManager.handleAnyDrop(draginfo);
	else
		return CampaignDataManager.handleStandardDrop(sTarget, draginfo);
	end
end
function handleStandardDrop(sTarget, draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	if CampaignDataManager.duplicateRecord(sTarget, sClass, sRecord) then
		return true;
	end
end

function importImageFilePath(sPath, bOpen)
	local sAssetName = Interface.addImageFile(sPath);
	if sAssetName then
		CampaignDataManager.createImageRecordFromAsset(sAssetName, bOpen);
	end
end
function importCampaignImageAssets()
	local tAssets = Interface.getAssets("image", "campaign/images");
	for _,v in ipairs(tAssets) do
		CampaignDataManager.createImageRecordFromAsset(v, false);
	end
end
function createImageRecordFromAsset(sAsset, bOpen)
	local bAllowEdit = RecordIndexManager.getEditMode("image");
	if not bAllowEdit then
		return;
	end

	local sName = UtilityManager.getAssetBaseFileName(sAsset);
	local nodeTarget = nil;
	local sRootMapping = RecordDataManager.getDataPathRoot("image");
	for _,nodeRecord in ipairs(DB.getChildList(sRootMapping)) do
		local sExistingName = DB.getValue(nodeRecord, "name", "");
		if sName == sExistingName then
			nodeTarget = nodeRecord;
		end
	end
	if not nodeTarget then
		nodeTarget = DB.createChild(sRootMapping);
		DB.setValue(nodeTarget, "name", "string", sName);
		DB.setValue(nodeTarget, "image", "image", sAsset);
	end
	if nodeTarget and bOpen then
		local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass("image");
		Interface.openWindow(sDisplayClass, nodeTarget);
	end
end

--
--	RECORD FUNCTIONS
--

function duplicateRecordWindow(w)
	if not w then
		return;
	end
	local sRecordType = RecordDataManager.getRecordTypeFromWindow(w);
	CampaignDataManager.duplicateRecord(sRecordType, w.getClass(), w.getDatabasePath(), true);
end
function duplicateRecord(sRecordType, sClass, sRecord, bOpen)
	if ((sClass or "") == "") or ((sRecord or "") == "") then
		return false;
	end
	if not RecordIndexManager.getEditMode(sRecordType) then
		return false;
	end

	local sTargetDataRoot = RecordDataManager.getDataPathRoot(sRecordType);

	local bCopy = false;
	if ((sTargetDataRoot or "") ~= "") then
		if (RecordDataManager.isRecordTypeDisplayClass(sRecordType, sClass)) then
			bCopy = true;
			if (sRecordType == "story") and (sClass == "referencemanualpage") then
				sTargetDataRoot = "reference.refmanualdata";
			end
		elseif ((sRecordType == "story") and RecordDataManager.isRecordTypeDisplayClass("note", sClass)) then
			bCopy = true;
		elseif ((sRecordType == "note") and RecordDataManager.isRecordTypeDisplayClass("story", sClass)) then
			bCopy = true;
		end
	end
	if not bCopy then
		return false;
	end

	local nodeSource = DB.findNode(sRecord);
	local nodeTarget = DB.createChildAndCopy(sTargetDataRoot, nodeSource);
	local sName = DB.getValue(nodeTarget, "name", "");
	if sName ~= "" then
		DB.setValue(nodeTarget, "name", "string", sName .. " " .. Interface.getString("masterindex_suffix_duplicate"));
	end
	if RecordDataManager.getLockMode(sRecordType) then
		DB.setValue(nodeTarget, "locked", "number", 1);
	end
	RecordManager.onRecordAddEvent(sRecordType, nodeTarget);
	if bOpen then
		RecordManager.openRecordWindow(sRecordType, nodeTarget);
	end
	return true;
end

--
--	IMPORT/EXPORT FUNCTIONS
--

local sImportRecordType = "";
function importChar()
	sImportRecordType = "charsheet";
	Interface.dialogFileOpen(CampaignDataManager.onImportFileSelection, nil, nil, true);
end
function importNPC()
	sImportRecordType = "npc";
	Interface.dialogFileOpen(CampaignDataManager.onImportFileSelection, nil, nil, true);
end
function importImage()
	sImportRecordType = "image";
	local tFileTypes = {
		jpg = "JPG Files",
		png = "PNG Files",
		webm = "WEBM Files",
		webp = "WEBP Files",
		uvtt = "UVTT Files",
		dd2vtt = "DD2VTT Files",
		df2vtt = "DF2VTT Files",
	};
	tFileTypes["*"] = "All Files";
	Interface.dialogFileOpen(CampaignDataManager.onImportFileSelection, tFileTypes, nil, true);
end
function onImportFileSelection(result, vPath)
	if result ~= "ok" then return; end

	if sImportRecordType == "charsheet" then
		local sRootMapping = RecordDataManager.getDataPathRoot(sImportRecordType);
		if sRootMapping then
			if type(vPath) == "table" then
				for _,v in ipairs(vPath) do
					DB.import(v, sRootMapping, "character");
					ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. v);
				end
			else
				DB.import(vPath, sRootMapping, "character");
				ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. vPath);
			end
		end
	elseif sImportRecordType == "npc" then
		local sRootMapping = RecordDataManager.getDataPathRoot(sImportRecordType);
		if sRootMapping then
			if type(vPath) == "table" then
				for _,v in ipairs(vPath) do
					DB.import(v, sRootMapping, "npc");
					ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. v);
				end
			else
				DB.import(vPath, sRootMapping, "npc");
				ChatManager.SystemMessage(Interface.getString("message_slashimportsuccess") .. ": " .. vPath);
			end
		end
	elseif sImportRecordType == "image" then
		if type(vPath) == "table" then
			for _,sPath in ipairs(vPath) do
				CampaignDataManager.importImageFilePath(sPath, false);
			end
		else
			CampaignDataManager.importImageFilePath(vPath, true);
		end
	end
end
function onImport(node)
	local aPath = StringManager.split(DB.getPath(node), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		if DB.getValue(node, "token", ""):sub(1,9) == "portrait_" then
			DB.setValue(node, "token", "token", "portrait_" .. DB.getName(node) .. "_token");
		end
	end
end

local sExportRecordType = "";
local sExportRecordPath = "";
function exportRecordWindow(w)
	local sRecordType = RecordDataManager.getRecordTypeFromWindow(w);
	if not RecordDataManager.getExportMode(sRecordType) then
		return;
	end
	sExportRecordType = sRecordType;
	sExportRecordPath = w.getDatabasePath();
	Interface.dialogFileSave(CampaignDataManager.onExportFileSelection);
end
function exportChar(nodeChar)
	sExportRecordType = "charsheet";
	if nodeChar then
		sExportRecordPath = DB.getPath(nodeChar);
	else
		sExportRecordPath = "";
	end
	Interface.dialogFileSave(CampaignDataManager.onExportFileSelection);
end
function exportNPC(nodeNPC)
	sExportRecordType = "npc";
	if nodeNPC then
		sExportRecordPath = DB.getPath(nodeNPC);
	else
		sExportRecordPath = "";
	end
	Interface.dialogFileSave(CampaignDataManager.onExportFileSelection);
end
function onExportFileSelection(sResult, sFilePath)
	if sResult ~= "ok" then
		return;
	end

	local sExportTag = RecordDataManager.getExportTag(sExportRecordType);
	if sExportTag == "" then
		return;
	end

	if (sExportRecordPath or "") ~= "" then
		DB.export(sFilePath, sExportRecordPath, sExportTag);
	else
		local sRootMapping = RecordDataManager.getDataPathRoot(sExportRecordType);
		if (sRootMapping or "") ~= "" then
			DB.export(sFilePath, sRootMapping, sExportTag, true);
		end
	end
end
function onExport(node, _, _, bList)
	if bList then
		ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess"));
	else
		ChatManager.SystemMessage(Interface.getString("message_slashexportsuccess") .. ": " .. DB.getValue(node, "name", ""));
	end
end

function addPregenChar(nodeSource)
	if CampaignDataManager2 and CampaignDataManager2.addPregenChar then
		return CampaignDataManager2.addPregenChar(nodeSource);
	end

	return CampaignDataManager.addPregenCharCore(nodeSource);
end
function addPregenCharCore(nodeSource)
	local nodeTarget = DB.createChildAndCopy("charsheet", nodeSource);

	local sToken = DB.getValue(nodeTarget, "token", "");
	if sToken:match("^portrait_.*_token$") then
		DB.setValue(nodeTarget, "token", "token", "");
	end

	local sPortrait = DB.getValue(nodeTarget, "portrait", "");
	if sPortrait ~= "" then
		RecordAssetManager.setCharPortrait(nodeTarget, sPortrait);
	end

	CampaignDataManager.addPregenCharLockListEntries(nodeTarget, "inventorylist");

	ChatManager.SystemMessage(Interface.getString("pregenchar_message_add"));
	return nodeTarget;
end
function addPregenCharLockListEntries(nodeTarget, sListPath)
	for _,v in ipairs(DB.getChildList(nodeTarget, sListPath)) do
		DB.setValue(v, "locked", "number", 1);
	end
end

--
-- Encounter management
--

function convertRndEncExprToEncCount(nodeNPC)
	local sExpr = DB.getValue(nodeNPC, "expr", "");
	DB.deleteChild(nodeNPC, "expr");

	sExpr = sExpr:gsub("$PC", tostring(PartyManager.getPartyCount()));

	local nCount = DiceManager.evalDiceMathExpression(sExpr);
	DB.setValue(nodeNPC, "count", "number", nCount);
	return nCount;
end
function generateEncounterFromRandom(nodeSource)
	if not nodeSource then
		return;
	end

	local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass("battle");
	local sRootMapping = RecordDataManager.getDataPathRoot("battle");
	if ((sRootMapping or "") == "") then
		return;
	end

	local nodeTarget = DB.createChildAndCopy(sRootMapping, nodeSource);

	local aDelete = {};
	local sTargetNPCList = RecordDataManager.getCustomData("battle", "npclist", "npclist");
	for _,nodeNPC in ipairs(DB.getChildList(nodeTarget, sTargetNPCList)) do
		local nCount = CampaignDataManager.convertRndEncExprToEncCount(nodeNPC);
		if nCount <= 0 then
			table.insert(aDelete, nodeNPC);
		end
	end
	for _,nodeDelete in ipairs(aDelete) do
		DB.deleteNode(nodeDelete);
	end
	DB.setValue(nodeTarget, "locked", "number", 1);

	if CampaignDataManager2 and CampaignDataManager2.onEncounterGenerated then
		CampaignDataManager2.onEncounterGenerated(nodeTarget);
	end

	Interface.openWindow(sDisplayClass, nodeTarget);
end

--
--	Misc
--

function setCharPortrait(nodeChar, sAsset)
	RecordAssetManager.setCharPortrait(nodeChar, sAsset);
end
