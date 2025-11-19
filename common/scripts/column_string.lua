--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	WindowManager.onColumnControlInit(self);
end

function setLockMode(bReadOnly)
	WindowManager.onColumnControlSetLockMode(self, bReadOnly);
end
function getLockMode()
	return WindowManager.onColumnControlGetLockMode(self);
end

function onVisibilityChanged()
	WindowManager.onColumnControlVisibilityChanged(self);
end
function onValueChanged()
	WindowManager.onColumnControlValueChanged(self);
end

function update(bReadOnly, bForceHide)
	return WindowManager.onColumnControlUpdateLegacy(self, bReadOnly, bForceHide);
end
