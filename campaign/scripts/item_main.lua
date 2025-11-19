--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onStateChanged();
end

function onLockModeChanged()
	self.onStateChanged();
end
function onIDModeChanged()
	self.onStateChanged();
end

function onStateChanged()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = RecordDataManager.getIDState("item", nodeRecord);
	WindowManager.callSafeControlsSetLockMode(self, { "notes", "description", }, bReadOnly);
	WindowManager.callSafeControlsSetVisible(self, { "notes", "description", }, bID);

	WindowManager.callSafeControlUpdate(self, "sub_pack", bReadOnly, bID);
end

function onDrop(_, _, draginfo)
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	if bReadOnly then
		return false;
	end
	return ItemManager.handleAnyDropOnItemRecord(nodeRecord, draginfo);
end
