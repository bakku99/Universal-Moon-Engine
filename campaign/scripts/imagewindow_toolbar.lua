--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local wTop = WindowManager.getTopWindow(self);
	if wTop.isPanel() then
		ToolbarManager.addButton(self, "share", "right").sendToBack();
		ToolbarManager.addSeparator(self, "right").sendToBack();
		ToolbarManager.addButton(self, "help", "right").sendToBack();
		ToolbarManager.addButton(self, "size_down", "right").sendToBack();
		if wTop.getClass() ~= "imagefullpanel" then
			ToolbarManager.addButton(self, "size_up", "right").sendToBack();
		end
		ToolbarManager.addButton(self, "close", "right").sendToBack();
		rightanchor.sendToBack();
	end

	self.updateDisplay();
end

function onImageCursorModeChanged()
	self.updateDisplay();
end
function onImageViewModeChanged()
	self.updateDisplay();
end
function onImageStateChanged()
	self.updateDisplay();
end
function onImageTokenCountChanged()
	self.updateDisplay();
end

function updateDisplay()
	local cImage = WindowManager.callOuterWindowFunction(self, "getImage");

	local bHasMask = cImage.hasMask();
	local bDrawUnlocked = (Session.IsHost or not cImage.getDrawLockState());
	local bHasTokens = cImage.hasTokens();
	local bFlatView = (cImage.getViewMode() == "");

	locked.setVisible(Session.IsHost);
	image_separator_locked.setVisible(Session.IsHost);

	image_preview.setVisible(Session.IsHost);
	image_preview.reinit();
	image_tokenlock.setVisible(Session.IsHost and bHasTokens);
	image_tokenlock.reinit();
	image_shortcut.reinit();
	image_deathmarker_clear.setVisible(Session.IsHost and bHasTokens and ImageDeathMarkerManager.isEnabled());

	image_target_clear.setVisible(bHasTokens);
	image_target_friend.setVisible(bHasTokens);
	image_target_foe.setVisible(bHasTokens);
	image_target_select.setVisible(bHasTokens);
	image_target_select.reinit();
	image_select.setVisible(bHasTokens);
	image_select.reinit();
	image_separator_target.setVisible(bHasTokens);

	image_erase.setVisible(bDrawUnlocked);
	image_erase.reinit();
	image_draw.setVisible(bDrawUnlocked);
	image_draw.reinit();
	image_unmask.setVisible(bHasMask);
	image_unmask.reinit();
	image_separator_draw.setVisible(bHasMask or bDrawUnlocked);

	image_ping.reinit();
	image_view_token.setVisible(bHasTokens);
	image_view_token.reinit();
	image_view_camera.reinit();
	image_zoomtofit.setVisible(bFlatView);
end
