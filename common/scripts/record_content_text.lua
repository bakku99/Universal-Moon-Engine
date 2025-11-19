--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals skipid target

function onInit()
	parentcontrol.onLayoutSizeChanged = self.onParentLayoutSizeChanged;
	self.onParentLayoutSizeChanged();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end

function getTextControlName()
	return (target and target[1]) or "text";
end
function getTextControl()
	return self[self.getTextControlName()];
end

function onParentLayoutSizeChanged()
	if not self then
		return;
	end
	local c = self.getTextControl();
	if not c then
		return;
	end

	local _,hWin = parentcontrol.getSize();
	c.setAnchoredHeight(nil, hWin - 10);
end

function onLockModeChanged(bReadOnly)
	local c = self.getTextControl();
	if not c then
		return;
	end

	c.setReadOnly(bReadOnly);

	if not skipid then
		local sRecordType = WindowManager.getRecordType(self);
		local bID = RecordDataManager.getIDState(sRecordType, getDatabaseNode());
		c.setVisible(bID);
	end
end
