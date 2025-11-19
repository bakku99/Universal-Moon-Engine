--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals field font parameters prefix resource static

DEFAULT_TEXT_FONT = "windowtitle";
DEFAULT_TEXT_OFFSET_Y = -3;
MIN_TEXT_WIDTH = 100;
MAX_TEXT_WINDOW_MARGIN = 60;

local _fnWindowLayoutSizeChanged = nil;

function onInit()
	self.createWidget();

	local sTitle = "";

	local bLinked = false;
	if field then
		local node = window.getDatabaseNode();
		if node then
			DB.addHandler(DB.getPath(node, field[1]), "onUpdate", self.onUpdate);
			sTitle = DB.getValue(node, field[1], "");
			bLinked = true;
		end
	end
	if not bLinked then
		if resource then
			sTitle = Interface.getString(resource[1]);
		elseif static then
			sTitle = static[1];
		else
			sTitle = Interface.getString(string.format("%s_window_title", window.getClass()));
		end
	end

	if prefix then
		sTitle = Interface.getString(prefix[1]) .. " - " .. sTitle;
	end

	self.setValue(sTitle);
	if not window.tooltip then
		window.setTooltipText(sTitle);
	end

	_fnWindowLayoutSizeChanged = window.onLayoutSizeChanged;
	window.onLayoutSizeChanged = self.handleWindowSizeChanged;
	self.updatePosition();
end
function onClose()
	if field then
		local node = window.getDatabaseNode();
		if node then
			DB.removeHandler(DB.getPath(node, field[1]), "onUpdate", self.onUpdate);
		end
	end
end

function handleWindowSizeChanged()
	if _fnWindowLayoutSizeChanged then
		_fnWindowLayoutSizeChanged();
	end
	self.updatePosition();
end

local _widgetTitle = nil;
function createWidget()
	local sTextFont = font and font[1];
	local sTextYOffset = parameters and parameters[1] and parameters[1].texty and parameters[1].texty[1];
	_widgetTitle = addTextWidget({
		font = sTextFont or self.DEFAULT_TEXT_FONT,
		x = 0, y = tonumber(sTextYOffset) or self.DEFAULT_TEXT_OFFSET_Y,
	});
end
function getWidget()
	return _widgetTitle;
end

function onUpdate()
	local sTitle = DB.getValue(window.getDatabaseNode(), field[1], "");
	if prefix then
		sTitle = Interface.getString(prefix[1]) .. " - " .. sTitle;
	end
	self.setValue(sTitle);
end

function setValue(sTitle)
	local wgt = self.getWidget();
	if wgt then
		wgt.setText(sTitle);
		self.updatePosition();
	end
end
function getValue()
	local wgt = self.getWidget();
	if wgt then
		return wgt.getText();
	end
	return "";
end

function updatePosition()
	local wgt = self.getWidget();
	if wgt then
		wgt.setMaxWidth(0);
		local wTitle, _ = wgt.getSize();
		local wWindow, _ = window.getSize();

		local sMinWidth = parameters and parameters[1] and parameters[1].minwidth and parameters[1].minwidth[1];
		local sMaxMargin = parameters and parameters[1] and parameters[1].windowmargin and parameters[1].windowmargin[1];

		local nMinWidth = tonumber(sMinWidth) or self.MIN_TEXT_WIDTH;
		local nMaxMargin = tonumber(sMaxMargin) or self.MAX_TEXT_WINDOW_MARGIN;

		local wMaxWidth = wWindow - (nMaxMargin * 2);
		if (wTitle > wMaxWidth) then
			wTitle = wMaxWidth;
		elseif (wTitle < nMinWidth) then
			wTitle = nMinWidth;
		end

		local nLeft = nMaxMargin + (wMaxWidth - wTitle) / 2;
		setAnchor("left", nil, "left", "absolute", nLeft);
		setAnchor("right", nil, "left", "absolute", nLeft + wTitle);
		wgt.setMaxWidth(wTitle);
	end
end
