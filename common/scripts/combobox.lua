--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals alignright buttonoffset center color font frame listdirection listfonts listframes listmaxsize listoffset unsorted

_tMetadataDefaults = {
	["button_h"] = 10,
	["button_icon"] = "combobox_button",
	["button_icon_active"] = "combobox_button_active",
	["button_offset_x"] = 0,
	["button_offset_y"] = 0,
	["font"] = "sheettext",
	["list_direction"] = "down",
	["list_font"] = "chatfont",
	["list_font_selected"] = "narratorfont",
	["list_frame"] = "",
	["list_frame_selected"] = "rowshade",
	["list_offset_x"] = 0,
	["list_offset_y"] = 5,
	["list_size_max"] = 0,
	["list_sorted"] = true,
};

function onInit()
	self.performOverridesInit();
	super.onInit();
end

local _fnSetReadOnly;
function performOverridesInit()
	_fnSetReadOnly = self.setReadOnly;
	self.setReadOnly = self.setReadOnlyOverride;
end
function setReadOnlyOverride(bValue)
	_fnSetReadOnly(bValue);
	if bValue then
		self.hideList();
	else
		self.refreshButtonDisplay();
	end
end

--
--	STANDARD CONTROL FUNCTIONS (AND OVERRIDES)
--

function onValueChanged()
	if self.onSelect then
		self.onSelect(self.getValue());
	end
end
function onClear()
	self.setListVisible(false);
end

--
--	DISPLAY PARAMETERS
--

function performDisplayParamInit()
	-- Read general parameters
	if unsorted then
		self.setMetadata("list_sorted", false);
	end
	if font and type(font[1]) == "string" then
		self.setMetadata("font", font[1]);
	end
	if color and type(color[1]) == "string" then
		self.setMetadata("color", color[1]);
	end

	-- Read button parameters
	if buttonoffset then
		local sOffset = buttonoffset[1];
		local nComma = string.find(sOffset, ",");
		if nComma then
			self.setMetadata("button_offset_x", tonumber(string.sub(sOffset, 1, nComma-1)));
			self.setMetadata("button_offset_y", tonumber(string.sub(sOffset, nComma+1)));
		end
	end

	-- Read list parameters
	if listmaxsize then
		self.setMetadata("list_size_max", tonumber(listmaxsize[1]) or 0);
	end
	if listdirection then
		if listdirection[1] == "up" then
			self.setMetadata("list_direction", "up");
		elseif listdirection[1] == "down" then
			self.setMetadata("list_direction", "down");
		end
	end
	if listoffset then
		local sPosition = listoffset[1];
		local nComma = string.find(sPosition, ",");
		if nComma then
			self.setMetadata("list_offset_x", tonumber(string.sub(sPosition, 1, nComma-1)));
			self.setMetadata("list_offset_y", tonumber(string.sub(sPosition, nComma+1)));
		else
			self.setMetadata("list_offset_y", tonumber(sPosition));
		end
	end
	if listfonts then
		if listfonts[1].normal and type(listfonts[1].normal[1]) == "string" then
			self.setMetadata("list_font", listfonts[1].normal[1]);
		end
		if listfonts[1].selected and type(listfonts[1].selected[1]) == "string" then
			self.setMetadata("list_font_selected", listfonts[1].selected[1]);
		end
	end
	if listframes then
		if listframes[1].normal and type(listframes[1].normal[1]) == "string" then
			self.setMetadata("list_frame", listframes[1].normal[1]);
		end
		if listframes[1].selected and type(listframes[1].selected[1]) == "string" then
			self.setMetadata("list_frame_selected", listframes[1].selected[1]);
		end
	end
end

function setColor(sColor)
	self.setMetadata("color", sColor, true);
end
function setFont(sFont)
	self.setMetadata("font", sFont, true);
end

--
--	UI MANAGEMENT
--

function performUIInit()
	-- Initialize button icon
	local sName = getName() or "";
	if (sName or "") ~= "" then
		local sButton = sName .. "_cbbutton";
		local cButton = window.createControl("combobox_button", sButton);
		self.setButtonControl(cButton);
		local nSizeH = self.getMetadata("button_h");
		local tOffset = { x = self.getMetadata("button_offset_x"), y = self.getMetadata("button_offset_y"), };
		cButton.setAnchor("right", sName, "right", "absolute", tOffset.x);
		cButton.setAnchor("top", sName, "center", "absolute", -(math.floor(nSizeH/2)) + tOffset.y);
		self.refreshButtonDisplay();
	end

	-- Determine if underlying node is read only (only applies to stringfield version)
	local node = self.getDatabaseNode();
	if node then
		if DB.isReadOnly(node) or not DB.isOwner(node) then
			self.setReadOnly(true);
		else
			self.updateVisibility();
		end
		setTooltipText(getValue());
	else
		self.updateVisibility();
	end
end
function performUICleanup()
	local cScrollbar = self.getScrollbarControl();
	if cScrollbar then
		self.setScrollbarControl(nil);
		cScrollbar.destroy();
	end
	local cList = self.getListControl();
	if cList then
		self.setListControl(nil);
		cList.destroy();
	end
	local cButton = self.getButtonControl();
	if cButton then
		self.setButtonControl(nil);
		cButton.destroy();
	end
end

local _ctrlButton = nil;
function getButtonControl()
	return _ctrlButton;
end
function setButtonControl(c)
	_ctrlButton = c;
end

local _ctrlList = nil;
function getListControl()
	return _ctrlList;
end
function setListControl(c)
	_ctrlList = c;
end
local _bActive = false;
function isListControlActive()
	return _bActive;
end
function setListControlActive(bState)
	_bActive = bState;
end
local _ctrlScroll = nil;
function getScrollbarControl()
	return _ctrlScroll;
end
function setScrollbarControl(c)
	_ctrlScroll = c;
end
function createListControls()
	local sName = getName();
	local cList = self.getListControl();
	if cList or (sName or "") == "" then
		return;
	end

	local sList = sName .. "_cblist";
	local sListScroll = sName .. "_cblistscroll";

	-- Create the list control
	if self.getMetadata("list_sorted") then
		cList = window.createControl("combobox_list_sorted", sList);
	else
		cList = window.createControl("combobox_list", sList);
	end
	self.setListControl(cList);
	cList.setTarget(sName);

	local tOffset = { x = self.getMetadata("list_offset_x"), y = self.getMetadata("list_offset_y"), };
	cList.setAnchor("left", sName, "left", "absolute", -(tOffset.x));
	cList.setAnchor("right", sName, "right", "absolute", tOffset.x);
	if self.getMetadata("list_direction") == "up" then
		cList.setAnchor("bottom", sName, "top", "absolute", -(tOffset.y));
		cList.resetAnchor("top");
	else
		cList.setAnchor("top", sName, "bottom", "absolute", tOffset.y);
		cList.resetAnchor("bottom");
	end

	-- Set the list parameters
	cList.setFonts(self.getMetadata("list_font"), self.getMetadata("list_font_selected"));
	cList.setFrames(self.getMetadata("list_frame"), self.getMetadata("list_frame_selected"));
	cList.setMaxRows(self.getMetadata("list_size_max"));

	-- Create list scroll bar
	local cScrollbar = window.createControl("combobox_scrollbar", sListScroll);
	self.setScrollbarControl(cScrollbar);
	cScrollbar.setAnchor("left", sList, "right", "absolute", -10);
	cScrollbar.setAnchor("top", sList, "top");
	cScrollbar.setAnchor("bottom", sList, "bottom");
	cScrollbar.setTarget(sList);

	self.refreshListDisplay();
end

function onVisibilityChanged()
	self.updateVisibility();
end
function updateVisibility()
	local bVisible = isVisible();
	if not bVisible then
		self.hideList();
	else
		self.refreshButtonDisplay();
	end
end

function refreshDisplay()
	self.refreshDataDisplay();
	self.refreshSelectionDisplay();
	self.refreshListDisplay();
end
local _widgetText = nil;
function refreshDataDisplay()
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

	if center then
		-- Do nothing
	elseif alignright then
		local w,_ = _widgetText.getSize();
		_widgetText.setPosition("right", -math.floor(w/2), 0);
	else
		-- Align left
		local w,_ = _widgetText.getSize();
		_widgetText.setPosition("left", math.floor(w/2), 0);
	end
end
function refreshListDisplay()
	local cList = self.getListControl();
	if not cList then
		return;
	end
	cList.clear();
	for _,sValue in ipairs(self.getValuesData()) do
		cList.addItem(self.getItemDataByValue(sValue));
	end
	self.refreshSelectionDisplay();
end
function refreshSelectionDisplay()
	if not self.isListControlActive() then
		return;
	end
	local cList = self.getListControl();
	if not cList then
		return;
	end
	cList.setSelectionValue(getValue());
end
function refreshButtonDisplay()
	local cButton = self.getButtonControl();
	if not cButton then
		return;
	end
	if self.isListControlActive() then
		cButton.setIcon(self.getMetadata("button_icon_active"));
	else
		cButton.setIcon(self.getMetadata("button_icon"));
	end
	cButton.setVisible(isVisible() and not isReadOnly());
end

function toggle()
	self.setListVisible(not self.isListControlActive());
end
function showList()
	self.setListVisible(true);
end
function hideList()
	self.setListVisible(false);
end
function setListVisible(bState)
	if bState then
		if not self.isListControlActive() then
			self.createListControls();
			local cList = self.getListControl();
			if cList then
				self.setListControlActive(true);
				cList.setVisible(true);
				cList.setFocus(true);
				cList.scrollToSelected();
				self.refreshSelectionDisplay();
			end
		end
	else
		if self.isListControlActive() then
			self.setListControlActive(false);
			local cList = self.getListControl();
			if cList then
				cList.setVisible(false);
			end
		end
	end
	self.refreshButtonDisplay();
end

--
--	UI EVENT
--

function onClickDown()
	if not isReadOnly() then
		return true;
	end
end
function onClickRelease()
	if not isReadOnly() then
		return self.activate();
	end
end
function activate()
	self.toggle();
	return true;
end

function onOptionClicked(wNewSelection)
	if wNewSelection then
		self.setValue(wNewSelection.Value.getValue());
	else
		self.setValue(0);
	end
	self.setListVisible(false);
end
function onOptionDelete(wDelete)
	local sValue = wDelete.Value.getValue();
	if self.onDelete then
		if self.onDelete(sValue) then
			return;
		end
	end
	self.remove(sValue);
end

--
--	BACKWARD COMPATIBILITY
--

function setComboBoxVisible(bState)
	setVisible(bState);
end

function isComboBoxReadOnly()
	return isReadOnly();
end
function setComboBoxReadOnly(bState)
	self.setReadOnly(bState);
end

function setListIndex(n)
	self.setIndex(n);
end
function setListValue(sValue)
	self.setValue(sValue);
end
function getSelectedValue()
	return self.getValue();
end

function add(sValue, sText, bAllowDelete)
	local tItem = { sValue = sValue or sText or "", sText = sText or sValue or "", bAllowDelete = bAllowDelete, };
	self.addItem(tItem);
end
function replace(nIndex, sValue, sText, bAllowDelete)
	local tValues = self.getValuesData();
	local sOriginalValue = tValues[nIndex];
	if not sOriginalValue then
		return;
	end

	local tItems = self.getItemsData();
	tItems[sOriginalValue] = nil;

	local tItem = { sValue = sValue or sText or "", sText = sText or sValue or "", bAllowDelete = bAllowDelete, };
	tItems[tItem.sValue] = tItem;
	self.getValuesData()[nIndex] = tItem.sValue;

	if self.getValue() == sOriginalValue then
		self.setValue(tItem.sValue);
	end

	self.refreshDisplay();
end
function remove(sValue)
	self.removeItem(sValue);
end
