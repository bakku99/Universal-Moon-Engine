--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bInitialized = false;
local _tActiveIdentities = {};

function onInit()
	_tActiveIdentities = User.getAllActiveIdentities();
	User.getRemoteIdentities("charsheet", GameSystem.requestCharSelectDetailClient(), self.addIdentity);
	_bInitialized = true;
end
function onClose()
	_bInitialized = false;
end

function addIdentity(id, vDetails, nodeLocal)
	if not _bInitialized then
		return;
	end
	for _, v in ipairs(_tActiveIdentities) do
		if v == id then
			return;
		end
	end

	local w = createWindow();
	if w then
		w.setData(id, nodeLocal);

		local sName, sDetails = GameSystem.receiveCharSelectDetailClient(vDetails);
		w.name.setValue(sName);
		w.details.setValue(sDetails);
		if DB.isOwner("charsheet." .. id) then
			w.campaign.setValue(Interface.getString("charselect_label_server") .. " (" .. Interface.getString("charselect_label_owned") .. ")");
		end

		if id then
			w.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end

		applySort();
	end
end
