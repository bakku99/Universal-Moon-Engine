--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onValueChanged();
end

function onValueChanged()
	local bActive = (getValue() == 1);

	window.updateDisplay();
	if bActive then
		window.windowlist.scrollToWindow(window);
	end

	if window.onActiveChanged then
		window.onActiveChanged(bActive)
	end

	CombatManager.onEntryActivationChanged(window.getDatabaseNode());
end

function onClickDown()
	return true;
end
function onClickRelease()
	if (getValue() == 0) and Session.IsHost then
		CombatManager.requestActivation(window.getDatabaseNode(), true);
	end
	return true;
end
function onDragStart(_, _, _, draginfo)
	if (getValue() == 1) and Session.IsHost then
		draginfo.setType("combattrackeractivation");
		draginfo.setIcon("ct_active");
		return true;
	end
end
function onDrop(_, _, draginfo)
	if draginfo.isType("combattrackeractivation") then
		CombatManager.requestActivation(window.getDatabaseNode(), true);
		return true;
	end
end
