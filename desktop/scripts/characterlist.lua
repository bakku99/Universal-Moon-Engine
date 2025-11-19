--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

BUTTON_PADDING = 20;

function onInit()
	button_swap.setVisible(CombatListManager.isEnabled());
	self.onLockStateChanged();
end

function onSwapButtonPressed()
	if button_swap.getValue() == 1 then
		content.setValue("tabletop_combatlist", "");
	else
		content.setValue("tabletop_partylist", "");
	end
end

--
--	PLACEMENT/MOVE MANAGEMENT
--

function onHover(bOnWindow)
	if getLockState() then
		if bOnWindow then
			button_lock.setVisible(true);
		else
			button_lock.setVisible(false);
		end
	end
end

function onLockStateChanged()
	if getLockState() then
		setFrame();
		button_lock.setValue(1);
		button_reset.setVisible(false);
	else
		setFrame("border");
		button_lock.setValue(0);
		button_reset.setVisible(true);
	end
end

function onLockButtonPressed()
	if button_lock.getValue() == 1 then
		setLockState(true);
	else
		setLockState(false);
	end
end
function onResetButtonPressed()
	resetPosition();
end

--
--	SIZE MANAGEMENT
--

function onLayoutSizeChanged()
	WindowManager.callInnerWindowFunction("onPanelSizeChanged");
end
function onContentSizeChanged(nW, nH)
	content.setAnchoredWidth(nW);
	content.setAnchoredHeight(nH);
	self.refreshSize();
end
function refreshSize()
	local nW = content.getAnchoredWidth();
	local nH = content.getAnchoredHeight();
	setSize(nW + self.BUTTON_PADDING, nH);
end
