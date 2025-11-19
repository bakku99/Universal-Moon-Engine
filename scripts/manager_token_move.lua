--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	Token.addEventHandler("onMovePathChanged", TokenMoveManager.onTokenMovePathChanged);

	Interface.addKeyedEventHandler("onHotkeyActivated", "tokenmoveacceptall", TokenMoveManager.onHotKeyAcceptAll);
	Interface.addKeyedEventHandler("onHotkeyActivated", "tokenmovecancelall", TokenMoveManager.onHotKeyCancelAll);
end

function onImageInit(cImage)
	TokenMoveManager.updateAllTokenMove(cImage);
end
function onImageClose(cImage)
	TokenMoveManager.clearImageApprovalEntries(cImage);
end

--
--	EVENTS
--

function onTokenMovePathChanged(tokenMap)
	TokenMoveManager.updateTokenMove(tokenMap, true);
	TokenMoveManager.updateViewTokenMove(tokenMap);
end
function updateAllTokenMove(cImage)
	if not cImage then
		return;
	end
	for _,tokenMap in ipairs(cImage.getTokens()) do
		TokenMoveManager.updateTokenMove(tokenMap);
	end
	TokenMoveManager.helperTokenMoveVisibility(cImage);
end
function updateTokenMove(tokenMap, bVisCheck)
	local cImage = ImageManager.getActiveImageFromToken(tokenMap);
	if not cImage then
		return;
	end

	local bShowMove = (Token.isOwner(tokenMap) or Token.isPublicEdit(tokenMap)) and (Token.getPlannedMovementDistance(tokenMap) > 0);
	if bShowMove then
		local w = TokenMoveManager.createApprovalEntry(cImage, tokenMap);
		if w then
			ActorDisplayManager.updateActorDisplayControls("distance", ActorManager.resolveActor(tokenMap), tokenMap);
		end
	else
		TokenMoveManager.clearApprovalEntry(cImage, tokenMap);
	end

	if bVisCheck then
		TokenMoveManager.helperTokenMoveVisibility(cImage);
	end
end
function updateViewTokenMove(tokenMap)
	local cImage = ImageManager.getActiveImageFromToken(tokenMap);
	if not cImage or (cImage.getViewToken() ~= tokenMap) then
		return;
	end
	local wViewToken = cImage.window and cImage.window.sub_view_token_detail and cImage.window.sub_view_token_detail.subwindow;
	if not wViewToken then
		return;
	end

	local bShowMoveUI =
			(Token.isOwner(tokenMap) or Token.isPublicEdit(tokenMap)) and
			(Token.getPlannedMovementDistance(tokenMap) > 0);
	wViewToken.button_accept.setVisible(bShowMoveUI);
	wViewToken.button_cancel.setVisible(bShowMoveUI);
end
function helperTokenMoveVisibility(cImage)
	if not cImage then
		return;
	end
	local nCount = cImage.window.sub_view_tokenmove.subwindow.list.getWindowCount();
	cImage.window.sub_view_tokenmove.setVisible(nCount > 0);
end

function createApprovalEntry(cImage, tokenMap)
	if not cImage or not tokenMap then
		return nil;
	end
	local w = TokenMoveManager.getApprovalEntry(cImage, tokenMap);
	if w then
		return w;
	end
	w = cImage.window.sub_view_tokenmove.subwindow.list.createWindow();
	if not w then
		return nil;
	end

	TokenMoveManager.setApprovalEntry(cImage, tokenMap, w);
	ActorDisplayManager.addDisplayControl(w.display, "tokenmove", ActorManager.resolveActor(tokenMap), { tokenMap = tokenMap });
	w.display.initData({ nID = tokenMap.getId() });
	return w;
end

--
--	UI
--

function onHotKeyAcceptAll()
	for _, cImage in ipairs(ImageManager.getActiveImages()) do
		Token.approvePlannedMovementAll(cImage.getDatabaseNode());
	end
	return true;
end
function onHotKeyCancelAll()
	for _, cImage in ipairs(ImageManager.getActiveImages()) do
		Token.cancelPlannedMovementAll(cImage.getDatabaseNode());
	end
	return true;
end

function onAcceptAllButtonPressed(w)
	local cImage = ImageManager.getImageControlFromWindow(w);
	if not cImage then
		return;
	end
	Token.approvePlannedMovementAll(cImage.getDatabaseNode());
end
function onCancelAllButtonPressed(w)
	local cImage = ImageManager.getImageControlFromWindow(w);
	if not cImage then
		return;
	end
	Token.cancelPlannedMovementAll(cImage.getDatabaseNode());
end
function onAcceptButtonPressed(w)
	local cImage = ImageManager.getImageControlFromWindow(w);
	if not cImage then
		return;
	end
	local tData = w.display.getData();
	if not tData then
		return;
	end
	Token.approvePlannedMovement(cImage.getDatabaseNode(), tData.nID);
	cImage.setFocus();
end
function onCancelButtonPressed(w)
	local cImage = ImageManager.getImageControlFromWindow(w);
	if not cImage then
		return;
	end
	local tData = w.display.getData();
	if not tData then
		return;
	end
	Token.cancelPlannedMovement(cImage.getDatabaseNode(), tData.nID);
	cImage.setFocus();
end

function onViewTokenAcceptButtonPressed(w)
	local cImage = ImageManager.getImageControlFromWindow(w);
	if not cImage then
		return;
	end
	local tokenView = cImage.getViewToken();
	if not tokenView then
		return;
	end
	Token.approvePlannedMovement(tokenView);
	cImage.setFocus();
end
function onViewTokenCancelButtonPressed(w)
	local cImage = ImageManager.getImageControlFromWindow(w);
	if not cImage then
		return;
	end
	local tokenView = cImage.getViewToken();
	if not tokenView then
		return;
	end
	Token.cancelPlannedMovement(tokenView);
	cImage.setFocus();
end

--
--	DATA
--

local _tApprovals = {};
function getApprovalData()
	return _tApprovals or {};
end
function getApprovalEntry(cImage, tokenMap)
	if not cImage or not tokenMap then
		return nil;
	end
	local tApprovals = TokenMoveManager.getApprovalData();
	local sImagePath = DB.getPath(cImage.getDatabaseNode());
	return tApprovals[sImagePath] and tApprovals[sImagePath][tokenMap.getId()];
end
function setApprovalEntry(cImage, tokenMap, w)
	if not cImage or not tokenMap then
		return;
	end
	local tApprovals = TokenMoveManager.getApprovalData();
	local sImagePath = DB.getPath(cImage.getDatabaseNode());
	tApprovals[sImagePath] = tApprovals[sImagePath] or {};
	tApprovals[sImagePath][tokenMap.getId()] = w;
end
function clearApprovalEntry(cImage, tokenMap)
	if not cImage or not tokenMap then
		return;
	end
	local tApprovals = TokenMoveManager.getApprovalData();
	local sImagePath = DB.getPath(cImage.getDatabaseNode());
	if not tApprovals[sImagePath] then
		return;
	end
	local nID = tokenMap.getId();
	local w = tApprovals[sImagePath][nID];
	if not w then
		return;
	end

	w.close();
	tApprovals[sImagePath][nID] = nil;
end
function clearImageApprovalEntries(cImage)
	if not cImage then
		return;
	end
	local tApprovals = TokenMoveManager.getApprovalData();
	local sImagePath = DB.getPath(cImage.getDatabaseNode());
	if not tApprovals[sImagePath] then
		return;
	end
	for _,w in pairs(tApprovals[sImagePath]) do
		w.close();
	end
	tApprovals[sImagePath] = nil;
end
