--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals font parameters stateicons

_tMetadataDefaults = {
	["font"] = "sheetlabel",
	["icon_off"] = "button_checkoff",
	["icon_on"] = "button_checkon",
	["option_w"] = 50,
};

--
--	DISPLAY PARAMETERS
--

function performDisplayParamInit()
	if font then
		self.setMetadata("font", font[1]);
	end
	if parameters then
		if parameters[1].optionwidth then
			self.setMetadata("option_w", tonumber(parameters[1].optionwidth[1]));
		end
	end
	if stateicons then
		for k,v in pairs(stateicons[1]) do
			if (v[1] or "") ~= "" then
				self.setMetadata("icon_" .. k, v[1]);
			end
		end
	end
end

--
--	UI DISPLAY
--

local _tLabelWidgets = {};
local _tBoxWidgets = {};
function refreshDisplay()
	if #_tBoxWidgets ~= #self.getValuesData() then
		self.refreshFullDisplay();
	else
		self.refreshDataDisplay();
	end
end
function refreshFullDisplay()
	-- Clean up previous values, if any
	for _,v in pairs(_tLabelWidgets) do
		v.destroy();
	end
	_tLabelWidgets = {};
	for _,v in pairs(_tBoxWidgets) do
		v.destroy();
	end
	_tBoxWidgets = {};

	-- Create a set of widgets for each option
	local nOptionWidth = self.getMetadata("option_w");
	local tValues = self.getValuesData();
	for k,sValue in ipairs(tValues) do
		-- Create a label widget
		local h = 0;
		local tItem = self.getItemDataByValue(sValue);
		if tItem then
			_tLabelWidgets[k] = addTextWidget({ font = self.getMetadata("font"), text = tItem.sText or "", });
			local w;
			w,h = _tLabelWidgets[k].getSize();
			_tLabelWidgets[k].setPosition("topleft", ((k - 1)*nOptionWidth) + (w / 2) + 20, h / 2);
		end

		-- Create the checkbox widget
		_tBoxWidgets[k] = addBitmapWidget(self.getMetadata("icon_off"));
		if h == 0 then
			w,h = _tBoxWidgets[k].getSize();
		end
		_tBoxWidgets[k].setPosition("topleft", ((k - 1) * nOptionWidth) + 10, h / 2);
	end

	-- Set the right display
	self.refreshDataDisplay();
end
function refreshDataDisplay()
	local n = self.getIndex();
	for k,v in ipairs(_tBoxWidgets) do
		v.setBitmap((k == n) and self.getMetadata("icon_on") or self.getMetadata("icon_off"));
	end
	setAnchoredWidth(#_tBoxWidgets * self.getMetadata("option_w"));
end

--
--	UI BEHAVIORS
--

function onClickDown()
	return true;
end
function onClickRelease(_, x, _)
	if isReadOnly() then
		return true;
	end
	self.setIndex(math.floor(x / self.getMetadata("option_w")) + 1);
	return true;
end
