--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	OptionsManager.setOptionDefault("INITIND", "images/Initiative/Default.webm@SmiteWorks Assets")
end
function onTabletopInit()
	if Session.IsHost then
		Token.addEventHandler("onContainerChanged", TokenManager.onContainerChanged);
		Token.addEventHandler("onTargetUpdate", TokenManager.onTargetUpdate);
		User.addEventHandler("onIdentityStateChange", TokenManager.onIdentityStateChange);

		CombatManager.setCustomDeleteCombatantHandler(TokenManager.onCombatantDelete);
		CombatManager.addAllCombatantFieldChangeHandler("space", "onUpdate", TokenManager.updateSpaceReach);
		CombatManager.addAllCombatantFieldChangeHandler("reach", "onUpdate", TokenManager.updateSpaceReach);
	end
	DB.addHandler("charsheet.*", "onDelete", TokenManager.deleteOwner);
	DB.addHandler("charsheet.*", "onObserverUpdate", TokenManager.updateOwner);

	Token.addEventHandler("onAdd", TokenManager.onTokenAdd);
	Token.addEventHandler("onMove", TokenManager.onMove);
	Token.addEventHandler("onDelete", TokenManager.onTokenDelete);
	Token.addEventHandler("onDrop", TokenManager.onDrop);
	Token.addEventHandler("onDoubleClick", TokenManager.onDoubleClick);
	Token.addEventHandler("onWheel", TokenManager.onWheel);
	Token.addEventHandler("onHover", TokenManager.onHover);

	CombatManager.addAllCombatantFieldChangeHandler("tokenrefid", "onUpdate", TokenManager.updateAttributes);
	CombatManager.addAllCombatantFieldChangeHandler("friendfoe", "onUpdate", TokenManager.updateFaction);
	CombatManager.addAllCombatantFieldChangeHandler("name", "onUpdate", TokenManager.updateName);
	CombatManager.addAllCombatantFieldChangeHandler("nonid_name", "onUpdate", TokenManager.updateName);
	CombatManager.addAllCombatantFieldChangeHandler("isidentified", "onUpdate", TokenManager.updateName);
	CombatManager.addAllCombatantFieldChangeHandler("active", "onUpdate", TokenManager.updateActive);

	TokenManager.initOptionTracking();
end

function onImageInit(cImage)
	for _,token in ipairs(cImage.getTokens()) do
		TokenManager.updateAttributesFromToken(token);
	end
end
function onImageClose(_)
end

--
--	Theming
--

local _sFrameName = "token_name";
local _sFrameOffsetName = "4,1,4,1";
local _sFontName = "token_name";
function setTokenFrameName(sFrame, sFrameOffset)
	_sFrameName = sFrame;
	_sFrameOffsetName = sFrameOffset;
end
function getTokenFrameName()
	return _sFrameName, _sFrameOffsetName;
end
function setTokenFontName(sFont)
	_sFontName = sFont;
end
function getTokenFontName()
	return _sFontName;
end

local _sFrameOrdinal = "token_ordinal";
local _sFrameOffsetOrdinal = "7,1,7,1";
local _sFontOrdinal = "token_ordinal";
function setTokenFrameOrdinal(sFrame, sFrameOffset)
	_sFrameOrdinal = sFrame;
	_sFrameOffsetOrdinal = sFrameOffset;
end
function getTokenFrameOrdinal()
	return _sFrameOrdinal, _sFrameOffsetOrdinal;
end
function setTokenFontOrdinal(sFont)
	_sFontOrdinal = sFont;
end
function getTokenFontOrdinal()
	return _sFontOrdinal;
end

local _sFrameHeight = "token_height";
local _sFrameOffsetHeight = "5,1,5,1";
local _sFontHeightPositive = "token_height";
local _sFontHeightNegative = "token_height_negative";
function setTokenFrameHeight(sFrame, sFrameOffset)
	_sFrameHeight = sFrame;
	_sFrameOffsetHeight = sFrameOffset;
end
function getTokenFrameHeight()
	return _sFrameHeight, _sFrameOffsetHeight;
end
function setTokenFontsHeight(sPositiveFont, sNegativeFont)
	_sFontHeightPositive = sPositiveFont;
	_sFontHeightNegative = sNegativeFont;
end
function getTokenFontsHeight()
	return _sFontHeightPositive, _sFontHeightNegative;
end

--
--	Other Customization Handlers
--

local fCustomGetReachUnderlayGridUnits = nil;
function setCustomGetReachUnderlayGridUnits(fn)
	fCustomGetReachUnderlayGridUnits = fn;
end
function getReachUnderlayGridUnits(nodeCT)
	if fCustomGetReachUnderlayGridUnits then
		return fCustomGetReachUnderlayGridUnits(nodeCT);
	end
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	return math.ceil(DB.getValue(nodeCT, "reach", nDU) / nDU);
end

--
--  Internal Behaviors
--

function linkToken(nodeCT, newTokenInstance)
	local nodeContainer = nil;
	if newTokenInstance then
		nodeContainer = newTokenInstance.getContainerNode();
	end

	if nodeContainer then
		DB.setValue(nodeCT, "tokenrefnode", "string", DB.getPath(nodeContainer));
		DB.setValue(nodeCT, "tokenrefid", "string", newTokenInstance.getId());
	else
		DB.setValue(nodeCT, "tokenrefnode", "string", "");
		DB.setValue(nodeCT, "tokenrefid", "string", "");
	end

	return true;
end

function initOptionTracking()
	if Session.IsHost then
		DB.addHandler("options.TFAC", "onUpdate", TokenManager.onOptionChanged);
	end
	DB.addHandler("options.TPTY", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.TNAM", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.INITIND", "onUpdate", TokenManager.onOptionChanged);
end
function onOptionChanged()
	for _,nodeCT in pairs(CombatManager.getAllCombatantNodes()) do
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			TokenManager.updateAttributesHelper(tokenCT, nodeCT);
		end
	end
end

function getImageGridSize(token)
	if not token then
		return nil;
	end
	local nodeImage = token.getContainerNode();
	return Image.getGridSize(nodeImage);
end
function getImageGridUnits(token)
	if not token then
		return nil;
	end
	local nodeImage = token.getContainerNode();
	return Image.getDistanceBaseUnits(nodeImage), Image.getDistanceSuffix(nodeImage);
end
function getImageTokenLockState(token)
	if not token then
		return nil;
	end
	local nodeImage = token.getContainerNode();
	return Image.getTokenLockState(nodeImage);
end

function onCombatantDelete(nodeCT)
	if TokenManager2 and TokenManager2.onCombatantDelete then
		if TokenManager2.onCombatantDelete(nodeCT) then
			return;
		end
	end

	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		tokenCT.delete();
	end
end
function onTokenAdd(tokenMap, bLoad)
	TokenManager.updateAttributesFromToken(tokenMap);
	if not bLoad then
		TokenManager.autoTokenScale(tokenMap);
	end
end
function onMove(tokenMap)
	TokenManager.updateHeightHelper(tokenMap);
end
function onTokenDelete(tokenMap)
	if Session.IsHost then
		CombatManager.onTokenDelete(tokenMap);
	end
end
function onContainerChanged(tokenCT, nodeOldContainer, nOldId)
	if nodeOldContainer then
		local nodeCT = CombatManager.getCTFromTokenRef(nodeOldContainer, nOldId);
		if nodeCT then
			local nodeNewContainer = tokenCT.getContainerNode();
			if nodeNewContainer then
				DB.setValue(nodeCT, "tokenrefnode", "string", DB.getPath(nodeNewContainer));
				DB.setValue(nodeCT, "tokenrefid", "string", tokenCT.getId());
			else
				DB.setValue(nodeCT, "tokenrefnode", "string", "");
				DB.setValue(nodeCT, "tokenrefid", "string", "");
			end
			TokenManager.onTokenAdd(tokenCT);
		end
	end
end
function onTargetUpdate(tokenMap)
	TargetingManager.onTargetUpdate(tokenMap);
end

function onWheelCT(nodeCT, notches)
	local bControl = Input.isControlPressed();
	local bAlt = Input.isAltPressed();
	if bControl or bAlt then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			if bControl then
				TokenManager.onWheelHelper(tokenCT, notches);
				return true;
			end
			if bAlt then
				TokenManager.onWheelHeightHelper(tokenCT, notches);
				return true;
			end
		end
	end
	return false;
end
function onWheelHelper(tokenCT, notches)
	if not tokenCT then
		return;
	end

	local newscale = tokenCT.getScale();
	local adj = notches * 0.1;
	if adj < 0 then
		newscale = newscale * (1 + adj);
	else
		newscale = newscale * (1 / (1 - adj));
	end
	tokenCT.setScale(newscale);
end
function onWheelHeightHelper(tokenCT, notches)
	if not tokenCT then
		return;
	end

	local nGridSize = TokenManager.getImageGridSize(tokenCT);
	tokenCT.setHeight(tokenCT.getHeight() + (notches * nGridSize));
end

function onDrop(tokenCT, draginfo)
	local nodeCT = CombatManager.getCTFromToken(tokenCT);
	if nodeCT then
		return CombatDropManager.handleAnyDrop(draginfo, DB.getPath(nodeCT));
	else
		if draginfo.getType() == "targeting" then
			ChatManager.SystemMessage(Interface.getString("ct_error_targetingunlinkedtoken"));
			return true;
		end
	end
end
function onDoubleClick(tokenMap, vImage)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if Session.IsHost then
			local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
			if sRecord ~= "" then
				Interface.openWindow(sClass, sRecord);
			else
				Interface.openWindow(sClass, nodeCT);
			end
		else
			if CombatManager.getFactionFromCT(nodeCT) == "friend" then
				local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
				if sClass == "charsheet" then
					if sRecord ~= "" and DB.isOwner(sRecord) then
						Interface.openWindow(sClass, sRecord);
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openpclinkedtokenwithoutaccess"));
					end
				else
					local nodeActor;
					if sRecord ~= "" then
						nodeActor = DB.findNode(sRecord);
					else
						nodeActor = nodeCT;
					end
					if nodeActor then
						Interface.openWindow(sClass, nodeActor);
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openotherlinkedtokenwithoutaccess"));
					end
				end
				vImage.clearSelectedTokens();
			end
		end
	end
end
function onWheel(tokenMap, notches)
	if Input.isAltPressed() then
		local bAllow;
		if Session.IsHost then
			bAllow = true;
		else
			local nodeCT = CombatManager.getCTFromToken(tokenMap);
			if nodeCT then
				bAllow = Token.isOwner(tokenMap);
			else
				bAllow = true;
			end
		end
		if bAllow then
			TokenManager.onWheelHeightHelper(tokenMap, notches);
			return true;
		end
	end
end
function onHover(tokenMap, bOver)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if OptionsManager.isOption("TNAM", "hover") then
			local widgetName = tokenMap.findWidget("name");
			if widgetName then
				widgetName.setVisible(bOver);
			end
			local widgetOrdinal = tokenMap.findWidget("ordinal");
			if widgetOrdinal then
				widgetOrdinal.setVisible(bOver);
			end
		end
		if TokenManager.isDefaultHealthEnabled() then
			local sOption;
			if Session.IsHost then
				sOption = OptionsManager.getOption("TGMH");
			elseif CombatManager.getFactionFromCT(nodeCT) == "friend" then
				sOption = OptionsManager.getOption("TPCH");
			else
				sOption = OptionsManager.getOption("TNPCH");
			end
			if (sOption == "barhover") or (sOption == "dothover") then
				local widgetHealthBar = tokenMap.findWidget("healthbar");
				if widgetHealthBar then
					widgetHealthBar.setVisible(bOver);
				end
				local widgetHealthDot = tokenMap.findWidget("healthdot");
				if widgetHealthDot then
					widgetHealthDot.setVisible(bOver);
				end
			end
		end
		if TokenManager.isDefaultEffectsEnabled() then
			local sOption;
			if Session.IsHost then
				sOption = OptionsManager.getOption("TGME");
			elseif CombatManager.getFactionFromCT(nodeCT) == "friend" then
				sOption = OptionsManager.getOption("TPCE");
			else
				sOption = OptionsManager.getOption("TNPCE");
			end
			if (sOption == "hover") or (sOption == "markhover") then
				for i = 1, TokenManager.TOKEN_MAX_EFFECTS do
					local wgt = tokenMap.findWidget("effect" .. i);
					if wgt then
						wgt.setVisible(bOver);
					end
				end
			end
		end
	end
end
function onIdentityStateChange(sIdentity, sUser, sStateName)
	if sStateName == "color" and sUser ~= "" then
		for _,nodeCT in ipairs(CombatManager.getAllCombatantNodes()) do
			local token = CombatManager.getTokenFromCT(nodeCT);
			if token then
				local rActor = ActorManager.resolveActor(nodeCT);
				if rActor and ActorManager.isPC(rActor) then
					local nodeCreature = ActorManager.getCreatureNode(rActor);
					if nodeCreature then
						local sTokenIdentity = DB.getName(nodeCreature);
						if sTokenIdentity == sIdentity then
							TokenManager.updateTokenColor(token);
						end
					end
				end
			end
		end
	end
end

function updateAttributesFromToken(tokenMap)
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		TokenManager.updateAttributesHelper(tokenMap, nodeCT);
	else
		TokenManager.updateHeightHelper(tokenMap);
	end
end
function updateAttributes(nodeField)
	local nodeCT = DB.getParent(nodeField);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateAttributesHelper(tokenCT, nodeCT);
	end
end
function updateAttributesHelper(tokenCT, nodeCT)
	if Session.IsHost then
		if OptionsManager.isOption("TFAC", "on") then
			tokenCT.setOrientationMode("facing");
		else
			tokenCT.setOrientationMode();
		end

		TokenManager.updateFactionHelper(tokenCT, nodeCT);
		TokenManager.updateSizeHelper(tokenCT, nodeCT);

		VisionManager.updateTokenVisionHelper(tokenCT, nodeCT);
		VisionManager.updateTokenLightingHelper(tokenCT, nodeCT);
	end
	TokenManager.updateActiveHelper(tokenCT, nodeCT);
	TokenManager.updateOwnerHelper(tokenCT, nodeCT);

	TokenManager.updateNameHelper(tokenCT, nodeCT);
	TokenManager.updateTooltip(tokenCT, nodeCT);
	TokenManager.updateHeightHelper(tokenCT);
	if TokenManager.isDefaultHealthEnabled() then
		TokenManager.updateHealthHelper(tokenCT, nodeCT);
	end
	if TokenManager.isDefaultEffectsEnabled() then
		TokenManager.updateEffectsHelper(tokenCT, nodeCT);
	end
	if TokenManager2 and TokenManager2.updateAttributesHelper then
		TokenManager2.updateAttributesHelper(tokenCT, nodeCT);
	end
end
function updateTooltip(tokenCT, nodeCT)
	if TokenManager2 and TokenManager2.updateTooltip then
		TokenManager2.updateTooltip(tokenCT, nodeCT);
		return;
	end

	if Session.IsHost then
		local tTooltip = {};
		local sOptTNAM = OptionsManager.getOption("TNAM");
		if sOptTNAM == "tooltip" then
			local sName = ActorManager.getDisplayName(nodeCT);
			table.insert(tTooltip, sName);
		end

		tokenCT.setName(table.concat(tTooltip, "\r"));
	end
end

function updateName(nodeName)
	local nodeCT = DB.getParent(nodeName);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateNameHelper(tokenCT, nodeCT);
		TokenManager.updateTooltip(tokenCT, nodeCT);
	end
	ActorDisplayManager.updateActorDisplayControls("name", ActorManager.resolveActor(nodeCT));
end
function updateNameHelper(tokenCT, nodeCT)
	local sOptTNAM = OptionsManager.getOption("TNAM");

	if sOptTNAM == "off" or sOptTNAM == "tooltip" then
		tokenCT.deleteWidget("name");
		tokenCT.deleteWidget("ordinal");
		return;
	end

	local sOptTASG = OptionsManager.getOption("TASG");
	local sName = ActorManager.getDisplayName(nodeCT);
	local nStarts, _, sNumber = string.find(sName, " ?(%d+)$");
	if nStarts then
		sName = string.sub(sName, 1, nStarts - 1);
	end

	local bWidgetsVisible = (sOptTNAM == "on");
	local widgetName = tokenCT.findWidget("name");
	if not widgetName then
		local sFrame, sFrameOffset = TokenManager.getTokenFrameName();
		local sFont = TokenManager.getTokenFontName();
		local tWidget = {
			name = "name",
			position = "top",
			frame = sFrame,
			frameoffset = sFrameOffset,
			font = sFont,
			text = "",
		};
		if sOptTASG == "80" then
			tWidget.y = -5;
		end
		widgetName = tokenCT.addTextWidget(tWidget);
	end
	if widgetName then
		widgetName.setText(sName);
		widgetName.setTooltipText(sName);
		widgetName.setVisible(bWidgetsVisible);

		local nSpace = TokenManager.calcTokenSpace(DB.getValue(nodeCT, "space"));
		widgetName.setMaxWidth((100 * nSpace) - (30 * nSpace));
	end

	if sNumber then
		local widgetOrdinal = tokenCT.findWidget("ordinal");
		if not widgetOrdinal then
			local sFrame, sFrameOffset = TokenManager.getTokenFrameOrdinal();
			local sFont = TokenManager.getTokenFontOrdinal();
			local tWidget = {
				name = "ordinal",
				position = "topright",
				frame = sFrame,
				frameoffset = sFrameOffset,
				font = sFont,
				text = "",
			};
			if sOptTASG == "80" then
				tWidget.x = 5;
				tWidget.y = -5;
			end
			widgetOrdinal = tokenCT.addTextWidget(tWidget);
		end
		if widgetOrdinal then
			widgetOrdinal.setText(sNumber);
			widgetOrdinal.setVisible(bWidgetsVisible);
		end
	else
		tokenCT.deleteWidget("ordinal");
	end
end

function updateHeightHelper(tokenMap)
	local widgetHeight = tokenMap.findWidget("height");

	local nHeight = tokenMap.getHeight();
	if nHeight == 0 then
		if widgetHeight then
			widgetHeight.destroy();
		end
		return;
	end

	local sFontPositive, sFontNegative = TokenManager.getTokenFontsHeight();
	if not widgetHeight then
		local sFrame, sFrameOffset = TokenManager.getTokenFrameHeight();
		local tWidget = {
			name = "height",
			position = "bottom",
			frame = sFrame,
			frameoffset = sFrameOffset,
			font = sFontPositive,
			text = "",
		};
		widgetHeight = tokenMap.addTextWidget(tWidget);
	end
	if widgetHeight then
		local nGridSize = TokenManager.getImageGridSize(tokenMap);
		if nHeight > 0 then
			nHeight = math.ceil((nHeight / nGridSize) - 0.25);
			widgetHeight.setFont(sFontPositive);
		else
			nHeight = math.floor((nHeight / nGridSize) + 0.25);
			widgetHeight.setFont(sFontNegative or sFontPositive);
		end
		local nBase, sSuffix = TokenManager.getImageGridUnits(tokenMap);
		widgetHeight.setText(string.format("%+d%s", nHeight * nBase, sSuffix));
	end
end

function updateVisibility(nodeCT)
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateVisibilityHelper(tokenCT, nodeCT);

		local _,bVisibleSetting = tokenCT.isVisible();
		if bVisibleSetting == false then
			TargetingManager.removeCTTargeted(nodeCT);
		end
	else
		if CombatManager.getFactionFromCT(nodeCT) ~= "friend" then
			if not CombatManager.getTokenVisibilityFromCT(nodeCT) then
				TargetingManager.removeCTTargeted(nodeCT);
			end
		end
	end
end
function updateVisibilityHelper(tokenCT, nodeCT)
	if CombatManager.getFactionFromCT(nodeCT) == "friend" then
		if OptionsManager.isOption("TPTY", "on") then
			tokenCT.setVisible(true);
		elseif not Session.IsHost and DB.isOwner(ActorManager.getCreatureNode(nodeCT)) then
			tokenCT.setVisible(true);
		else
			tokenCT.setVisible(nil);
		end
	else
		if CombatManager.getTokenVisibilityFromCT(nodeCT) then
			if tokenCT.isVisible() ~= true then
				tokenCT.setVisible(nil);
			end
		else
			tokenCT.setVisible(false);
		end
	end
end

function deleteOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			if Session.IsHost then
				tokenCT.setOwner();
				TokenManager.updateTokenColor(tokenCT);
			end
		end
	end
end
-- NOTE: Assume registered on host; Only called for PC (charsheet) node owner changes
function updateOwner(nodePC)
	local nodeCT = CombatManager.getCTFromNode(nodePC);
	if nodeCT then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			TokenManager.updateOwnerHelper(tokenCT, nodeCT);
		end
	end
end
function updateOwnerHelper(tokenCT, nodeCT)
	if Session.IsHost then
		local nodeCreature = ActorManager.getCreatureNode(nodeCT);
		tokenCT.setOwner(DB.getOwner(nodeCreature));
		TokenManager.updateTokenColor(tokenCT);
	end
end

function updateActive(nodeField)
	local nodeCT = DB.getParent(nodeField);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateActiveHelper(tokenCT, nodeCT);
	end
end
function updateActiveHelper(tokenCT, nodeCT)
	local bActive = (DB.getValue(nodeCT, "active", 0) == 1);

	local bHasWidget = TokenManager.setActiveWidget(tokenCT, nodeCT, bActive);
	if Session.IsHost then
		if bActive and not bHasWidget then
			tokenCT.setActive(true);
		else
			tokenCT.setActive(false);
		end
	end
end
function setActiveWidget(tokenCT, _, bActive)
	tokenCT.deleteWidget("active");
	tokenCT.deleteWidget("active3D");

	if not bActive then
		return false;
	end

	local tData = TokenManager.getTokenActiveOptions();
	if not tData or ((tData.sAsset or "") == "") then
		return false;
	end

	local nGridSize = TokenManager.getTokenSpace(tokenCT);
	if OptionsManager.isOption("TASG", "100") then
		nGridSize = nGridSize * 1.5;
	else
		nGridSize = nGridSize * 1.2;
	end

	local tWidget = {
		name = "active",
		asset = tData.sAsset,
		w = nGridSize * 100, h = nGridSize * 100,
		displaytype = tData.bOver and "" or "underlay",
		displaymode = "2D",
	};
	local wgt = tokenCT.addBitmapWidget(tWidget);
	if wgt then
		wgt.sendToBack();
	end

	local tWidget3D = {
		name = "active3D",
		asset = tData.sAsset,
		w = nGridSize * 100, h = nGridSize * 100,
		displaytype = "floor",
		displaymode = "3D",
	};
	local wgt3D = tokenCT.addBitmapWidget(tWidget3D);
	if wgt3D then
		wgt3D.sendToBack();
	end
	return true;
end

function getTokenActiveOptions()
	local tData = {
		sAsset = OptionsManager.getOption("INITIND"),
		bOver = false,
	};
	if StringManager.startsWith(tData.sAsset, "over|") then
		tData.sAsset = tData.sAsset:sub(6);
		tData.bOver = true;
	end
	return tData;
end
function setTokenActiveOptions(tData)
	if not tData or ((tData.sAsset or "") == "") then
		OptionsManager.setOption("INITIND", "");
		return;
	end
	if tData.bOver then
		OptionsManager.setOption("INITIND", string.format("over|%s", tData.sAsset));
	else
		OptionsManager.setOption("INITIND", tData.sAsset);
	end
end

function updateFaction(nodeFaction)
	local nodeCT = DB.getParent(nodeFaction);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		if Session.IsHost then
			TokenManager.updateFactionHelper(tokenCT, nodeCT);
		end
		TokenManager.updateTooltip(tokenCT, nodeCT);
		if TokenManager.isDefaultHealthEnabled() then
			TokenManager.updateHealthHelper(tokenCT, nodeCT);
		end
		if TokenManager.isDefaultEffectsEnabled() then
			TokenManager.updateEffectsHelper(tokenCT, nodeCT);
		end
		if TokenManager2 and TokenManager2.updateFaction then
			TokenManager2.updateFaction(tokenCT, nodeCT);
		end
	end
end
function updateFactionHelper(tokenCT, nodeCT)
	local sFaction = CombatManager.getFactionFromCT(nodeCT);

	local bAllowPublicAccess = false;
	if (sFaction == "friend") and OptionsManager.isOption("TPTY", "on") then
		bAllowPublicAccess = true;
	end
	tokenCT.setPublicEdit(bAllowPublicAccess);
	tokenCT.setPublicVision(bAllowPublicAccess);

	local bEnableFOW = false;
	local sOptionTFOW = OptionsManager.getOption("TFOW");
	if sOptionTFOW == "on" then
		bEnableFOW = true;
	elseif sOptionTFOW == "pc" and (sFaction == "friend") then
		bEnableFOW = true;
	end
	tokenCT.setFOWEnabled(bEnableFOW);

	TokenManager.updateTokenColor(tokenCT);

	TokenManager.updateVisibilityHelper(tokenCT, nodeCT);
	TokenManager.updateSizeHelper(tokenCT, nodeCT);
end

function updateSpaceReach(nodeField)
	local nodeCT = DB.getParent(nodeField);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateSizeHelper(tokenCT, nodeCT);
	end
end

function updateSizeHelper(tokenCT, nodeCT)
	local nDU = GameSystem.getDistanceUnitsPerGrid();

	local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
	local nHalfSpace = nSpace / 2;
	local nReach = nHalfSpace + TokenManager.getReachUnderlayGridUnits(nodeCT);

	-- Clear underlays
	tokenCT.removeAllUnderlays();

	-- Reach underlay
	local sClass,_ = DB.getValue(nodeCT, "link", "", "");
	if sClass == "charsheet" then
		tokenCT.addUnderlay(nReach, "4f000000", "hover");
	else
		tokenCT.addUnderlay(nReach, "4f000000", "hover,gmonly");
	end

	-- Faction/space underlay
	local sFaction = CombatManager.getFactionFromCT(nodeCT);
	if sFaction == "friend" then
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.getUIColor("faction_friend"));
	elseif sFaction == "foe" then
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.getUIColor("faction_foe"));
	elseif sFaction == "neutral" then
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.getUIColor("faction_neutral"));
	else
		tokenCT.addUnderlay(nHalfSpace, "2F" .. ColorManager.getUIColor("faction_none"));
	end

	-- Set grid spacing
	tokenCT.setGridSize(nSpace);

	-- Update name widget size
	TokenManager.updateNameHelper(tokenCT, nodeCT);

	-- Update health bar size
	if TokenManager.isDefaultHealthEnabled() then
		TokenManager.updateHealthHelper(tokenCT, nodeCT);
	end
end

function updateTokenColor(token)
	-- Only update custom color if token exists and only on host
	if not token then
		return;
	end
	if not token.setColor then
		return;
	end
	if not Session.IsHost then
		return;
	end

	-- If valid CT actor, then check for custom color based on token linking
	local nodeCT = CombatManager.getCTFromToken(token);
	local rActor = ActorManager.resolveActor(nodeCT);
	if rActor then
		-- If PC, check to see if identity has owner and is active
		if ActorManager.isPC(rActor) then
			local nodeCreature = ActorManager.getCreatureNode(rActor);
			if nodeCreature then
				local nodeIdentity = DB.getName(nodeCreature);
				local bMatch = false;
				for _, sIdentity in pairs(User.getAllActiveIdentities()) do
					if sIdentity == nodeIdentity then
						bMatch = true;
					end
				end
				if bMatch then
					local color = User.getIdentityColor(DB.getName(nodeCreature));
					if color then
						token.setColor(color);
						return;
					end
				end
			end
		end

		-- Otherwise, use faction coloring
		local sFaction = CombatManager.getFactionFromCT(nodeCT);
		if sFaction == "friend" then
			token.setColor(ColorManager.getUIColor("faction_friend"));
			return;
		elseif sFaction == "foe" then
			token.setColor(ColorManager.getUIColor("faction_foe"));
			return;
		elseif sFaction == "neutral" then
			token.setColor(ColorManager.getUIColor("faction_neutral"));
			return;
		end
	end

	-- Set to neutral faction color if all of our custom color checks fail
	token.setColor(ColorManager.getUIColor("faction_none"));
end

--
-- Widget Management
--

local _nTokenDragUnits = nil;
function setDragTokenUnits(n)
	_nTokenDragUnits = n;
end
function getDragTokenUnits()
	return _nTokenDragUnits;
end
function endDragTokenWithUnits()
	_nTokenDragUnits = nil;
end
function calcTokenSpace(nSpace)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	if nSpace and nDU and nDU > 0 then
		return math.max(math.ceil((nSpace / nDU) * 2) / 2, 0.25);
	end
	return 1;
end
function getTokenSpace(tokenMap)
	local nSpace = TokenManager.getDragTokenUnits();
	if not nSpace then
		local nodeCT = CombatManager.getCTFromToken(tokenMap);
		if nodeCT then
			nSpace = DB.getValue(nodeCT, "space");
		end
	end
	return TokenManager.calcTokenSpace(nSpace);
end
function autoTokenScale(tokenMap)
	if not Session.IsHost or OptionsManager.isOption("TASG", "off") then
		return;
	end

	local aImage = DB.getValue(tokenMap.getContainerNode());
	if not aImage or (aImage.gridsizex <= 0) or (aImage.gridsizey <= 0) then
		return;
	end

	local nGridScale = TokenManager.getTokenSpace(tokenMap);
	if aImage.gridtype == 1 then
		nGridScale = nGridScale / 1.414;
	end
	local sOptTASG = OptionsManager.getOption("TASG");
	if sOptTASG == "80" then
		nGridScale = nGridScale * 0.8;
	end
	tokenMap.setScale(nGridScale);
end

--
-- Effects Management
--

function updateEffects(nodeCT)
	if Session.IsHost then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			VisionManager.updateTokenVisionHelper(tokenCT, nodeCT);
			VisionManager.updateTokenLightingHelper(tokenCT, nodeCT);
		end
	end
	if TokenManager.isDefaultEffectsEnabled() then
		local tokenCT = CombatManager.getTokenFromCT(nodeCT);
		if tokenCT then
			TokenManager.updateEffectsHelper(tokenCT, nodeCT);
			TokenManager.updateTooltip(tokenCT, nodeCT);
		end
	end
end

--
-- Common token manager add-on health bar/dot functionality
--
-- Callback assumed input of:
--		* nodeCT
-- Assume callback function provided returns 3 parameters
--		* percent wounded (number),
--		* status text (string),
--		* status color (string, hex color)
--

TOKEN_HEALTHBAR_HOFFSET = 0;
TOKEN_HEALTHBAR_WIDTH = 10;
TOKEN_HEALTHBAR_HEIGHT = 100;
TOKEN_HEALTHDOT_HOFFSET = -3;
TOKEN_HEALTHDOT_VOFFSET = -10;
TOKEN_HEALTHDOT_SIZE = 20;

local _bDisplayDefaultEffects = false;
local _fnGetHealthInfo = nil;

function setDefaultHealthEnabled(bState)
	_bDisplayDefaultEffects = bState;
end
function isDefaultHealthEnabled()
	return _bDisplayDefaultEffects;
end
function setDefaultHealthInfoFunction(fn)
	_fnGetHealthInfo = fn;
end
function getDefaultHealthInfoFunction()
	return _fnGetHealthInfo or TokenManager.getHealthInfoDefault;
end
function getHealthInfoDefault(nodeCT)
	return ActorHealthManager.getTokenHealthInfo(ActorManager.resolveActor(nodeCT));
end

function addDefaultHealthFeatures(f, tHealthFields)
	TokenManager.setDefaultHealthEnabled(true);
	TokenManager.setDefaultHealthInfoFunction(f);
	ActorDisplayManager.addDefaultHealthFeatures(tHealthFields);
end
function updateHealth(nodeField)
	local nodeCT = DB.getParent(nodeField);
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT then
		TokenManager.updateHealthHelper(tokenCT, nodeCT);
		TokenManager.updateTooltip(tokenCT, nodeCT);
	end
end
function updateHealthHelper(tokenCT, nodeCT)
	local sOptTH;
	if Session.IsHost then
		sOptTH = OptionsManager.getOption("TGMH");
	elseif CombatManager.getFactionFromCT(nodeCT) == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end

	if sOptTH == "bar" or sOptTH == "barhover" then
		tokenCT.deleteWidget("healthdot");

		local _,h = tokenCT.getSize();
		local bAddBar = false;
		if h > 0 then
			bAddBar = true;
		end
		if bAddBar then
			local widgetHealthBar = tokenCT.findWidget("healthbar");
			if not widgetHealthBar then
				local tWidget = {
					name = "healthbar",
					icon = "healthbar",
				};
				widgetHealthBar = tokenCT.addBitmapWidget(tWidget);
			end
			if widgetHealthBar then
				local nPercentWounded,sStatus,sColor = TokenManager.getDefaultHealthInfoFunction()(nodeCT);

				widgetHealthBar.sendToBack();
				widgetHealthBar.setColor(sColor);
				widgetHealthBar.setTooltipText(sStatus);
				widgetHealthBar.setVisible(sOptTH == "bar");
				TokenManager.updateHealthBarScale(tokenCT, nodeCT, nPercentWounded);
			end
		else
			tokenCT.deleteWidget("healthbar");
		end

	elseif sOptTH == "dot" or sOptTH == "dothover" then
		tokenCT.deleteWidget("healthbar");

		local widgetHealthDot = tokenCT.findWidget("healthdot");
		if not widgetHealthDot then
			local nSpace = TokenManager.calcTokenSpace(DB.getValue(nodeCT, "space"));
			local tWidget = {
				name = "healthdot",
				icon = "healthdot",
				position = "bottomright",
				x = TokenManager.TOKEN_HEALTHDOT_HOFFSET,
				y = TokenManager.TOKEN_HEALTHDOT_VOFFSET,
				w = TokenManager.TOKEN_HEALTHDOT_SIZE * nSpace,
				h = TokenManager.TOKEN_HEALTHDOT_SIZE * nSpace,
			};
			widgetHealthDot = tokenCT.addBitmapWidget(tWidget);
		end
		if widgetHealthDot then
			local _,sStatus,sColor = TokenManager.getDefaultHealthInfoFunction()(nodeCT);

			widgetHealthDot.setColor(sColor);
			widgetHealthDot.setTooltipText(sStatus);
		end
	else
		tokenCT.deleteWidget("healthbar");
		tokenCT.deleteWidget("healthdot");
	end
end
function updateHealthBarScale(tokenCT, nodeCT, nPercentWounded)
	local widgetHealthBar = tokenCT.findWidget("healthbar");
	if widgetHealthBar then
		local nSpace = TokenManager.calcTokenSpace(DB.getValue(nodeCT, "space"));
		local sOptTASG = OptionsManager.getOption("TASG");

		local barw = TokenManager.TOKEN_HEALTHBAR_WIDTH;
		local barh = TokenManager.TOKEN_HEALTHBAR_HEIGHT;
		if sOptTASG == "80" then
			barw = barw * 0.8;
			barh = barh * 0.8;
		end

		widgetHealthBar.setClipRegion(0, nPercentWounded * 100, 100, 100);
		widgetHealthBar.setSize(barw * nSpace, barh * nSpace);
		widgetHealthBar.setPosition("right", TokenManager.TOKEN_HEALTHBAR_HOFFSET, 0);
	end
end

--
-- Common token manager add-on effect functionality
--
-- Callback assumed input of:
--		* nodeCT
--		* bSkipGMOnlyEffects
-- Callback assumed output of:
--		* integer-based array of tables with following format
-- 			{
--				sName = "<Effect name to display>", (Currently, as effect icon tooltips when each displayed)
--				sIcon = "<Effect icon asset to display on token>",
--				sEffect = "<Original effect string>" (Currently used for large tooltips (multiple effects))
--			}
--

TOKEN_MAX_EFFECTS = 6;
TOKEN_EFFECT_MARGIN = 0;

TOKEN_EFFECT_SIZE_SMALL = 10;
TOKEN_EFFECT_SIZE_STANDARD = 15;
TOKEN_EFFECT_SIZE_LARGE = 20;

local _bDisplayDefaultEffects = false;
local _fnGetEffectInfo = nil;
local _fnParseEffectComp = nil;

function setDefaultEffectsEnabled(bState)
	_bDisplayDefaultEffects = bState;
end
function isDefaultEffectsEnabled()
	return _bDisplayDefaultEffects;
end
function setDefaultEffectInfoFunction(fn)
	_fnGetEffectInfo = fn;
end
function getDefaultEffectInfoFunction()
	return _fnGetEffectInfo or TokenManager.getEffectInfoDefault;
end
function setDefaultEffectParseFunction(fn)
	_fnParseEffectComp = fn;
end
function getDefaultEffectParseFunction()
	return _fnParseEffectComp or EffectManager.parseEffectCompSimple;
end

function addDefaultEffectFeatures(f, f2)
	TokenManager.setDefaultEffectsEnabled(true);
	TokenManager.setDefaultEffectInfoFunction(f);
	TokenManager.setDefaultEffectParseFunction(f2);

	ActorDisplayManager.addDefaultEffectFeatures();
end

function updateEffectsHelper(tokenCT, nodeCT)
	local sOptTE;
	if Session.IsHost then
		sOptTE = OptionsManager.getOption("TGME");
	elseif CombatManager.getFactionFromCT(nodeCT) == "friend" then
		sOptTE = OptionsManager.getOption("TPCE");
	else
		sOptTE = OptionsManager.getOption("TNPCE");
	end

	local sOptTASG = OptionsManager.getOption("TASG");
	local nEffectSize = TokenManager.TOKEN_EFFECT_SIZE_LARGE;
	if sOptTASG == "80" then
		nEffectSize = nEffectSize * 0.8;
	end

	if sOptTE == "off" then
		for i = 1, TokenManager.TOKEN_MAX_EFFECTS do
			tokenCT.deleteWidget("effect" .. i);
		end
	elseif sOptTE == "mark" or sOptTE == "markhover" then
		local bWidgetsVisible = (sOptTE == "mark");

		local tTooltip = {};
		local aCondList = TokenManager.getDefaultEffectInfoFunction()(nodeCT);
		for _,v in ipairs(aCondList) do
			table.insert(tTooltip, v.sEffect);
		end

		if #tTooltip > 0 then
			local w = tokenCT.findWidget("effect1");
			if not w then
				local tWidget = {
					name = "effect1",
					icon = "cond_generic",
				};
				w = tokenCT.addBitmapWidget(tWidget);
			else
				w.setBitmap("cond_generic");
			end
			if w then
				w.setTooltipText(table.concat(tTooltip, "\r"));
				w.setPosition("topleft", (nEffectSize / 2), (nEffectSize / 2));
				w.setSize(nEffectSize, nEffectSize);
				w.setVisible(bWidgetsVisible);
			end
			for i = 2, TokenManager.TOKEN_MAX_EFFECTS do
				local w = tokenCT.findWidget("effect" .. i);
				if w then
					w.destroy();
				end
			end
		else
			for i = 1, TokenManager.TOKEN_MAX_EFFECTS do
				local w = tokenCT.findWidget("effect" .. i);
				if w then
					w.destroy();
				end
			end
		end
	else
		local bWidgetsVisible = (sOptTE == "on");

		local aCondList = TokenManager.getDefaultEffectInfoFunction()(nodeCT);
		local nConds = #aCondList;

		local wTokenEffectMax;
		if sOptTASG == "80" then
			wTokenEffectMax = 80;
		else
			wTokenEffectMax = 100;
		end

		local wLast = nil;
		local lastposy = 0;
		local posy = 0;
		local i = 1;
		local nMaxLoop = math.min(nConds, TokenManager.TOKEN_MAX_EFFECTS);
		while i <= nMaxLoop do
			local w = tokenCT.findWidget("effect" .. i);
			if not w then
				local tWidget = {
					name = "effect" .. i,
				};
				w = tokenCT.addBitmapWidget(tWidget);
			end
			if w then
				w.setBitmap(aCondList[i].sIcon);
				w.setTooltipText(aCondList[i].sName);
				if wLast and posy + nEffectSize > wTokenEffectMax then
					w.destroy();
					wLast.setBitmap("cond_more");
					wLast.setPosition("topleft", (nEffectSize / 2), lastposy + (nEffectSize / 2));
					wLast.setSize(nEffectSize, nEffectSize);
					local tTooltip = {};
					table.insert(tTooltip, wLast.getTooltipText());
					for j = i, nConds do
						table.insert(tTooltip, aCondList[j].sEffect);
					end
					wLast.setTooltipText(table.concat(tTooltip, "\r"));
					i = i + 1;
					break;
				end
				if i == nMaxLoop and nConds > nMaxLoop then
					w.setBitmap("cond_more");
					local tTooltip = {};
					for j = i, nConds do
						table.insert(tTooltip, aCondList[j].sEffect);
					end
					w.setTooltipText(table.concat(tTooltip, "\r"));
				end
				w.setPosition("topleft", (nEffectSize / 2), posy + (nEffectSize / 2));
				w.setSize(nEffectSize, nEffectSize);
				lastposy = posy;
				posy = posy + nEffectSize + TokenManager.TOKEN_EFFECT_MARGIN;
				w.setVisible(bWidgetsVisible);
				wLast = w;
			end
			i = i + 1;
		end
		while i <= TokenManager.TOKEN_MAX_EFFECTS do
			tokenCT.deleteWidget("effect" .. i);
			i = i + 1;
		end
	end
end

local _tParseEffectTagConditional = {};
local _tParseEffectBonusTag = {};
local _tParseEffectSimpleTag = {};
local _tParseEffectCondition = {};
function addEffectTagIconConditional(sType, f)
	_tParseEffectTagConditional[sType] = f;
end
function getEffectTagIconConditionals()
	return _tParseEffectTagConditional;
end
function addEffectTagIconBonus(vType)
	if type(vType) == "table" then
		for _,v in pairs(vType) do
			_tParseEffectBonusTag[v] = true;
		end
	elseif type(vType) == "string" then
		_tParseEffectBonusTag[vType] = true;
	end
end
function getEffectTagIconBonuses()
	return _tParseEffectBonusTag;
end
function addEffectTagIconSimple(vType, sIcon)
	if type(vType) == "table" then
		for kTag,vTag in pairs(vType) do
			_tParseEffectSimpleTag[kTag] = vTag;
		end
	elseif type(vType) == "string" then
		if not sIcon then return; end
		_tParseEffectSimpleTag[vType] = sIcon;
	end
end
function getEffectTagIconSimple()
	return _tParseEffectSimpleTag;
end
function addEffectConditionIcon(vType, sIcon)
	if type(vType) == "table" then
		for kCond,vCond in pairs(vType) do
			_tParseEffectCondition[kCond:lower()] = vCond;
		end
	elseif type(vType) == "string" then
		if not sIcon then return; end
		_tParseEffectCondition[vType] = sIcon;
	end
end
function getEffectConditionIcons()
	return _tParseEffectCondition;
end
function getEffectInfoDefault(nodeCT, bSkipGMOnly)
	local tEffectsDisplayData = {};

	local rActor = ActorManager.resolveActor(nodeCT);

	for _,nodeEffect in ipairs(UtilityManager.getSortedNodeList(DB.getChildList(nodeCT, "effects"))) do
		if DB.getValue(nodeEffect, "isactive", 0) == 1 then
			if (not bSkipGMOnly and Session.IsHost) or (DB.getValue(nodeEffect, "isgmonly", 0) == 0) then
				local tDisplayData = TokenManager.getEffectDisplayInfoDefault(rActor, nodeEffect);
				if tDisplayData then
					table.insert(tEffectsDisplayData, tDisplayData);
				end
			end
		end
	end

	return tEffectsDisplayData;
end
function getEffectDisplayInfoDefault(rActor, nodeEffect)
	if not nodeEffect then
		return nil;
	end

	local sLabel = DB.getValue(nodeEffect, "label", "");
	local aEffectComps = EffectManager.parseEffect(sLabel);
	if #aEffectComps == 0 then
		return nil;
	end

	local aEffectIcons = {};
	for kComp,sEffectComp in ipairs(aEffectComps) do
		local vComp = TokenManager.getDefaultEffectParseFunction()(sEffectComp);
		local sTag = vComp.type;

		local sNewIcon = nil;
		local bContinue = true;

		local tParseEffectTagConditional = TokenManager.getEffectTagIconConditionals();
		for kCustom,_ in pairs(tParseEffectTagConditional) do
			if kCustom == sTag then
				bContinue = tParseEffectTagConditional[kCustom](rActor, nodeEffect, vComp);
				sNewIcon = "";
				break;
			end
		end
		if not bContinue then
			break;
		end

		if not sNewIcon then
			local tParseEffectBonusTag = TokenManager.getEffectTagIconBonuses();
			for kBonus,_ in pairs(tParseEffectBonusTag) do
				if kBonus == sTag then
					if #(vComp.dice) > 0 or vComp.mod > 0 then
						sNewIcon = "cond_bonus";
					elseif vComp.mod < 0 then
						sNewIcon = "cond_penalty";
					else
						sNewIcon = "";
					end
					break;
				end
			end
		end
		if not sNewIcon then
			sNewIcon = TokenManager.getEffectTagIconSimple()[sTag];
		end
		if not sNewIcon then
			sTag = vComp.original:lower();
			sNewIcon = TokenManager.getEffectConditionIcons()[sTag];
		end

		aEffectIcons[kComp] = sNewIcon;
	end

	-- If the first effect component didn't match anything, use it as a name
	local sFinalName = nil;
	if not aEffectIcons[1] then
		sFinalName = aEffectComps[1].original;
	end

	-- If all icons match, then use the matching icon, otherwise, use the generic icon
	local sFinalIcon = nil;
	for _,vIcon in pairs(aEffectIcons) do
		if (vIcon or "") ~= "" then
			if sFinalIcon then
				if sFinalIcon ~= vIcon then
					sFinalIcon = nil;
					break;
				end
			else
				sFinalIcon = vIcon;
			end
		end
	end

	return { sName = sFinalName or sLabel, sIcon = sFinalIcon or "cond_generic", sEffect = sLabel, };
end
