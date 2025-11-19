--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

PS_LIST = "partysheet.partyinformation";

local aEntryMap = {};
local aFieldMap = {};

function onInit()
	WindowTabManager.registerTab("partysheet_host", { sName = "main", sTabRes = "tab_main", sClass = "ps_main" });
	WindowTabManager.registerTab("partysheet_host", { sName = "inventory", sTabRes = "tab_inventory", sClass = "ps_inventory" });
	WindowTabManager.registerTab("partysheet_host", { sName = "order", sTabRes = "tab_order", sClass = "ps_order" });

	WindowTabManager.registerTab("partysheet_client", { sName = "main", sTabRes = "tab_main", sClass = "ps_main", sOption = "PSMN" });
	WindowTabManager.registerTab("partysheet_client", { sName = "inventory", sTabRes = "tab_inventory", sClass = "ps_inventory" });
	WindowTabManager.registerTab("partysheet_client", { sName = "order", sTabRes = "tab_order", sClass = "ps_order" });
end

function onTabletopInit()
	if Session.IsHost then
		for _,v in ipairs(PartyManager.getPartyNodes()) do
			PartyManager.linkPCFields(v);
		end

		DB.addHandler("charsheet.*", "onDelete", PartyManager.onCharDelete);
	end
end

function getPartyNodes()
	return DB.getChildList(PartyManager.PS_LIST);
end
function getPartyCount()
	return DB.getChildCount(PartyManager.PS_LIST);
end
function getPartyActors()
	local tParty = {};
	for _,v in ipairs(PartyManager.getPartyNodes()) do
		local _,sRecord = DB.getValue(v, "link");
		local rActor = ActorManager.resolveActor(sRecord);
		if rActor then
			table.insert(tParty, rActor);
		end
	end
	return tParty;
end

function mapChartoPS(nodeChar)
	if not nodeChar then return nil; end

	local sChar = DB.getPath(nodeChar);
	for _,v in ipairs(PartyManager.getPartyNodes()) do
		local _,sRecord = DB.getValue(v, "link", "", "");
		if sRecord == sChar then
			return v;
		end
	end
	return nil;
end
function mapPStoChar(nodePS)
	if not nodePS then return nil; end

	local _,sRecord = DB.getValue(nodePS, "link", "", "");
	if sRecord == "" then return nil; end
	return DB.findNode(sRecord);
end

function onCharDelete(nodeChar)
	local nodePS = PartyManager.mapChartoPS(nodeChar);
	if nodePS then
		DB.deleteNode(nodePS);
	end

	PartyFormationManager.onFormationSourceDelete(nodeChar);
end

function onLinkUpdated(nodeField)
	DB.setValue(aFieldMap[DB.getPath(nodeField)], DB.getType(nodeField), DB.getValue(nodeField));
end
function onLinkDeleted(nodeField)
	local sFieldName = DB.getPath(nodeField);
	aFieldMap[sFieldName] = nil;
	DB.removeHandler(sFieldName, 'onUpdate', PartyManager.onLinkUpdated);
	DB.removeHandler(sFieldName, 'onDelete', PartyManager.onLinkDeleted);
end

function onEntryDeleted(nodePS)
	local sPath = DB.getPath(nodePS);
	if aEntryMap[sPath] then
		DB.removeHandler(sPath, "onDelete", PartyManager.onEntryDeleted);
		aEntryMap[sPath] = nil;

		for k,v in pairs(aFieldMap) do
			if string.sub(v, 1, sPath:len()) == sPath then
				aFieldMap[k] = nil;
				DB.removeHandler(k, "onUpdate", PartyManager.onLinkUpdated);
				DB.removeHandler(k, "onDelete", PartyManager.onLinkDeleted);
			end
		end
	end
end

function linkRecordField(nodeRecord, nodePS, sField, sType, sPSField)
	if not nodeRecord then return; end

	if not sPSField then
		sPSField = sField;
	end

	local sPath = DB.getPath(nodePS);
	if not aEntryMap[sPath] then
		DB.addHandler(sPath, "onDelete", PartyManager.onEntryDeleted);
		aEntryMap[sPath] = true;
	end

	local nodeField = DB.createChild(nodeRecord, sField, sType);
	DB.addHandler(nodeField, "onUpdate", PartyManager.onLinkUpdated);
	DB.addHandler(nodeField, "onDelete", PartyManager.onLinkDeleted);

	aFieldMap[DB.getPath(nodeField)] = DB.getPath(nodePS, sPSField);
	PartyManager.onLinkUpdated(nodeField);
end

function linkPCFields(nodePS)
	if PartyManager2 and PartyManager2.linkPCFields then
		PartyManager2.linkPCFields(nodePS);
		return;
	end

	local nodeChar = PartyManager.mapPStoChar(nodePS);
	PartyManager.linkRecordField(nodeChar, nodePS, "name", "string");
end

--
-- DROP HANDLING
--

function onDrop(draginfo)
	if Session.IsHost then
		if draginfo.isType("shortcut") or draginfo.isType("token") then
			local sClass = draginfo.getShortcutData();
			if (sClass or "") == "charsheet" then
				PartyManager.addChar(draginfo.getDatabaseNode());
			end
			return true;
		end
	end
	return false;
end
function addChar(nodeChar)
	local nodePS = PartyManager.mapChartoPS(nodeChar)
	if nodePS then
		return;
	end

	nodePS = DB.createChild(PartyManager.PS_LIST);
	DB.setValue(nodePS, "link", "windowreference", "charsheet", DB.getPath(nodeChar));
	PartyManager.linkPCFields(nodePS);
end
