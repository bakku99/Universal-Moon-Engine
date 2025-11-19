--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals HRIR_WIDGET_POS HRIR_WIDGET_X HRIR_WIDGET_Y HRIR_WIDGET_W HRIR_WIDGET_H

HRIR_WIDGET_POS = "topright";
HRIR_WIDGET_X = -10;
HRIR_WIDGET_Y = 12;
HRIR_WIDGET_W = 20;
HRIR_WIDGET_H = 20;

local _tData;
function getData()
	return _tData;
end
function getRecordPath()
	return "";
end

function initData(tData)
	_tData = tData;
	self.handleText(tData);
	self.handleHRIROption();
end
function handleText(tData)
	setValue(tData.nRound or 0);
end
function handleHRIROption()
	if not OptionsManager.isOption("HRIR", "on") then
		return;
	end

	addBitmapWidget({
		name = "hrir",
		icon = "button_toolbar_refresh",
		color = Interface.getFontColor("sheetnumber"),
		position = HRIR_WIDGET_POS,
		x = HRIR_WIDGET_X, y = HRIR_WIDGET_Y,
		w = HRIR_WIDGET_W, h = HRIR_WIDGET_H,
	});
end
