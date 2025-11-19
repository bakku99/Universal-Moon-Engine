--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.updateDisplay();
	UserManager.registerColorCallback(self.updateDisplay);
end
function onClose()
	UserManager.unregisterColorCallback(self.updateDisplay);
end

function initialize(sKey)
	self.setKey(sKey);
end

function setReadOnly()
	-- Do nothing; user color should always be local
end

function updateDisplay()
	color.setValue(UserManager.getIdentityColor());
end

function onColorChanged(sColor)
	UserManager.setIdentityColor(sColor);
end

function onDragStart(draginfo)
	local sKey = self.getKey();
	if sKey then
		draginfo.setType("shortcut");
		draginfo.setIcon("action_option");
		draginfo.setShortcutData("colorselect", "");
		draginfo.setDescription(self.getLabel());
		return true;
	end
end
