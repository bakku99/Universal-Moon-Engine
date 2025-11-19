--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local RULESET_NAME = "CoreRPG";
local VERSION_MAJOR = 7;
local VERSION_REGISTRY_GLOBAL = 1;

function onInit()
	if Session.IsHost then
		VersionManager.updateCampaign();
	end
	Module.addEventHandler("onModuleLoad", VersionManager.onModuleLoad);
	VersionManager.updateGlobalRegistry();
end

function onModuleLoad(sModule)
	local _, _, aMajor, _ = DB.getRulesetVersion(sModule);
	VersionManager.updateModule(sModule, aMajor[RULESET_NAME]);
end

function updateCampaign()
	local _, _, aMajor, _ = DB.getRulesetVersion();
	local major = aMajor[RULESET_NAME];
	if not major then
		return;
	end

	if major > 0 and major < VERSION_MAJOR then
		ChatManager.SystemMessage("Migrating campaign database to latest data version. (" .. RULESET_NAME ..")");
		DB.backup();

		if major < 2 then
			VersionManager.convertNotes2();
		end
		if major < 4 then
			VersionManager.convertImages4();
			VersionManager.convertItems4();
			VersionManager.convertPartyItems4();
		end
		if major < 5 then
			VersionManager.convertCurrency5();
		end
		if major < 6 then
			VersionManager.convertParty6();
		end
		if major < 7 then
			VersionManager.convertCharsCoinOther7();
		end
	end
end
function updateModule(sModule, nVersion)
	if not nVersion then nVersion = 0; end
	if nVersion > 0 and nVersion < VERSION_MAJOR then
		local nodeRoot = DB.getRoot(sModule);
		if not nodeRoot then return; end
		if nVersion < 4 then
			VersionManager.convertImages4(nodeRoot);
			VersionManager.convertItems4(nodeRoot);
		end
	end
end
function updateGlobalRegistry()
	if not GlobalRegistry then
		return;
	end
	local nVersion = GlobalRegistry.version and GlobalRegistry.version[RULESET_NAME] or 0;
	if nVersion < VERSION_REGISTRY_GLOBAL then
		if nVersion < 1 then
			VersionManager.convertRegistry1();
		end
	end
	if not GlobalRegistry.version then
		GlobalRegistry.version = {};
	end
	GlobalRegistry.version[RULESET_NAME] = VERSION_REGISTRY_GLOBAL;
end

function convertNotes2()
	for _,vNote in ipairs(DB.getChildList("notes")) do
		local vText = DB.getChild(vNote, "text");
		if DB.getType(vText) == "string" then
			local sText = DB.getValue(vText);
			sText = "<p>" .. sText:gsub("\n", "</p><p>") .. "</p>";
			DB.deleteChild(vNote, "text");
			DB.setValue(vNote, "text", "formattedtext", sText);
		end
	end
end
function convertImages4(nodeRoot)
	local sValue = DB.getValue("options.IMID", "");
	if sValue == "on" then return; end

	local aMappings = RecordDataManager.getDataPaths("image");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in ipairs(DB.getChildList(DB.getPath(nodeRoot, vMapping))) do
			DB.deleteChild(vNode, "isidentified");
		end
	end
end
function convertItems4(nodeRoot)
	local sValue = DB.getValue("options.MIID", "");
	if sValue == "on" then return; end

	local aMappings = RecordDataManager.getDataPaths("item");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in ipairs(DB.getChildList(DB.getPath(nodeRoot, vMapping))) do
			DB.deleteChild(vNode, "isidentified");
		end
	end

	local aMappings = RecordDataManager.getDataPaths("treasureparcel");
	for _,vMapping in ipairs(aMappings) do
		for _,vNode in ipairs(DB.getChildList(DB.getPath(nodeRoot, vMapping))) do
			for _,vParcelItem in ipairs(DB.getChildList(vNode, "itemlist")) do
				DB.deleteChild(vParcelItem, "isidentified");
			end
		end
	end
end
function convertPartyItems4()
	local sValue = DB.getValue("options.MIID", "");
	if sValue == "on" then return; end

	for _,vParcelItem in ipairs(DB.getChildList("partysheet.treasureparcelitemlist")) do
		DB.deleteChild(vParcelItem, "isidentified");
	end
end
function convertCurrency5()
	if not GameSystem.currencies then
		return;
	end

	local tGameCurrencies = {};
	for _,tGameCurrency in ipairs(GameSystem.currencies) do
		local tNew = {
			sName = tGameCurrency["name"] or tGameCurrency,
			nWeight = tGameCurrency["weight"] or 0,
			nValue = tGameCurrency["value"] or 0,
		};
		if type(tNew.sName) == "string" then
			tNew.sNameLower = tNew.sName:lower();
		else
			tNew.sNameLower = "";
		end
		table.insert(tGameCurrencies, tNew);
	end

	for _,nodeCurrency in ipairs(DB.getChildList("currencies")) do
		local nWeight = DB.getValue(nodeCurrency, "weight", 0);
		local nValue = DB.getValue(nodeCurrency, "value", 0);
		if (nWeight == 0) and (nValue == 0) then
			local sNameLower = StringManager.trim(DB.getValue(nodeCurrency, "name", "")):lower();
			if sNameLower ~= "" then
				for _,tGameCurrency in ipairs(tGameCurrencies) do
					if sNameLower == tGameCurrency.sNameLower then
						DB.setValue(nodeCurrency, "weight", "number", tGameCurrency.nWeight);
						DB.setValue(nodeCurrency, "value", "number", tGameCurrency.nValue);
						break;
					end
				end
			end
		end
	end
end
function convertParty6()
	DB.deleteNode("partysheet.image");
	for _,v in ipairs(DB.getChildList("partysheet.partyinformation")) do
		DB.deleteChild(v, "token");
		DB.deleteChild(v, "tokenrefid");
		DB.deleteChild(v, "tokenrefnode");
	end
end
function convertCharsCoinOther7()
	RecordManager.callForEachRecord("charsheet", VersionManager.convertCharCoinOther7);
end
function convertCharCoinOther7(nodeChar)
	local sOther = DB.getValue(nodeChar, "coinother", "");
	if sOther ~= "" then
		local nodeCoinList = DB.createChild(nodeChar, "coins");
		if nodeCoinList then
			local nodeCoin = DB.createChild(nodeCoinList);
			DB.setValue(nodeCoin, "name", "string", sOther);
		end
	end
	DB.deleteChild(nodeChar, "coinother");
end
function convertRegistry1()
	if Session.IsHost and GlobalRegistry.imagedeathmarkersets then
		local tDefaultSets = ImageDeathMarkerData.getDefaultSets();
		local sResolvedKey = ImageDeathMarkerManager.resolveDefaultSetName("skull");
		if not GlobalRegistry.imagedeathmarkersets[sResolvedKey] then
			GlobalRegistry.imagedeathmarkersets[sResolvedKey] = tDefaultSets["skull"];
		end
		local sResolvedKey = ImageDeathMarkerManager.resolveDefaultSetName("tombstone");
		if not GlobalRegistry.imagedeathmarkersets[sResolvedKey] then
			GlobalRegistry.imagedeathmarkersets[sResolvedKey] = tDefaultSets["tombstone"];
		end
	end
end
