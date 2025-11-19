--
--  Please see the license.html file included with this distribution for
--  attribution and copyright information.
--

function onInit()
	self.onTypeChanged();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end

function onLockModeChanged(bReadOnly)
	WindowManager.callSafeControlsSetLockMode(self, { "type", }, bReadOnly);
end

function onTypeChanged()
	local nodeRecord = getDatabaseNode();
	local sType = DB.getValue(nodeRecord, "type", "");
	if sType == "trigger" then
		type_stats.setValue("soundset_main_trigger", nodeRecord);
	elseif sType == "content" then
		type_stats.setValue("soundset_main_content", nodeRecord);
	else
		type_stats.setValue("", "");
	end
end

function onDrop(_, _, draginfo)
	return SoundsetManager.handleAnyDrop(draginfo, getDatabaseNode());
end
