--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sButtonClass = nil;
local _sButtonPath = nil;
function onPreInitialize(_, tData)
	if tData then
		_sButtonClass = tData.buttonclass;
		_sButtonPath = tData.buttonpath;
		button.setStateText(0, Interface.getString(tData.buttonlabelres));
	end
end

function onButtonPress()
	if _sButtonClass then
		Interface.openWindow(_sButtonClass, _sButtonPath or "");
	end
end

function setReadOnly(bReadOnly)
	super.setReadOnly(bReadOnly);

	checkbox.setReadOnly(bReadOnly);
	button.setVisible(not bReadOnly);
	if bReadOnly then
		checkbox.setAnchor("right", nil, "right", "absolute", -58);
	else
		checkbox.setAnchor("right", nil, "right", "absolute", -105);
	end
end

function getDisplayValue()
	return StringManager.capitalize(self.getOptionValue());
end
function getOptionValue()
	if checkbox.getValue() ~= 0 then
		return "on";
	end
	return "off";
end
function onSetOptionValue(s)
	if s == "on" then
		checkbox.setValue(1);
	else
		checkbox.setValue(0);
	end
end
