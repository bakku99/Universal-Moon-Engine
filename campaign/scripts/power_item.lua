--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if not windowlist.isReadOnly() then
		PowerManagerCore.registerDefaultPowerMenu(self);
	end
	PowerManagerCore.handleDefaultPowerInitParse(getDatabaseNode());

	self.updateDetailButton();
	self.toggleDetail();
	self.onDisplayChanged();

	if windowlist and windowlist.onChildWindowAdded then
		windowlist.onChildWindowAdded(self);
	end

	if RecordDataManager.getLockMode("charsheet") then
		self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
	end

	local node = getDatabaseNode();
	local sActionsPath = PowerManagerCore.getPowerActionsPath();
	DB.addHandler(DB.getPath(node, sActionsPath), "onChildAdded", self.onActionListChanged);
	DB.addHandler(DB.getPath(node, sActionsPath), "onChildDeleted", self.onActionListChanged);
end
function onClose()
	local node = getDatabaseNode();
	local sActionsPath = PowerManagerCore.getPowerActionsPath();
	DB.removeHandler(DB.getPath(node, sActionsPath), "onChildAdded", self.onActionListChanged);
	DB.removeHandler(DB.getPath(node, sActionsPath), "onChildDeleted", self.onActionListChanged);
end

function onLockModeChanged(bReadOnly)
	WindowManager.callSafeControlsSetLockMode(self, { "idelete", }, bReadOnly);
end
function onActionListChanged()
	if not activatedetail then
		return;
	end
	self.updateDetailButton();
end
function onDisplayChanged()
	PowerManagerCore.updatePowerDisplay(self);
end

function onMenuSelection(...)
	PowerManagerCore.onDefaultPowerMenuSelection(self, ...)
end

function updateDetailButton()
	if not activatedetail then
		return;
	end

	local bShow = (DB.getChildCount(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()) > 0);
	if not bShow then
		activatedetail.setValue(0);
	end
	activatedetail.setVisible(bShow);
end
function toggleDetail()
	if not activatedetail then
		return;
	end

	local bShow = (activatedetail.getValue() == 1);
	if bShow then
		actions.setDatabaseNode(DB.createChild(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()));
	else
		actions.setDatabaseNode(nil);
	end
	actions.setVisible(bShow);
end

local _bFilter = true;
function setFilter(bNewFilter)
	_bFilter = bNewFilter;
end
function getFilter()
	return _bFilter;
end
