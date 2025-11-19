--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals button.subroll

function onInit()
	self.onDataChanged();
	DB.addHandler(getDatabaseNode(), "onChildUpdate", self.onDataChanged);
end
function onClose()
	DB.removeHandler(getDatabaseNode(), "onChildUpdate", self.onDataChanged);
end

function onDataChanged()
	local tData = self.getActionData();
	local sButton, sButtonDown = PowerActionManagerCore.getActionButtonIcons(getDatabaseNode(), tData);
	button.setIcons(sButton, sButtonDown);

	button.setTooltipText(PowerActionManagerCore.getActionTooltip(getDatabaseNode(), tData));
end
function getActionData()
	local tData = {};
	if button and button.subroll then
		tData.sSubRoll = button.subroll[1];
	end
	return tData;
end

function performAction(draginfo, sSubRoll)
	PowerActionManagerCore.performAction(draginfo, getDatabaseNode(), { sSubRoll = sSubRoll });
end
