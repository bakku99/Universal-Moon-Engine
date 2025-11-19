--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	Standard features
--

function enableSimpleLocationHandling()
	if Session.IsHost then
		CharInventoryManager.enableInventoryUpdates();
		CharInventoryManager.registerFieldUpdateCallback("carried", CharInventoryManager.onLocationHandlingCarriedChange);
	end
end

local _bUpdatingContainerItemCarried = false;
function onLocationHandlingCarriedChange(nodeItem)
	if _bUpdatingContainerItemCarried then
		return;
	end

	local nodeChar = DB.getChild(nodeItem, "...");
	if not nodeChar then
		return;
	end

	_bUpdatingContainerItemCarried = true;
	local sCarriedItem = StringManager.trim(ItemManager.getDisplayName(nodeItem)):lower();
	if sCarriedItem ~= "" then
		local nCarried = DB.getValue(nodeItem, "carried", 0);
		for _,nodeInvItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
			if nodeInvItem ~= nodeItem then
				local sLoc = StringManager.trim(DB.getValue(nodeInvItem, "location", "")):lower();
				if sLoc == sCarriedItem then
					DB.setValue(nodeInvItem, "carried", "number", nCarried);
				end
			end
		end
	end
	_bUpdatingContainerItemCarried = false;
end

--
--	Field Update Callback Registration
--	Note: These callbacks are character sheet independent
--

local _tInvLists = {};
local _tFieldCallbacks = {};

function enableInventoryUpdates(sList)
	if not sList then
		sList = "inventorylist";
	end
	if not _tInvLists[sList] then
		_tInvLists[sList] = true;
		DB.addHandler("charsheet.*." .. sList .. ".*.*", "onUpdate", CharInventoryManager.onFieldUpdate);
	end
end
function registerFieldUpdateCallback(sField, fCallback)
	if not sField or not fCallback then
		return;
	end

	_tFieldCallbacks[sField] = _tFieldCallbacks[sField] or {};
	for _,v in ipairs(_tFieldCallbacks[sField]) do
		if v == fCallback then
			return;
		end
	end
	table.insert(_tFieldCallbacks[sField], fCallback);
end
function onFieldUpdate(nodeField)
	local nodeItem = DB.getParent(nodeField);
	local sField = DB.getName(nodeField);

	if _tFieldCallbacks[sField] then
		for _,fCallback in ipairs(_tFieldCallbacks[sField]) do
			fCallback(nodeItem, sField);
		end
	end
end
