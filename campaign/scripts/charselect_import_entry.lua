--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();

	local sLocalAsset = User.getLocalIdentityPortrait(node);
	if (sLocalAsset or "") ~= "" then
		portrait.setFile(sLocalAsset);
	else
		local sPortrait = DB.getValue(node, "portrait", "");
		if sPortrait ~= "" then
			portrait.setFile(sPortrait);
		end
	end
	name.setValue(DB.getValue(node, "name", ""));
	details.setValue(GameSystem.getCharSelectDetailHost(node));
end

local _bRequested = false;
function importCharacter()
	if Session.IsHost then
		local nodeTarget = CampaignDataManager.addPregenChar(getDatabaseNode());
		if (portrait.getFile() or "") ~= "" then
			portrait.activate(nodeTarget);
		end
	else
		if not _bRequested then
			UserManager.requestIdentity("", { nodeLocal = getDatabaseNode(), fnResponse = self.requestResponse, });
			_bRequested = true;
		end
	end
end
function requestResponse(result, identity)
	if result and identity then
		windowlist.window.close();
	else
		error.setVisible(true);
	end
end

function exportCharacter()
	CampaignDataManager.exportChar(getDatabaseNode());
end
