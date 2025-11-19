--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals alignleft alignright color font

_tMetadataDefaults = {
	["font"] = "sheettext",
};

--
--	DISPLAY PARAMETERS
--

function performDisplayParamInit()
	if font then
		self.setMetadata("font", font[1]);
	end
	if color then
		self.setMetadata("color", color[1]);
	end
end

function setColor(sColor)
	self.setMetadata("color", sColor, true);
end
function setFont(sFont)
	self.setMetadata("font", sFont, true);
end

--
--	UI DISPLAY
--

local _widgetText = nil;
function refreshDisplay()
	local sFont = self.getMetadata("font");
	local tItem = self.getItemDataByValue(self.getValue());
	local sText = tItem and tItem.sText or "";

	if not _widgetText then
		_widgetText = addTextWidget({ font = sFont, text = sText, });
	else
		_widgetText.setFont(sFont);
		_widgetText.setText(sText);
	end

	if (self.getMetadata("color") or "") ~= "" then
		_widgetText.setColor(self.getMetadata("color"));
	else
		_widgetText.setColor(nil);
	end

	if alignleft then
		local w,_ = _widgetText.getSize();
		_widgetText.setPosition("left", math.floor(w/2), 0);
	elseif alignright then
		local w,_ = _widgetText.getSize();
		_widgetText.setPosition("right", -math.floor(w/2), 0);
	end
end

--
--	UI BEHAVIORS
--

function onClickDown()
	return true;
end
function onClickRelease()
	if not isReadOnly() then
		self.cycleValue(Input.isControlPressed());
	end
	return true;
end

--
--	BACKWARD COMPATIBILITY
--

function setDisplayColor(sColor)
	self.setColor(sColor);
end
function setDisplayFont(sFont)
	self.setFont(sFont);
end

function initialize(sLabels, sValues, sEmptyLabel, sInitialValue)
	local tData = {
		sValues = sValues,
		sLabels = sLabels,
		sDefaultLabel = sEmptyLabel,
	};
	local tItems = self.getOptionItems(tData);
	self.setItems(tItems);

	if sInitialValue then
		self.setValue(sInitialValue);
	end
end
function initialize2(sLabels, sValues, sEmptyLabel, sInitialValue)
	local tData = {
		sValues = sValues,
		sLabels = UtilityManager.resolvePipedStringRes(sLabels),
		sDefaultLabel = sEmptyLabel,
	};
	local tItems = self.getOptionItems(tData);
	self.setItems(tItems);

	if sInitialValue then
		self.setValue(sInitialValue);
	end
end

function cycleLabel(bBackward)
	self.cycleValue(bBackward);
end
