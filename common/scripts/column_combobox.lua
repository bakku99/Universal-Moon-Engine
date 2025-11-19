--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals nohide

function onInit()
	local bControlReadOnly = isReadOnly();
	super.onInit();
	if bControlReadOnly or DB.isReadOnly(getDatabaseNode()) then
		self.update(true);
	end
end

function setLockMode(bReadOnly)
	local bShow = not bReadOnly or nohide or not isEmpty();
	self.setComboBoxVisible(bShow);
	self.setComboBoxReadOnly(bReadOnly);
end

function onVisibilityChanged()
	super.onVisibilityChanged();
	WindowManager.onColumnControlVisibilityChanged(self);
end

function update(bReadOnly, bForceHide)
	local bShow = not bForceHide and (not bReadOnly or nohide or not isEmpty());
	self.setComboBoxVisible(bShow);
	self.setComboBoxReadOnly(bReadOnly);
	return bShow;
end
