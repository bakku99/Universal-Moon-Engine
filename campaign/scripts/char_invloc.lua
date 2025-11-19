--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local aAutoFill = {};

function onChar()
	if getCursorPosition() == #getValue() + 1 then
		local sCompletion = StringManager.autoComplete(aAutoFill, getValue(), true);
		if sCompletion then
			setValue(getValue() .. sCompletion);
			setSelectionPosition(getCursorPosition() + #sCompletion);
		end
		return;
	end
end
function onGainFocus()
	window.windowlist.setSortLock(true);
	aAutoFill = {};
	for _,w in ipairs(window.windowlist.getWindows()) do
		local bID = RecordDataManager.getIDState("item", w.getDatabaseNode());
		if bID then
			local s = w.name.getValue();
			if s ~= "" then
				table.insert(aAutoFill, s);
			end
		end
	end
	if super and super.onGainFocus then
		super.onGainFocus();
	end
end
function onLoseFocus()
	window.windowlist.setSortLock(false);
	if super and super.onLoseFocus then
		super.onLoseFocus();
	end
	window.windowlist.updateContainers();
end
