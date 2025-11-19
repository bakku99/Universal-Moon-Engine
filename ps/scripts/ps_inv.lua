--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		PartyLootManager.populate();
	else
		OptionsManager.registerCallback("PSIN", self.onOptionChanged);
	end
	self.onOptionChanged();
end
function onClose()
	if not Session.IsHost then
		OptionsManager.unregisterCallback("PSIN", self.onOptionChanged);
	end
end

function onOptionChanged()
	local bShow = Session.IsHost or OptionsManager.isOption("PSIN", "on");
	if bShow then
		sub_party.setValue("ps_inventory_party", getDatabaseNode());
	else
		sub_party.setValue("", "");
	end
	sub_party.setVisible(bShow);
end

function onDrop(_, _, draginfo)
	return ItemManager.handleAnyDrop("partysheet", draginfo);
end
