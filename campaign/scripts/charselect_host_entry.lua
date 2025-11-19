--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("char_menu_ownerclear"), "erase", 4);
		registerMenuItem(string.format(Interface.getString("char_menu_ownergm"), User.getUsername()), "mask", 3);
	end

	local node = getDatabaseNode();
	portrait.setIcon("portrait_" .. DB.getName(node) .. "_charlist", true);
	details.setValue(GameSystem.getCharSelectDetailHost(node));

	self.updateOwner();
	local sPath = DB.getPath(getDatabaseNode());
	DB.addHandler(sPath, "onObserverUpdate", self.updateOwner);
end
function onClose()
	local sPath = DB.getPath(getDatabaseNode());
	DB.removeHandler(sPath, "onObserverUpdate", self.updateOwner);
end

function updateOwner()
	local sOwner = DB.getOwner(getDatabaseNode());
	if (sOwner or "") ~= "" then
		owner.setValue(Interface.getString("charselect_label_ownedby") .. " " .. sOwner);
	else
		owner.setValue("");
	end
end

function onMenuSelection(selection)
	if Session.IsHost then
		if selection == 4 then
			local node = getDatabaseNode();
			local sOwner = DB.getOwner(node);
			if (sOwner or "") ~= "" then
				DB.removeHolder(node, sOwner);
			end
		end
		if selection == 3 then
			local node = getDatabaseNode();
			local sOwner = DB.getOwner(node);
			if (sOwner or "") ~= "" then
				DB.removeHolder(node, sOwner);
			end
			DB.setOwner(node, User.getUsername());
		end
	end
end

function openCharacter()
	Interface.openWindow("charsheet", getDatabaseNode());
end

function dragCharacter(draginfo)
	return RecordAssetManager.handlePictureDragStart(getDatabaseNode(), draginfo);
end
