--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("power_menu_action_delete"), "deletepointer", 4);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 4, 3);

	WindowManager.setInitialOrder(self);
	self.updateDisplay();

	local sRecordType = RecordDataManager.getRecordTypeFromWindow(WindowManager.getTopWindow(self));
	if RecordDataManager.getLockMode(sRecordType) then
		self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
	end
end

function onLockModeChanged(bReadOnly)
	WindowManager.callSafeControlsSetLockMode(self, { "idelete", "ireorder", }, bReadOnly);
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		DB.deleteNode(getDatabaseNode());
	end
end

function onDrop(_, _, draginfo)
	return WindowManager.handleDropReorder(self, draginfo);
end

function onTypeChanged()
	self.updateDisplay();
end
function onDataChanged()
	if contents and contents.subwindow then
		contents.subwindow.onDataChanged();
	end
end

function updateDisplay()
	if contents then
		local sType = DB.getValue(getDatabaseNode(), "type", "");
		local sContentClass = "power_action_" .. sType;
		if Interface.isWindowClass(sContentClass) then
			contents.setValue(sContentClass, getDatabaseNode());
		else
			contents.setValue("", "");
		end
	end
end
