--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if RecordDataManager.getLockMode("charsheet") then
		self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
	end
	self.addHandler(getDatabaseNode());
end
function onClose()
	self.removeHandler();
end

function onLockModeChanged(bReadOnly)
	local tFields = { "name", "nonid_name", "weight", "idelete", };
	WindowManager.callSafeControlsSetLockMode(self, tFields, bReadOnly);
	-- local tFields = { "count", "location", "carried", };
	-- WindowManager.callSafeControlsSetLockMode(self, tFields, bReadOnly);
end
function onEditModeChanged()
	self.onLockModeChanged(not WindowManager.getEditMode(window, "inventorylist_iedit"));
end

local _node;
function addHandler(node)
	if node then
		_node = node;
		DB.addHandler(_node, "onDelete", self.onDelete);
	end
end
function removeHandler()
	if _node then
		DB.removeHandler(_node, "onDelete", self.onDelete);
		_node = nil;
	end
end
function onDelete(node)
	ItemManager.onCharRemoveEvent(node);
	self.removeHandler();
end
