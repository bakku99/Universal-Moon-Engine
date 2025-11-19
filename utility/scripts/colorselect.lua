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

function updateDisplay()
	color.setValue(UserManager.getIdentityColor());
end
function onColorChanged(sColor)
	UserManager.setIdentityColor(sColor);
end
