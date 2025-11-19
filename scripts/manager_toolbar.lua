--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	REGISTRATION
--

local _tButtons = {};
function registerButton(sKey, tButton)
	if ((sKey or "") == "") or ((tButton and tButton.sType or "") == "") then
		return;
	end
	_tButtons[sKey] = tButton;
end
function getButton(sKey)
	return _tButtons[sKey or ""];
end
function checkButton(sKey)
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton then
		return false;
	end
	return true;
end

--
--	BUILD
--

function addList(w, t, sPosition)
	if not t then
		return;
	end
	for _,sKey in ipairs(t) do
		if (sKey or "") == "" then
			ToolbarManager.addSeparator(w, sPosition);
		else
			ToolbarManager.addButton(w, sKey, sPosition);
		end
	end
end
function addButton(w, sKey, sPosition)
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton or not tButton.sType then
		return;
	end
	local c = nil;
	if tButton.sType == "action" then
		local sTemplate = string.format("toolbar_%s_%s", tButton.sType or "", sPosition or "");
		c = w.createControl(sTemplate, "button_" .. sKey);
	elseif tButton.sType == "field" then
		local sTemplate = string.format("toolbar_field_%s", sPosition or "");
		c = w.createControl(sTemplate, sKey);
	elseif tButton.sType == "toggle" then
		local sTemplate = string.format("toolbar_toggle_%s", sPosition or "");
		c = w.createControl(sTemplate, sKey);
	elseif tButton.sType == "multifield" then
		local sTemplate = string.format("toolbar_multifield_%s", sPosition or "");
		c = w.createControl(sTemplate, sKey);
	end
	ToolbarManager.initButton(c, sKey);
	return c;
end
function addSeparator(w, sPosition)
	return w.createControl(string.format("toolbar_separator_%s", sPosition or ""));
end

--
--	BUTTON - GENERAL
--

function initButton(c, sKey)
	if not c then
		return;
	end
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton or not tButton.sType then
		c.setVisible(false);
		return;
	end
	c.setColor(ColorManager.getWindowMenuIconColor());
	if tButton.bHostOnly and not Session.IsHost then
		c.setVisible(false);
	end
	if tButton.bReadOnly then
		c.setReadOnly(true);
	end
	if tButton.sType == "action" then
		ToolbarManager.initButtonAction(c, sKey);
	elseif tButton.sType == "field" then
		ToolbarManager.initButtonField(c, sKey);
	elseif tButton.sType == "toggle" then
		ToolbarManager.initButtonToggle(c, sKey);
	elseif tButton.sType == "multifield" then
		ToolbarManager.initButtonField(c, sKey);
	end
	if c.init then
		c.init();
	end
	if tButton.fnOnInit then
		tButton.fnOnInit(c);
	end
end
function onButtonGetDefault(c)
	if not c then
		return 0;
	end
	local tButton = ToolbarManager.getButton(c.getName());
	if not tButton then
		return 0;
	end
	if tButton.nDefault then
		return tButton.nDefault;
	elseif tButton.fnGetDefault then
		return tButton.fnGetDefault(c);
	end
	return 0;
end
function onButtonValueChanged(c)
	if not c then
		return;
	end
	local tButton = ToolbarManager.getButton(c.getName());
	if not tButton then
		return;
	end
	if tButton.sValueChangeEvent and WindowManager.hasOuterWindowFunction(c.window, tButton.sValueChangeEvent) then
		WindowManager.callOuterWindowFunction(c.window, tButton.sValueChangeEvent, c.getValue());
	end
	if tButton.fnOnValueChange then
		tButton.fnOnValueChange(c);
	end
end

--
--	BUTTON - ACTION
--

function initButtonAction(c, sKey)
	if not c then
		return;
	end
	c.setKey(sKey);
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton then
		return;
	end
	if tButton.sIcon then
		c.setIcons(tButton.sIcon);
	end
	if tButton.sTooltipRes then
		c.setTooltipText(Interface.getString(tButton.sTooltipRes));
	end
	if tButton.sHoverCursor then
		c.setHoverCursor(tButton.sHoverCursor);
	end
	if tButton.sDatabaseEvent and tButton.fnOnDatabaseEvent then
		c.addDatabaseEvent(tButton.sDatabaseEvent, tButton.fnOnDatabaseEvent);
	end
end
function activateButtonAction(c, ...)
	if not c then
		return;
	end
	local sKey = c.getKey();
	if not sKey then
		return;
	end
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton then
		return;
	end
	if tButton.fnActivate then
		tButton.fnActivate(c, ...);
	end
end
function dragButtonAction(c, draginfo, ...)
	if not c then
		return;
	end
	local sKey = c.getKey();
	if not sKey then
		return;
	end
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton then
		return;
	end
	if tButton.fnDrag then
		return tButton.fnDrag(c, draginfo, ...);
	end
end

--
--	BUTTON - FIELD
--

function initButtonField(c, sKey)
	if not c then
		return;
	end
	local tButton = ToolbarManager.getButton(sKey);
	if not tButton then
		return;
	end
	if #tButton > 1 then
		for k,tState in ipairs(tButton) do
			c.setStateIcons(k - 1, tState.icon);
			c.setStateTooltipText(k - 1, Interface.getString(tState.tooltipres));
		end
	elseif #tButton == 1 then
		c.setStateIcons(0, tButton[1].icon);
		c.setStateTooltipText(0, Interface.getString(tButton[1].tooltipres));
		c.setStateIcons(1, tButton[1].icon);
		c.setStateTooltipText(1, Interface.getString(tButton[1].tooltipres));
	else
		c.setStateIcons(0, tButton.sIcon);
		c.setStateTooltipText(0, Interface.getString(tButton.sTooltipRes));
		c.setStateIcons(1, tButton.sIcon);
		c.setStateTooltipText(1, Interface.getString(tButton.sTooltipRes));
	end
end

--
--	BUTTON - TOGGLE
--

function initButtonToggle(c, sKey)
	ToolbarManager.initButtonField(c, sKey);
end
