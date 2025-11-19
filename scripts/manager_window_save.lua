--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopClose()
	WindowSaveManager.saveWindowState();
end

function isNoSaveWindow(w)
	if w and w.placement and w.placement[1] and w.placement[1].nosave then
		return true;
	end
	return false;
end

function getWindowState()
	return CampaignRegistry.tabletopstate or {};
end
function setWindowState(t)
	CampaignRegistry.tabletopstate = t;
end

function loadWindowState()
	if not OptionsManager.isOption("WSAV", "on") then
		return;
	end
	local t = WindowSaveManager.getWindowState();
	for _,v in ipairs(t) do
		if v.class and v.path and ((v.path == "") or DB.isNode(v.path)) then
			Interface.openWindow(v.class, v.path);
		end
	end
	if t["_panels"] then
		local tPanel = t["_panels"]["imagebackpanel"];
		if tPanel and (tPanel["record"] or "") ~= "" then
			ImageManager.setPanelValue(ImageManager.getBackPanel(), tPanel["record"], tPanel["x"], tPanel["y"], tPanel["zoom"]);
		end
		local tPanel = t["_panels"]["imagemaxpanel"];
		if tPanel and (tPanel["record"] or "") ~= "" then
			ImageManager.setPanelValue(ImageManager.getMaxPanel(), tPanel["record"], tPanel["x"], tPanel["y"], tPanel["zoom"]);
		end
		local tPanel = t["_panels"]["imagefullpanel"];
		if tPanel and (tPanel["record"] or "") ~= "" then
			ImageManager.setPanelValue(ImageManager.getFullPanel(), tPanel["record"], tPanel["x"], tPanel["y"], tPanel["zoom"]);
		end
	end
end
function saveWindowState()
	local t = {};
	if OptionsManager.isOption("WSAV", "on") then
		for _,w in ipairs(Interface.getWindows()) do
			if not w.isPanel() and not w.isMinimized() and not WindowSaveManager.isNoSaveWindow(w) then
				table.insert(t, { class = w.getClass(), path = w.getDatabasePath() });
			end
		end
		local sRecord, x, y, zoom = ImageManager.getPanelValue(ImageManager.getBackPanel());
		if ((sRecord or "") ~= "") then
			t["_panels"] = t["_panels"] or {};
			t["_panels"]["imagebackpanel"] = { record = sRecord, x = x, y = y, zoom = zoom };
		end
		sRecord, x, y, zoom = ImageManager.getPanelValue(ImageManager.getMaxPanel());
		if ((sRecord or "") ~= "") then
			t["_panels"] = t["_panels"] or {};
			t["_panels"]["imagemaxpanel"] = { record = sRecord, x = x, y = y, zoom = zoom };
		end
		sRecord, x, y, zoom = ImageManager.getPanelValue(ImageManager.getFullPanel());
		if ((sRecord or "") ~= "") then
			t["_panels"] = t["_panels"] or {};
			t["_panels"]["imagefullpanel"] = { record = sRecord, x = x, y = y, zoom = zoom };
		end
	end
	WindowSaveManager.setWindowState(t);
end
