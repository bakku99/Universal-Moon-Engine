--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	DATA
--

function onValueChanged()
	WindowManager.callOuterWindowFunction(window, "onUsedChanged");
end

--
--	DISPLAY
--

-- Enables/Disables incrementing, can still decrement
local _bIncrementEnabled = true;
function disable()
	_bIncrementEnabled = false;
	self.refreshDisplay();
end
function enable()
	_bIncrementEnabled = true;
	self.refreshDisplay();
end

function getSlotIcon(n)
	return ((n > self.getVarNumber("current")) and _bIncrementEnabled) and self.getMetadata("icon_off") or self.getMetadata("icon_on");
end
function getSlotColor(n)
	return ((n > self.getVarNumber("current")) and (not _bIncrementEnabled)) and self.getMetadata("color_disabled") or self.getMetadata("color_full");
end

--
--	UI EVENTS
--

function onWheel(n)
	if isReadOnly() then
		return;
	end
	if not Input.isControlPressed() then
		return false;
	end
	if not _bIncrementEnabled and (n > 0) then
		return false;
	end

	self.adjustCounter(n);
	return true;
end
function onClickRelease(_, x, y)
	if isReadOnly() then
		return;
	end

	local nCurr = self.getVarNumber("current");
	if self.calcClickValue(x, y) > nCurr then
		if not _bIncrementEnabled then
			return true;
		end
		self.adjustCounter(1);
	else
		self.adjustCounter(-1);
	end
	if self.getVarNumber("current") > nCurr then
		PowerManagerCore.usePower(window.getDatabaseNode());
	end

	return true;
end
