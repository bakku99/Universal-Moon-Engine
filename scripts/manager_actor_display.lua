--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	ActorDisplayManager.setDisplayCallback("name", "", ActorDisplayManager.addActorDisplayName);

	ActorDisplayManager.setDisplayCallback("health", "combatlist", ActorDisplayManager.addActorDisplayHealth);
	ActorDisplayManager.setDisplayCallback("effects", "combatlist", ActorDisplayManager.addActorDisplayEffects);

	ActorDisplayManager.setDisplayCallback("health", "tokenhover", ActorDisplayManager.addActorDisplayHealth);
	ActorDisplayManager.setDisplayCallback("effects", "tokenhover", ActorDisplayManager.addActorDisplayEffects);
	ActorDisplayManager.setDisplayCallback("height", "tokenhover", ActorDisplayManager.addActorDisplayHeight);

	ActorDisplayManager.setDisplayCallback("health", "tokenviewer", ActorDisplayManager.addActorDisplayHealth);
	ActorDisplayManager.setDisplayCallback("effects", "tokenviewer", ActorDisplayManager.addActorDisplayEffects);
	ActorDisplayManager.setDisplayCallback("distance", "tokenviewer", ActorDisplayManager.addActorDisplayDistance);

	ActorDisplayManager.setDisplayCallback("distance", "tokenmove", ActorDisplayManager.addActorDisplayDistance);
end
function onTabletopInit()
	ActorDisplayManager.addStandardTokenDisplay();
	ActorDisplayManager.addStandardNameDisplay();
	ActorDisplayManager.addEffectTracking();
	Token.addEventHandler("onHover", ActorDisplayManager.onTokenHover);
end

--
--	REGISTRATIONS
--

local _tDisplayControls = {};
function addDisplayControl(c, sDisplayType, rActor, tCustom)
	if not c then
		return;
	end

	_tDisplayControls[c] = {
		sDisplayType = sDisplayType,
		sActorPath = ActorManager.getCreatureNodeName(rActor),
		tCustom = tCustom,
	};
	ActorDisplayManager.updateDisplay("", sDisplayType, c, rActor, tCustom);
	c.notifyActorDisplayManagerOnClose();
end
function removeDisplayControl(c)
	_tDisplayControls[c] = nil;
end
function updateActorDisplayControls(sDisplaySet, rActor, tokenMap)
	local sActorPath = ActorManager.getCreatureNodeName(rActor);
	if (sActorPath or "") ~= "" then
		for c,tData in pairs(_tDisplayControls) do
			if sActorPath == tData.sActorPath then
				ActorDisplayManager.updateDisplay(sDisplaySet, tData.sDisplayType, c, rActor, tData.tCustom);
			end
		end
	elseif tokenMap then
		for c,tData in pairs(_tDisplayControls) do
			if tData.tCustom and tData.tCustom.tokenMap == tokenMap then
				ActorDisplayManager.updateDisplay(sDisplaySet, tData.sDisplayType, c, rActor, tData.tCustom);
			end
		end
	end
end
function updateAllActorDisplayControls()
	for c,tData in pairs(_tDisplayControls) do
		ActorDisplayManager.updateDisplay("", tData.sDisplayType, c, ActorManager.resolveActor(tData.sActorPath), tData.tCustom);
	end
end
function getDisplayControlType(c)
	if not c then
		return "";
	end
	if not _tDisplayControls[c] then
		return "";
	end
	return _tDisplayControls[c].sDisplayType or "";
end

local _tDisplaySets = {};
local _tDisplayCallbacks = {};
function setDisplayCallback(sDisplaySet, sDisplayType, fn)
	if not fn then
		return;
	end

	local bFound = false;
	for _,s in ipairs(_tDisplaySets) do
		if s == sDisplaySet then
			bFound = true;
			break;
		end
	end
	if not bFound then
		table.insert(_tDisplaySets, 1, sDisplaySet);
	end

	_tDisplayCallbacks[sDisplaySet] = _tDisplayCallbacks[sDisplaySet] or {};
	_tDisplayCallbacks[sDisplaySet][sDisplayType] = fn;
end
function clearDisplayCallback(sDisplaySet)
	for k,s in ipairs(_tDisplaySets) do
		if s == sDisplaySet then
			table.remove(_tDisplaySets, k);
			break;
		end
	end
	_tDisplayCallbacks[sDisplaySet] = nil;
end
function callDisplayCallbacks(sDisplaySet, sDisplayType, ...)
	if not sDisplayType then
		return;
	end
	for _,s in ipairs(_tDisplaySets) do
		if ((sDisplaySet or "") == "") or (sDisplaySet == s) then
			if _tDisplayCallbacks[s] then
				local fn = _tDisplayCallbacks[s][sDisplayType] or _tDisplayCallbacks[s][""];
				if fn then
					fn(...);
				end
			end
		end
	end
end

--
--	OPTION AND FIELD UPDATES
--

function onOptionChanged()
	ActorDisplayManager.updateAllActorDisplayControls();
	TokenManager.onOptionChanged();
end
function onTokenUpdate(nodeField)
	local nodeActor = DB.getParent(nodeField);
	ActorDisplayManager.updateActorDisplayControls("", ActorManager.resolveActor(nodeActor));
end
function onNameUpdate(nodeField)
	local nodeActor = DB.getParent(nodeField);
	ActorDisplayManager.updateActorDisplayControls("name", ActorManager.resolveActor(nodeActor));
end
function onHealthUpdate(nodeField)
	local nodeActor = DB.getParent(nodeField);
	ActorDisplayManager.updateActorDisplayControls("health", ActorManager.resolveActor(nodeActor));
	TokenManager.updateHealth(nodeField);
end

function addStandardTokenDisplay()
	CombatManager.addAllCombatantFieldChangeHandler("token", "onUpdate", ActorDisplayManager.onTokenUpdate);
end
function addStandardNameDisplay()
	DB.addHandler("charsheet.*.name", "onUpdate", ActorDisplayManager.onNameUpdate);
	CombatManager.addAllCombatantFieldChangeHandler("name", "onUpdate", ActorDisplayManager.onNameUpdate);
	CombatManager.addAllCombatantFieldChangeHandler("nonid_name", "onUpdate", ActorDisplayManager.onNameUpdate);
	CombatManager.addAllCombatantFieldChangeHandler("isidentified", "onUpdate", ActorDisplayManager.onNameUpdate);
end
function addDefaultHealthFeatures(tHealthFields)
	for _,sField in ipairs(tHealthFields) do
		CombatManager.addCombatantFieldChangeHandler(sField, "onUpdate", ActorDisplayManager.onHealthUpdate);
	end

	OptionsManager.registerOptionData({
		sKey = "TGMH", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_bar|option_val_barhover|option_val_dot|option_val_dothover",
			values = "bar|barhover|dot|dothover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "dot",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "TNPCH", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_bar|option_val_barhover|option_val_dot|option_val_dothover",
			values = "bar|barhover|dot|dothover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "dot",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "TPCH", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_bar|option_val_barhover|option_val_dot|option_val_dothover",
			values = "bar|barhover|dot|dothover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "dot",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "WNDC", sGroupRes = "option_header_combat",
		tCustom = {
			labelsres = "option_val_detailed",
			values = "detailed",
			baselabelres = "option_val_simple",
			baseval = "off",
			default = "off",
		},
	});

	DB.addHandler("options.TGMH", "onUpdate", ActorDisplayManager.onOptionChanged);
	DB.addHandler("options.TNPCH", "onUpdate", ActorDisplayManager.onOptionChanged);
	DB.addHandler("options.TPCH", "onUpdate", ActorDisplayManager.onOptionChanged);
	DB.addHandler("options.WNDC", "onUpdate", ActorDisplayManager.onOptionChanged);
end
function addDefaultEffectFeatures()
	OptionsManager.registerOptionData({
		sKey = "TGME", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover",
			values = "on|hover|mark|markhover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "on",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "TNPCE", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover",
			values = "on|hover|mark|markhover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "on",
		},
	});
	OptionsManager.registerOptionData({
		sKey = "TPCE", sGroupRes = "option_header_token",
		tCustom = {
			labelsres = "option_val_icons|option_val_iconshover|option_val_mark|option_val_markhover",
			values = "on|hover|mark|markhover",
			baselabelres = "option_val_off",
			baseval = "off",
			default = "on",
		},
	});

	DB.addHandler("options.TGME", "onUpdate", ActorDisplayManager.onOptionChanged);
	DB.addHandler("options.TNPCE", "onUpdate", ActorDisplayManager.onOptionChanged);
	DB.addHandler("options.TPCE", "onUpdate", ActorDisplayManager.onOptionChanged);
	DB.addHandler("options.TESZ", "onUpdate", ActorDisplayManager.onOptionChanged);
end

function addEffectTracking()
	CombatManager.setCustomAddCombatantEffectHandler(ActorDisplayManager.updateCTEffects);
	CombatManager.setCustomDeleteCombatantEffectHandler(ActorDisplayManager.updateCTEffects);
	CombatManager.addAllCombatantEffectFieldChangeHandler("isactive", "onAdd", ActorDisplayManager.updateCTEffectsField);
	CombatManager.addAllCombatantEffectFieldChangeHandler("isactive", "onUpdate", ActorDisplayManager.updateCTEffectsField);
	CombatManager.addAllCombatantEffectFieldChangeHandler("isgmonly", "onAdd", ActorDisplayManager.updateCTEffectsField);
	CombatManager.addAllCombatantEffectFieldChangeHandler("isgmonly", "onUpdate", ActorDisplayManager.updateCTEffectsField);
	CombatManager.addAllCombatantEffectFieldChangeHandler("label", "onAdd", ActorDisplayManager.updateCTEffectsField);
	CombatManager.addAllCombatantEffectFieldChangeHandler("label", "onUpdate", ActorDisplayManager.updateCTEffectsField);
end
function updateCTEffectsField(nodeEffectField)
	ActorDisplayManager.updateCTEffects(DB.getChild(nodeEffectField, "...."));
end
function updateCTEffects(nodeCT)
	if TokenManager.isDefaultEffectsEnabled() then
		ActorDisplayManager.updateActorDisplayControls("effects", ActorManager.resolveActor(nodeCT));
	end
	TokenManager.updateEffects(nodeCT);
end

--
--	GENERAL DISPLAY BUILD
--

function updateDisplay(sDisplaySet, sDisplayType, cDisplay, rActor, tCustom)
	if not cDisplay then
		return;
	end

	if (sDisplaySet or "") == "" then
		cDisplay.setAsset(ActorDisplayManager.getDisplayPicture(sDisplayType, rActor, tCustom));
	end

	ActorDisplayManager.callDisplayCallbacks(sDisplaySet, sDisplayType, cDisplay, rActor, tCustom);
end

--
--	STANDARD PICTURE SOURCE HANDLING
--

local _tDisplayPictureSources = {};
function getDisplayPictureSource(sDisplayType)
	if (sDisplayType or "") == "" then
		return "";
	end
	return _tDisplayPictureSources[sDisplayType] or "";
end
function setDisplayPictureSource(sDisplayType, s)
	if (sDisplayType or "") == "" then
		return;
	end
	_tDisplayPictureSources[sDisplayType] = s;
end
function getDisplayPicture(sDisplayType, rActor, tCustom)
	if tCustom and tCustom.tokenMap then
		return tCustom.tokenMap.getPrototype();
	end

	local sPictureType = ActorDisplayManager.getDisplayPictureSource(sDisplayType);
	if (sPictureType == "portrait") and ActorManager.isRecordType(rActor, "charsheet") then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		return "portrait_" .. DB.getName(nodeActor) .. "_charlist";
	end

	return UtilityManager.resolveActorToken(rActor);
end

--
--	STANDARD DISPLAY HANDLERS
--

function addActorDisplayName(cDisplay, rActor)
	if not cDisplay then
		return;
	end
	if not rActor then
		cDisplay.deleteWidget("name");
		cDisplay.deleteWidget("ordinal");
		return;
	end

	local sName = ActorManager.getDisplayName(rActor);
	local nStarts, _, sNumber = string.find(sName, " ?(%d+)$");
	if nStarts then
		sName = string.sub(sName, 1, nStarts - 1);
	end

	local widgetName = cDisplay.findWidget("name");
	if widgetName then
		widgetName.setText(sName);
		widgetName.setTooltipText(sName);
	else
		local sFrame, sFrameOffset = TokenManager.getTokenFrameName();
		local sFont = TokenManager.getTokenFontName();
		local tWidget = {
			name = "name",
			position = "top",
			frame = sFrame,
			frameoffset = sFrameOffset,
			font = sFont,
			text = sName,
			tooltip = sName,
			w = 80,
		};
		if (ActorDisplayManager.getDisplayControlType(cDisplay) == "combatlist") then
			tWidget.w = 70;
		end
		cDisplay.addTextWidget(tWidget);
	end

	if sNumber then
		local widgetOrdinal = cDisplay.findWidget("ordinal");
		if widgetOrdinal then
			widgetOrdinal.setText(sNumber);
		else
			local sFrame, sFrameOffset = TokenManager.getTokenFrameOrdinal();
			local sFont = TokenManager.getTokenFontOrdinal();
			local tWidget = {
				name = "ordinal",
				position = "topright",
				x = -2,
				frame = sFrame,
				frameoffset = sFrameOffset,
				font = sFont,
				text = sNumber,
			};
			cDisplay.addTextWidget(tWidget);
		end
	else
		cDisplay.deleteWidget("ordinal");
	end
end
function addActorDisplayHealth(cDisplay, rActor)
	if not cDisplay then
		return;
	end
	if not TokenManager.isDefaultHealthEnabled() then
		return;
	end
	local nodeCT = ActorManager.getCTNode(rActor);
	if not nodeCT then
		cDisplay.deleteWidget("healthbar");
		cDisplay.deleteWidget("healthdot");
		return;
	end

	local sOptTH;
	if Session.IsHost then
		sOptTH = OptionsManager.getOption("TGMH");
	elseif CombatManager.getFactionFromCT(nodeCT) == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end

	if sOptTH == "bar" or sOptTH == "barhover" then
		cDisplay.deleteWidget("healthdot");

		local widgetHealthBar = cDisplay.findWidget("healthbar");
		if not widgetHealthBar then
			widgetHealthBar = cDisplay.addBitmapWidget({
				name = "healthbar",
				icon = "healthbar",
				position = "right",
				w = TokenManager.TOKEN_HEALTHBAR_WIDTH,
				h = TokenManager.TOKEN_HEALTHBAR_HEIGHT,
			});
		end
		if widgetHealthBar then
			local nPercentWounded, sStatus, sColor = ActorHealthManager.getTokenHealthInfo(rActor);

			widgetHealthBar.setColor(sColor);
			widgetHealthBar.setTooltipText(sStatus);
			widgetHealthBar.setClipRegion(0, nPercentWounded * 100, 100, 100);
		end

	elseif sOptTH == "dot" or sOptTH == "dothover" then
		cDisplay.deleteWidget("healthbar");

		local widgetHealthDot = cDisplay.findWidget("healthdot");
		if not widgetHealthDot then
			local tWidget = {
				name = "healthdot",
				icon = "healthdot",
				position = "bottomright",
				x = TokenManager.TOKEN_HEALTHDOT_HOFFSET,
				y = TokenManager.TOKEN_HEALTHDOT_VOFFSET,
				w = TokenManager.TOKEN_HEALTHDOT_SIZE,
				h = TokenManager.TOKEN_HEALTHDOT_SIZE,
			};
			if ActorDisplayManager.getDisplayControlType(cDisplay) == "combatlist" then
				tWidget.x = CombatListManager.HEALTHDOT_HOFFSET;
				tWidget.y = CombatListManager.HEALTHDOT_VOFFSET;
			end
			widgetHealthDot = cDisplay.addBitmapWidget(tWidget);
		end
		if widgetHealthDot then
			local _, sStatus, sColor = ActorHealthManager.getTokenHealthInfo(rActor);

			widgetHealthDot.setColor(sColor);
			widgetHealthDot.setTooltipText(sStatus);
		end
	else
		cDisplay.deleteWidget("healthbar");
		cDisplay.deleteWidget("healthdot");
	end
end
function addActorDisplayEffects(cDisplay, rActor)
	if not cDisplay or not rActor then
		return;
	end
	if not TokenManager.isDefaultEffectsEnabled() then
		return;
	end
	local nodeCT = ActorManager.getCTNode(rActor);
	if not nodeCT then
		for i = 1, TokenManager.TOKEN_MAX_EFFECTS do
			cDisplay.deleteWidget("effect" .. i);
		end
		return;
	end

	local sOptTE;
	if Session.IsHost then
		sOptTE = OptionsManager.getOption("TGME");
	elseif ActorManager.getFaction(rActor) == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
	end

	local nPositionAdjX = 0;
	local nPositionAdjY = 0;
	local bCombatListDisplay = (ActorDisplayManager.getDisplayControlType(cDisplay) == "combatlist");
	if bCombatListDisplay then
		nPositionAdjX = -5;
		nPositionAdjY = 5;
	end

	if sOptTE == "off" then
		for i = 1, TokenManager.TOKEN_MAX_EFFECTS do
			cDisplay.deleteWidget("effect" .. i);
		end
	elseif sOptTE == "mark" or sOptTE == "markhover" then
		local tTooltip = {};
		local tCondList = TokenManager.getDefaultEffectInfoFunction()(nodeCT);
		for _,v in ipairs(tCondList) do
			table.insert(tTooltip, v.sEffect);
		end

		if #tTooltip > 0 then
			local w = cDisplay.findWidget("effect1");
			if not w then
				local tWidget = {
					name = "effect1",
					icon = "cond_generic",
				};
				w = cDisplay.addBitmapWidget(tWidget);
			else
				w.setBitmap("cond_generic");
			end
			if w then
				local nEffectSize = TokenManager.TOKEN_EFFECT_SIZE_STANDARD;
				w.setTooltipText(table.concat(tTooltip, "\r"));
				w.setPosition("topleft", (nEffectSize / 2) + nPositionAdjX, 10 + (nEffectSize / 2) + nPositionAdjY);
				w.setSize(nEffectSize, nEffectSize);
			end
			for i = 2, TokenManager.TOKEN_MAX_EFFECTS do
				cDisplay.deleteWidget("effect" .. i);
			end
		else
			for i = 1, TokenManager.TOKEN_MAX_EFFECTS do
				cDisplay.deleteWidget("effect" .. i);
			end
		end
	else
		local tCondList = TokenManager.getDefaultEffectInfoFunction()(nodeCT);
		local nConds = #tCondList;

		local wLast = nil;
		local posy = 10;
		local nEffectSize = TokenManager.TOKEN_EFFECT_SIZE_STANDARD;
		local nMaxLoop = math.min(nConds, TokenManager.TOKEN_MAX_EFFECTS);
		local i = 1;
		while i <= nMaxLoop do
			local tWidget = {
				name = "effect" .. i,
				icon = tCondList[i].sIcon,
				position ="topleft",
				x = (nEffectSize / 2) + nPositionAdjX,
				y = posy + (nEffectSize / 2) + nPositionAdjY,
				w = nEffectSize, h = nEffectSize,
				tooltip = tCondList[i].sEffect,
			};
			wLast = cDisplay.findWidget("effect" .. i);
			if not wLast then
				wLast = cDisplay.addBitmapWidget(tWidget);
			else
				wLast.setBitmap(tWidget.icon);
				wLast.setTooltipText(tWidget.tooltip);
			end
			posy = posy + nEffectSize + TokenManager.TOKEN_EFFECT_MARGIN;
			i = i + 1;
		end
		if wLast and (nConds > TokenManager.TOKEN_MAX_EFFECTS) then
			wLast.setBitmap("cond_more");
			local tTooltip = {};
			table.insert(tTooltip, wLast.getTooltipText());
			for j = i, nConds do
				table.insert(tTooltip, tCondList[j].sEffect);
			end
			wLast.setTooltipText(table.concat(tTooltip, "\r"));
		end
		while i <= TokenManager.TOKEN_MAX_EFFECTS do
			cDisplay.deleteWidget("effect" .. i);
			i = i + 1;
		end
	end
end

function addActorDisplayHeight(cDisplay, _, tCustom)
	if not cDisplay or not tCustom or not tCustom.tokenMap then
		return;
	end
	local nHeight = tCustom.tokenMap.getHeight();
	if nHeight == 0 then
		return;
	end

	local sFontPositive, sFontNegative = TokenManager.getTokenFontsHeight();
	local widgetHeight = cDisplay.findWidget("height");
	if not widgetHeight then
		local sFrame, sFrameOffset = TokenManager.getTokenFrameHeight();
		local tWidget = {
			name = "height",
			position = "bottom",
			y = -5,
			frame = sFrame,
			frameoffset = sFrameOffset,
			font = sFontPositive,
			text = "",
		};
		widgetHeight = cDisplay.addTextWidget(tWidget);
	end

	local nGridSize = TokenManager.getImageGridSize(tCustom.tokenMap);
	if nHeight > 0 then
		nHeight = math.ceil((nHeight / nGridSize) - 0.25);
		widgetHeight.setFont(sFontPositive);
	else
		nHeight = math.floor((nHeight / nGridSize) + 0.25);
		widgetHeight.setFont(sFontNegative or sFontPositive);
	end
	local nBase, sSuffix = TokenManager.getImageGridUnits(tCustom.tokenMap);
	widgetHeight.setText(string.format("%+d%s", nHeight * nBase, sSuffix));
end

function addActorDisplayDistance(cDisplay, _, tCustom)
	if not cDisplay or not tCustom or not tCustom.tokenMap then
		return;
	end

	local nDistance = Token.getPlannedMovementDistance(tCustom.tokenMap);
	if nDistance == 0 then
		cDisplay.deleteWidget("distance");
		return
	end

	local widgetDistance = cDisplay.findWidget("distance");
	if not widgetDistance then
		local sFontPositive, _ = TokenManager.getTokenFontsHeight();
		local sFrame, sFrameOffset = TokenManager.getTokenFrameHeight();
		local tWidget = {
			name = "distance",
			position = "bottom",
			y = -15,
			frame = sFrame,
			frameoffset = sFrameOffset,
			font = sFontPositive,
			text = "",
		};
		widgetDistance = cDisplay.addTextWidget(tWidget);
	end

	local nBase, sSuffix = TokenManager.getImageGridUnits(tCustom.tokenMap);
	widgetDistance.setText(string.format("%d%s", nDistance * nBase, sSuffix));
end

--
--	IMAGE TOKEN HOVER HANDLING
--

function onTokenHover(tokenMap, bHover)
	local cImage = ImageManager.getActiveImageFromToken(tokenMap);
	if not cImage then
		return;
	end
	if cImage.getViewToken() == tokenMap then
		ActorDisplayManager.setImageHoverTokenDetail(cImage.window, nil, bHover);
	else
		ActorDisplayManager.setImageHoverTokenDetail(cImage.window, tokenMap, bHover);
	end
end
function setImageHoverTokenDetail(wImage, tokenMap, bHover)
	if not wImage then
		return;
	end
	local cSubDetail = wImage.sub_hover_token_detail;
	if not cSubDetail then
		return;
	end

	local bShow = tokenMap and bHover;
	if bShow then
		local iw, ih = wImage.image.getSize();
		local cw = cSubDetail.getAnchoredWidth();
		local ch = cSubDetail.getAnchoredHeight();
		if (cw * 4 > iw) or (ch * 4 > ih) then
			bShow = false;
		end
	end

	if bShow then
		cSubDetail.setValue("image_hover_token_detail", "");
		cSubDetail.setVisible(true);
		local rActor = ActorManager.resolveActor(tokenMap);
		ActorDisplayManager.addDisplayControl(cSubDetail.subwindow.display, "tokenhover", rActor, { tokenMap = tokenMap });
	else
		cSubDetail.setValue("", "");
		cSubDetail.setVisible(false);
	end
end
function setImageViewTokenDetail(wImage, tokenMap)
	if not wImage then
		return;
	end
	local cSubDetail = wImage.sub_view_token_detail;
	if not cSubDetail then
		return;
	end

	local bShow = tokenMap and true;
	if bShow then
		local iw, ih = wImage.image.getSize();
		local cw = cSubDetail.getAnchoredWidth();
		local ch = cSubDetail.getAnchoredHeight();
		if (cw * 2 > iw) or (ch * 2 > ih) then
			bShow = false;
		end
	end

	if bShow then
		cSubDetail.setValue("image_view_token_detail", "");
		cSubDetail.setVisible(true);
		local rActor = ActorManager.resolveActor(tokenMap);
		ActorDisplayManager.addDisplayControl(cSubDetail.subwindow.display, "tokenviewer", rActor, { tokenMap = tokenMap });
		TokenMoveManager.updateViewTokenMove(tokenMap);
	else
		cSubDetail.setValue("", "");
		cSubDetail.setVisible(false);
	end
end
