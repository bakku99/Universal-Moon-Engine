--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals allowalpha callback default

local _bColorDialogShown = false;
local _widgetColor;
local _sColor = "";

function onFirstLayout()
	local w,h = getSize();
	addBitmapWidget({ icon = "colorgizmo_bigbtn_base", w = w, h = h });
	_widgetColor = addBitmapWidget({ icon = "colorgizmo_bigbtn_color", w = w, h = h });
	addBitmapWidget({ icon = "colorgizmo_bigbtn_effects", w = w, h = h });

	self.updateColorDisplay();
end
function onClose()
	self.closeColorDialog();
end

function closeColorDialog()
	if _bColorDialogShown then
		Interface.dialogColorClose();
	end
end

function setValue(sColor)
	if ((sColor or "") == "") and default and default[1] then
		sColor = default[1];
	end
	_sColor = sColor;
	self.updateColorDisplay();
end
function getValue()
	if default and default[1] and (_sColor == default[1]) then
		return "";
	end
	return _sColor;
end
function updateColorDisplay()
	if _widgetColor then
		_widgetColor.setColor(_sColor);
	end
end

function onButtonPress()
	self.closeColorDialog();
	_bColorDialogShown = Interface.dialogColor(self.onColorDialogCallback, _sColor);
end
function onColorDialogCallback(sResult, sColor)
	if not allowalpha then
		if #sColor > 6 then
			sColor = sColor:sub(-6);
		end
	end
	self.setValue(sColor);
	if callback then
		WindowManager.callOuterWindowFunction(window, callback[1], self.getValue());
	else
		WindowManager.callOuterWindowFunction(window, "onColorChanged", self.getValue());
	end
	if sResult == "ok" or sResult == "cancel" then
		_bColorDialogShown = false;
	end
end
