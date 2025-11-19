--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onRechargeChanged();
	self.onLockModeChanged(WindowManager.getWindowReadOnlyState(self));
end

function onLockModeChanged(bReadOnly)
	WindowManager.callSafeControlsSetLockMode(self, { "name", }, bReadOnly);
end

function onUsedChanged()
	parentcontrol.window.windowlist.onUsedChanged();
end
function onRechargeChanged()
	local sRecharge = DB.getValue(getDatabaseNode(), "recharge", ""):lower():sub(1,2);
	if sRecharge == "da" or sRecharge == "re" then -- 13A (re)
		name.setColor("FFFFFF");
		name.setFrame("headerpowerdaily", 8, 0, 8, 1)
	elseif sRecharge == "en" or sRecharge == "ba" or sRecharge == "ac" then  -- 4E (en/ac) / 13A (ba/ac)
		name.setColor("FFFFFF");
		name.setFrame("headerpowerenc", 8, 0, 8, 1)
	elseif sRecharge == "at" then
		name.setColor("FFFFFF");
		name.setFrame("headerpoweratwill", 8, 0, 8, 1)
	else
		name.setColor(UtilityManager.getFontColorSansAlpha("sheettext"));
		name.setFrame("fielddark", 7, 5, 7, 5);
	end
end
