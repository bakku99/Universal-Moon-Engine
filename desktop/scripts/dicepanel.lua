--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bHoverLock = false;

function onInit()
	self.onLockStateChanged();
end

function onHover(bOnWindow)
	if getLockState() then
		if not bOnWindow then
			_bHoverLock = false;
			self.updateButtonDisplay();
			button_lock.setVisible(false);
		end
	end
end
function onHoverUpdate(x, _)
	if getLockState() then
		_bHoverLock = (x <= 20);
		self.updateButtonDisplay();
	end
end
function onLockStateChanged()
	local bLockState = getLockState();
	setFrame(bLockState and "" or "border");
	button_lock.setValue(bLockState and 1 or 0);
	self.updateButtonDisplay();
	DiceManager.onDicePanelLockChanged();
end

function onLockButtonPressed()
	setLockState(not getLockState());
end

function onResetButtonPressed()
	resetPosition();
end

function updateButtonDisplay()
	local bShowReset = not getLockState();
	local bShowLock = _bHoverLock or bShowReset;
	button_lock.setVisible(bShowLock);
	button_reset.setVisible(bShowReset);
end
