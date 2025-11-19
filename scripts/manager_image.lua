--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ImageManager.addStandardDropHandlers();
	Interface.addKeyedEventHandler("onWindowOpened", "imagewindow", ImageManager.onWindowOpened);
end
function onTabletopInit()
	ImageManager.registerToolbarButtons();
	ImageManager.registerDBHandlers();
end

--
--	EVENTS
--

function onWindowOpened(w)
	ImageManager.checkImageSharing(w);
end

function onImageInit(cImage)
	if Session.IsHost then
		cImage.setTokenOrientationMode(false);
	end
	TokenManager.onImageInit(cImage);
	TokenMoveManager.onImageInit(cImage);
end
function onImageClose(cImage)
	TokenManager.onImageClose(cImage);
	TokenMoveManager.onImageClose(cImage);
end

function registerDBHandlers()
	local vNodes = RecordDataManager.getDataPaths("image");
	for i = 1, #vNodes do
		local sPath = vNodes[i] .. ".*@*";
		DB.addHandler(sPath, "onDelete", ImageManager.onImageRecordDeleted);
	end
end
function onImageRecordDeleted(nodeImageRecord)
	ImageManager.checkImagePanelDeletion(nodeImageRecord);
end

--
--	RESOLVERS
--

function isImageWindow(w)
	if not w then
		return false;
	end
	return StringManager.contains({ "imagewindow", "imagebackpanel", "imagemaxpanel", "imagefullpanel" }, WindowManager.getTopWindow(w).getClass());
end
function getImageControlFromWindow(w)
	local wTop = WindowManager.getTopWindow(w);
	if not wTop then
		return nil;
	end
	local sDisplayClass = wTop.getClass();
	if sDisplayClass == "imagewindow" then
		return wTop.image;
	elseif StringManager.contains({ "imagewindow", "imagebackpanel", "imagemaxpanel", "imagefullpanel" }, sDisplayClass) then
		return wTop.sub.subwindow.image;
	end
	return nil;
end
function getActiveImageFromToken(tokenMap)
	if not tokenMap then
		return nil;
	end
	local nodeImage = tokenMap.getContainerNode();
	if not nodeImage then
		return nil;
	end
	for _, cImage in ipairs(ImageManager.getActiveImages()) do
		if cImage.getDatabaseNode() == nodeImage then
			return cImage;
		end
	end
	return nil;
end

--
--	TOOLBAR
--

function registerToolbarButtons()
	ToolbarManager.registerButton("image_toolbar",
		{
			sType = "toggle",
			sIcon = "button_toolbar_toggle",
			sTooltipRes = "image_tooltip_toolbartoggle",
			fnGetDefault = ImageManager.onToolbarToggleGetValue,
			fnOnInit = ImageManager.onToolbarToggleInit,
			fnOnValueChange = ImageManager.onToolbarToggleValueChanged,
		});

	ToolbarManager.registerButton("image_navigation",
		{
			sType = "toggle",
			sIcon = "button_toolbar_navigation",
			sTooltipRes = "image_tooltip_toolbarnavigation",
			fnOnValueChange = ImageManager.onToolbarNavigationValueChanged,
		});
	ToolbarManager.registerButton("image_preview",
		{
			sType = "toggle",
			sIcon = "tool_preview_30",
			sTooltipRes = "image_tooltip_toolbarpreview",
			fnGetDefault = ImageManager.onToolbarPreviewGetValue,
			fnOnValueChange = ImageManager.onToolbarPreviewValueChanged,
		});
	ToolbarManager.registerButton("image_tokenlock",
		{
			sType = "toggle",
			sIcon = "tool_tokenlocked_30",
			sTooltipRes = "image_tooltip_toolbartokenlock",
			fnGetDefault = ImageManager.onToolbarTokenLockGetValue,
			fnOnValueChange = ImageManager.onToolbarTokenLockValueChanged,
		});
	ToolbarManager.registerButton("image_shortcut",
		{
			sType = "toggle",
			sIcon = "tool_shortcut_30",
			sTooltipRes = "image_tooltip_toolbarshortcut",
			fnGetDefault = ImageManager.onToolbarShortcutGetValue,
			fnOnValueChange = ImageManager.onToolbarShortcutValueChanged,
		});
	ToolbarManager.registerButton("image_deathmarker_clear",
		{
			sType = "action",
			sIcon = "tool_deathmarker_clear",
			sTooltipRes = "image_tooltip_toolbardeathmarkerclear",
			fnActivate = ImageManager.onToolbarDeathMarkerClearPressed,
		});

	ToolbarManager.registerButton("image_target_clear",
		{
			sType = "action",
			sIcon = "tool_target_clear_30",
			sTooltipRes = "image_tooltip_toolbartargetclear",
			fnActivate = ImageManager.onToolbarTargetClearPressed,
		});
	ToolbarManager.registerButton("image_target_friend",
		{
			sType = "action",
			sIcon = "tool_target_allies_30",
			sTooltipRes = "image_tooltip_toolbartargetfriend",
			fnActivate = ImageManager.onToolbarTargetFriendPressed,
		});
	ToolbarManager.registerButton("image_target_foe",
		{
			sType = "action",
			sIcon = "tool_target_enemies_30",
			sTooltipRes = "image_tooltip_toolbartargetfoe",
			fnActivate = ImageManager.onToolbarTargetFoePressed,
		});
	ToolbarManager.registerButton("image_target_select",
		{
			sType = "toggle",
			sIcon = "tool_target_select_30",
			sTooltipRes = "image_tooltip_toolbartarget",
			fnGetDefault = ImageManager.onToolbarTargetSelectGetValue,
			fnOnValueChange = ImageManager.onToolbarTargetSelectValueChanged,
		});
	ToolbarManager.registerButton("image_select",
		{
			sType = "toggle",
			sIcon = "tool_select_30",
			sTooltipRes = "image_tooltip_toolbarselect",
			fnGetDefault = ImageManager.onToolbarSelectGetValue,
			fnOnValueChange = ImageManager.onToolbarSelectValueChanged,
		});

	ToolbarManager.registerButton("image_erase",
		{
			sType = "toggle",
			sIcon = "tool_erase_30",
			sTooltipRes = "image_tooltip_toolbarerase",
			fnGetDefault = ImageManager.onToolbarEraseGetValue,
			fnOnValueChange = ImageManager.onToolbarEraseValueChanged,
		});
	ToolbarManager.registerButton("image_draw",
		{
			sType = "toggle",
			sIcon = "tool_paint_30",
			sTooltipRes = "image_tooltip_toolbardraw",
			fnGetDefault = ImageManager.onToolbarDrawGetValue,
			fnOnValueChange = ImageManager.onToolbarDrawValueChanged,
		});
	ToolbarManager.registerButton("image_unmask",
		{
			sType = "toggle",
			sIcon = "tool_mask_30",
			sTooltipRes = "image_tooltip_toolbarmask",
			fnGetDefault = ImageManager.onToolbarUnmaskGetValue,
			fnOnValueChange = ImageManager.onToolbarUnmaskValueChanged,
		});

	ToolbarManager.registerButton("image_ping",
		{
			sType = "toggle",
			sIcon = "button_toolbar_ping",
			sTooltipRes = "image_tooltip_toolbarping",
			fnGetDefault = ImageManager.onToolbarPingGetValue,
			fnOnValueChange = ImageManager.onToolbarPingValueChanged,
		});
	ToolbarManager.registerButton("image_view_token",
		{
			sType = "toggle",
			sIcon = "button_toolbar_share_specific",
			sTooltipRes = "image_tooltip_toolbarviewtoken",
			fnGetDefault = ImageManager.onToolbarViewTokenGetValue,
			fnOnValueChange = ImageManager.onToolbarViewTokenValueChanged,
		});
	ToolbarManager.registerButton("image_view_camera",
		{
			sType = "toggle",
			sIcon = "button_toolbar_camera",
			sTooltipRes = "image_tooltip_toolbarviewcamera",
			fnGetDefault = ImageManager.onToolbarViewCameraGetValue,
			fnOnValueChange = ImageManager.onToolbarViewCameraValueChanged,
		});
	ToolbarManager.registerButton("image_zoomtofit",
		{
			sType = "action",
			sIcon = "tool_zoomtofit_30",
			sTooltipRes = "image_tooltip_toolbarzoomtofit",
			fnActivate = ImageManager.onToolbarZoomToFitPressed,
		});
end

function onToolbarToggleGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return cImage.hasTokens() and 1 or 0;
end
function onToolbarToggleInit(c)
	ImageManager.onToolbarToggleValueChanged(c);
end
function onToolbarToggleValueChanged(c)
	local wTop = WindowManager.getTopWindow(c.window);
	wTop.toolbar.setVisible(c.getValue() == 1);

	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	cImage.setFocus();
end

function onToolbarNavigationValueChanged(c)
	local wTop = WindowManager.getTopWindow(c.window);

	local cCameraControls;
	if wTop.getClass() == "imagewindow" then
		cCameraControls = wTop.sub_camera_controls;
	else
		cCameraControls = wTop.sub.subwindow and wTop.sub.subwindow.sub_camera_controls or nil;
	end
	if cCameraControls then
		cCameraControls.setVisible(c.getValue() == 1);
	end

	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	cImage.setFocus();
end
function onToolbarPreviewGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return cImage.getPreviewState() and 1 or 0;
end
function onToolbarPreviewValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if cImage.getPreviewState() then
		cImage.setPreviewState(false);
	else
		cImage.setPreviewState(true);
	end
	cImage.setFocus();
end
function onToolbarTokenLockGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return cImage.getTokenLockState() and 1 or 0;
end
function onToolbarTokenLockValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if cImage.getTokenLockState() then
		cImage.setTokenLockState(false);
	else
		cImage.setTokenLockState(true);
	end
	cImage.setFocus();
end
function onToolbarShortcutGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return cImage.getShortcutState() and 1 or 0;
end
function onToolbarShortcutValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if cImage.getShortcutState() then
		cImage.setShortcutState(false);
	else
		cImage.setShortcutState(true);
	end
	cImage.setFocus();
end
function onToolbarDeathMarkerClearPressed(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	ImageDeathMarkerManager.clearMarkers(c.window.getDatabaseNode());
	cImage.setFocus();
end

function onToolbarTargetClearPressed(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	TargetingManager.clearTargets(cImage);
	cImage.setFocus();
end
function onToolbarTargetFriendPressed(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	TargetingManager.setFactionTargets(cImage);
	cImage.setFocus();
end
function onToolbarTargetFoePressed(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	TargetingManager.setFactionTargets(cImage, true);
	cImage.setFocus();
end
function onToolbarTargetSelectGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getCursorMode() == "target") and 1 or 0;
end
function onToolbarTargetSelectValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getCursorMode() == "target") then
		cImage.setCursorMode("");
	else
		cImage.setCursorMode("target");
	end
	cImage.setFocus();
end
function onToolbarSelectGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getCursorMode() == "select") and 1 or 0;
end
function onToolbarSelectValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getCursorMode() == "select") then
		cImage.setCursorMode("");
	else
		cImage.setCursorMode("select");
	end
	cImage.setFocus();
end

function onToolbarEraseGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getCursorMode() == "erase") and 1 or 0;
end
function onToolbarEraseValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getCursorMode() == "erase") then
		cImage.setCursorMode("");
	else
		cImage.setCursorMode("erase");
	end
	cImage.setFocus();
end
function onToolbarDrawGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getCursorMode() == "draw") and 1 or 0;
end
function onToolbarDrawValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getCursorMode() == "draw") then
		cImage.setCursorMode("");
	else
		cImage.setCursorMode("draw");
	end
	cImage.setFocus();
end
function onToolbarUnmaskGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getCursorMode() == "unmask") and 1 or 0;
end
function onToolbarUnmaskValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getCursorMode() == "unmask") then
		cImage.setCursorMode("");
	else
		cImage.setCursorMode("unmask");
	end
	cImage.setFocus();
end

function onToolbarPingGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getCursorMode() == "ping") and 1 or 0;
end
function onToolbarPingValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getCursorMode() == "ping") then
		cImage.setCursorMode("");
	else
		cImage.setCursorMode("ping");
	end
	cImage.setFocus();
end
function onToolbarViewTokenGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getViewMode() == "fpv") and 1 or 0;
end
function onToolbarViewTokenValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getViewMode() == "fpv") then
		cImage.setViewMode("");
	else
		cImage.setViewMode("fpv");
	end
	cImage.setFocus();
end
function onToolbarViewCameraGetValue(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	return (cImage.getViewMode() == "free") and 1 or 0;
end
function onToolbarViewCameraValueChanged(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	if (cImage.getViewMode() == "free") then
		cImage.setViewMode("");
	else
		cImage.setViewMode("free");
	end
	cImage.setFocus();
end
function onToolbarZoomToFitPressed(c)
	local cImage = WindowManager.callOuterWindowFunction(c.window, "getImage");
	cImage.zoomToFit();
	cImage.setFocus();
end

-- Panel functions

local _wBackPanel = nil;
function registerBackPanel(w)
	_wBackPanel = w;
end
function getBackPanel()
	return _wBackPanel;
end
local _wMaxPanel = nil;
function registerMaxPanel(w)
	_wMaxPanel = w;
end
function getMaxPanel()
	return _wMaxPanel;
end
local _wFullPanel = nil;
function registerFullPanel(w)
	_wFullPanel = w;
end
function getFullPanel()
	return _wFullPanel;
end

function getPanelValue(wPanel)
	if not wPanel then
		return "", "";
	end
	local _, sRecord = wPanel.sub.getValue();
	local x, y, zoom;
	if wPanel.sub.subwindow then
		x, y, zoom = wPanel.sub.subwindow.image.getViewpoint();
	end
	return sRecord, x, y, zoom;
end
function getPanelDataValue(wPanel)
	if not wPanel then
		return "";
	end
	local _, sRecord = wPanel.sub.getValue();
	return sRecord;
end
function isPanelDataValue(wPanel, sRecord)
	if (sRecord or "") == "" then
		return false;
	end
	local sPanelRecord = ImageManager.getPanelDataValue(wPanel);
	if (sPanelRecord or "") == "" then
		return false;
	end
	return (sPanelRecord == sRecord);
end
function clearPanelValue(wPanel)
	if not wPanel then
		return;
	end
	ImageManager.setPanelValue(wPanel, "", "");
end
function setPanelValue(wPanel, sRecord, x, y, zoom)
	if not wPanel then
		return;
	end
	local bShow = ((sRecord or "") ~= "");
	if bShow then
		wPanel.sub.setValue("imagepanelwindow", sRecord);
		wPanel.setBackColor("808080");
	else
		wPanel.sub.setValue();
		wPanel.setBackColor();
	end
	wPanel.setEnabled(bShow);
	if x and y and zoom and wPanel.sub.subwindow then
		wPanel.sub.subwindow.image.setViewpoint(x, y, zoom);
	end

	SoundsetManager.updateImageContext();
end

function closePanel()
	ImageManager.clearPanelValue(ImageManager.getBackPanel());
	ImageManager.clearPanelValue(ImageManager.getMaxPanel());
	ImageManager.clearPanelValue(ImageManager.getFullPanel());

	SoundsetManager.updateImageContext();
end
function sendWindowToBackPanel(w)
	local wBackPanel = ImageManager.getBackPanel();
	if not wBackPanel then
		return;
	end
	local sClass = w.getClass();
	if (sClass or "") ~= "imagewindow" then
		return;
	end
	local vNode = w.getDatabaseNode();
	if not vNode then
		return;
	end

	local x,y,zoom = w.image.getViewpoint();
	w.close();

	ImageManager.clearPanelValue(ImageManager.getMaxPanel());
	ImageManager.clearPanelValue(ImageManager.getFullPanel());

	ImageManager.setPanelValue(wBackPanel, DB.getPath(vNode), x, y, zoom);
end
function sendBackPanelToWindow()
	local wBackPanel = ImageManager.getBackPanel();
	if not wBackPanel then
		return;
	end

	local sRecord, x, y, zoom = ImageManager.getPanelValue(wBackPanel);
	ImageManager.clearPanelValue(wBackPanel);

	ImageManager.clearPanelValue(ImageManager.getMaxPanel());
	ImageManager.clearPanelValue(ImageManager.getFullPanel());

	local w = RecordManager.openRecordWindow("image", sRecord);
	if not w then
		SoundsetManager.updateImageContext();
		return;
	end
	w.image.setViewpoint(x, y, zoom);
end
function sendBackPanelToMaxPanel()
	local wBackPanel = ImageManager.getBackPanel();
	local wMaxPanel = ImageManager.getMaxPanel();
	if not wBackPanel or not wMaxPanel then
		return;
	end
	local sRecord, x, y, zoom = ImageManager.getPanelValue(wBackPanel);
	ImageManager.clearPanelValue(wBackPanel);

	ImageManager.clearPanelValue(ImageManager.getFullPanel());

	ImageManager.setPanelValue(wMaxPanel, sRecord, x, y, zoom);
end
function sendMaxPanelToBackPanel()
	local wBackPanel = ImageManager.getBackPanel();
	local wMaxPanel = ImageManager.getMaxPanel();
	if not wBackPanel or not wMaxPanel then
		return;
	end
	local sRecord, x, y, zoom = ImageManager.getPanelValue(wMaxPanel);
	ImageManager.clearPanelValue(wMaxPanel);

	ImageManager.clearPanelValue(ImageManager.getFullPanel());

	ImageManager.setPanelValue(wBackPanel, sRecord, x, y, zoom);
end
function sendMaxPanelToFullPanel()
	local wMaxPanel = ImageManager.getMaxPanel();
	local wFullPanel = ImageManager.getFullPanel();
	if not wMaxPanel or not wFullPanel then
		return;
	end
	local sRecord, x, y, zoom = ImageManager.getPanelValue(wMaxPanel);
	ImageManager.clearPanelValue(wMaxPanel);

	ImageManager.clearPanelValue(ImageManager.getBackPanel());

	ImageManager.setPanelValue(wFullPanel, sRecord, x, y, zoom);
end
function sendFullPanelToMaxPanel()
	local wMaxPanel = ImageManager.getMaxPanel();
	local wFullPanel = ImageManager.getFullPanel();
	if not wMaxPanel or not wFullPanel then
		return;
	end
	local sRecord, x, y, zoom = ImageManager.getPanelValue(wFullPanel);
	ImageManager.clearPanelValue(wFullPanel);

	ImageManager.clearPanelValue(ImageManager.getBackPanel());

	ImageManager.setPanelValue(wMaxPanel, sRecord, x, y, zoom);
end
function checkImageSharing(w)
	local sClass = w.getClass() or "";
	if sClass ~= "imagewindow" then
		return;
	end
	local vRecord = w.getDatabaseNode();
	if not vRecord then
		return;
	end

	local sRecord = DB.getPath(vRecord);
	if ImageManager.isPanelDataValue(ImageManager.getBackPanel(), sRecord) or
			ImageManager.isPanelDataValue(ImageManager.getMaxPanel(), sRecord) or
			ImageManager.isPanelDataValue(ImageManager.getFullPanel(), sRecord) then
		w.close();
	end
end
function checkImagePanelDeletion(nodeImageRecord)
	local bChanged = false;
	local sRecord = DB.getPath(nodeImageRecord);

	local wBackPanel = ImageManager.getBackPanel();
	if ImageManager.isPanelDataValue(wBackPanel, sRecord) then
		ImageManager.clearPanelValue(wBackPanel);
		bChanged = true;
	end
	local wMaxPanel = ImageManager.getMaxPanel();
	if ImageManager.isPanelDataValue(wMaxPanel, sRecord) then
		ImageManager.clearPanelValue(wMaxPanel);
		bChanged = true;
	end
	local wFullPanel = ImageManager.getFullPanel();
	if ImageManager.isPanelDataValue(wFullPanel, sRecord) then
		ImageManager.clearPanelValue(wFullPanel);
		bChanged = true;
	end
	if bChanged then
		SoundsetManager.updateImageContext();
	end
end

function performSizeUp(w)
	local wTop = WindowManager.getTopWindow(w);
	local sClass = wTop.getClass();
	if sClass == "imagewindow" then
		ImageManager.sendWindowToBackPanel(wTop);
	elseif sClass == "imagebackpanel" then
		ImageManager.sendBackPanelToMaxPanel();
	elseif sClass == "imagemaxpanel" then
		ImageManager.sendMaxPanelToFullPanel();
	end
end
function performSizeDown(w)
	local wTop = WindowManager.getTopWindow(w);
	local sClass = wTop.getClass();
	if sClass == "imagebackpanel" then
		ImageManager.sendBackPanelToWindow();
	elseif sClass == "imagemaxpanel" then
		ImageManager.sendMaxPanelToBackPanel();
	elseif sClass == "imagefullpanel" then
		ImageManager.sendFullPanelToMaxPanel();
	end
end

-- Registration functions

local _tImages = {};
function registerImage(cImage)
	table.insert(_tImages, cImage);
	ImageManager.onImageInit(cImage);
end
function unregisterImage(cImage)
	ImageManager.onImageClose(cImage);
	for k, v in ipairs(_tImages) do
		if v == cImage then
			table.remove(_tImages, k);
			return;
		end
	end
end
function getActiveImages()
	return _tImages;
end

-- Drop handling

function addStandardDropHandlers()
	ImageManager.registerDropCallback("shortcut", ImageManager.onImageShortcutDrop);
	ImageManager.registerDropCallback("combattrackerff", ImageManager.onImageCTFactionDrop);
	ImageManager.registerDropCallback("token", ImageManager.onImageTokenDrop);
end

local _tDropCallbacks = {};
function registerDropCallback(sDropType, fn)
	UtilityManager.registerKeyCallback(_tDropCallbacks, sDropType, fn);
end
function unregisterDropCallback(sDropType, fn)
	UtilityManager.unregisterKeyCallback(_tDropCallbacks, sDropType, fn);
end

function onImageShortcutDrop(cImage, x, y, draginfo)
	if (draginfo.getTokenData() or "") ~= "" then
		return ImageManager.onImageTokenDrop(cImage, x, y, draginfo);
	end
end
function onImageCTFactionDrop(cImage, x, y, draginfo)
	return CombatManager.handleFactionDropOnImage(draginfo, cImage, x, y);
end
function onImageTokenDrop(cImage, x, y, draginfo)
	local sClass,sRecord = draginfo.getShortcutData();
	if ((sClass or "") == "") or ((sRecord or "") == "") then
		return;
	end
	x, y = cImage.snapToGrid(x, y);

	local sRecordType = ActorManager.getRecordType(sRecord);
	if not CombatRecordManager.hasRecordTypeCallback(sRecordType) then
		return;
	end

	local nodeCT = CombatManager.getCTFromNode(sRecord);
	if nodeCT then
		local tokenMap = CombatManager.addTokenFromCT(cImage.getDatabaseNode(), nodeCT, x, y);
		CombatManager.replaceCombatantToken(nodeCT, tokenMap);
	else
		local tCustom = {
			sClass = sClass,
			sRecord = sRecord,
			sToken = draginfo.getTokenData(),
			tPlacement = {
				imagelink = DB.getPath(cImage.getDatabaseNode()),
				imagex = x,
				imagey = y,
			},
			draginfo = draginfo,
		};
		CombatRecordManager.onRecordTypeEvent(sRecordType, tCustom);
	end

	return true;
end

-- Event handlers

function onImageTargetSelect(cImage, tTargets)
	local aSelected = cImage.getSelectedTokens();
	if #aSelected == 0 then
		local tokenActive = TargetingManager.getActiveToken(cImage);
		if tokenActive then
			local bAllTargeted = true;
			for _,vToken in ipairs(tTargets) do
				if not vToken.isTargetedBy(tokenActive) then
					bAllTargeted = false;
					break;
				end
			end

			for _,vToken in ipairs(tTargets) do
				tokenActive.setTarget(not bAllTargeted, vToken);
			end
			return true;
		end
	end
end
function onImageDrop(cImage, x, y, draginfo)
	if UtilityManager.performKeyCallbacks(_tDropCallbacks, draginfo.getType(), cImage, x, y, draginfo) then
		return true;
	end
end

-- Helpers

-- NOTE: Returns cImage, wImage, bWindowOpened
function getImageControl(tokenMap, bOpen)
	if not tokenMap then
		return nil, nil, false;
	end
	local nodeImage = tokenMap.getContainerNode();
	if not nodeImage then
		return nil, nil, false;
	end
	local vNodeImageRecord = DB.getParent(nodeImage);
	if not vNodeImageRecord then
		return nil, nil, false;
	end
	local sRecord = DB.getPath(vNodeImageRecord);

	local wBackPanel = ImageManager.getBackPanel();
	if ImageManager.isPanelDataValue(wBackPanel, sRecord) then
		return wBackPanel.sub.subwindow.image, wBackPanel.sub.subwindow, false;
	end
	local wMaxPanel = ImageManager.getMaxPanel();
	if ImageManager.isPanelDataValue(wMaxPanel, sRecord) then
		return wMaxPanel.sub.subwindow.image, wMaxPanel.sub.subwindow, false;
	end
	local wFullPanel = ImageManager.getFullPanel();
	if ImageManager.isPanelDataValue(wFullPanel, sRecord) then
		return wFullPanel.sub.subwindow.image, wFullPanel.sub.subwindow, false;
	end
	local w = Interface.findWindow("imagewindow", sRecord);
	if w then
		if bOpen then
			w.bringToFront();
		end
		return w.image, w, false;
	end
	if bOpen then
		local w = RecordManager.openRecordWindow("image", sRecord);
		if w then
			return w.image, w, true;
		end
	end
	return nil, nil, false;
end
function centerOnToken(tokenMap, bOpen)
	if not tokenMap then
		return false;
	end
	local cImage = ImageManager.getImageControl(tokenMap, bOpen);
	if not cImage then
		return false;
	end
	local x,y = tokenMap.getPosition();
	cImage.setViewpoint(x,y);
	cImage.clearSelectedTokens();
	cImage.selectToken(tokenMap);
	return true;
end
function selectToken(tokenMap)
	if not tokenMap then
		return false;
	end
	local cImage = ImageManager.getImageControl(tokenMap);
	if not cImage then
		return false;
	end
	cImage.clearSelectedTokens();
	cImage.selectToken(tokenMap);
end
