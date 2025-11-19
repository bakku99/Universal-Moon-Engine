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
	self.setVisible(bShow);
	self.setReadOnly(bReadOnly);
end

function onVisibilityChanged()
	if super and super.onVisibilityChanged then
		super.onVisibilityChanged();
	end
	WindowManager.onColumnControlVisibilityChanged(self);
end

function update(bReadOnly, bForceHide)
	local bShow = not bForceHide and (not bReadOnly or nohide or not isEmpty());
	self.setVisible(bShow);
	self.setReadOnly(bReadOnly);
	return bShow;
end
