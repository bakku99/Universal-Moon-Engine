--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onTargetsChanged();
	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "targets"), "onChildAdded", self.onTargetsChanged);
	DB.addHandler(DB.getPath(node, "targets.*"), "onChildUpdate", self.onTargetsChanged);
	DB.addHandler(DB.getPath(node, "targets"), "onChildDeleted", self.onTargetsChanged);
	DB.addHandler(DB.getPath(node, "friendfoe"), "onUpdate", self.onTargetsChanged);
end
function onClose()
	local node = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "targets"), "onChildAdded", self.onTargetsChanged);
	DB.removeHandler(DB.getPath(node, "targets.*"), "onChildUpdate", self.onTargetsChanged);
	DB.removeHandler(DB.getPath(node, "targets"), "onChildDeleted", self.onTargetsChanged);
	DB.removeHandler(DB.getPath(node, "friendfoe"), "onUpdate", self.onTargetsChanged);
end

function onToggle()
	self.onTargetsChanged();
end

function onTargetsChanged()
	local nodeCT = window.getDatabaseNode();
	if (window.getClass() == "client_ct_entry") and not Session.IsHost and (CombatManager.getFactionFromCT(nodeCT) ~= "friend") then
		setVisible(false);
		setValue(nil);
	else
		-- Get target names
		local aTargetNames = {};
		for _,vTarget in ipairs(DB.getChildList(window.getDatabaseNode(), "targets")) do
			local sTargetName = "";
			local sCTNode = DB.getValue(vTarget, "noderef", "");
			if sCTNode ~= "" then
				local nodeCT = DB.findNode(sCTNode);
				if nodeCT then
					sTargetName = ActorManager.getDisplayName(nodeCT);
				end
			end
			if sTargetName == "" then
				sTargetName = "<Target>";
			end
			table.insert(aTargetNames, sTargetName);
		end

		-- Set the targeting summary string
		if #aTargetNames > 0 then
			setValue(Interface.getString("ct_label_targets") .. " " .. table.concat(aTargetNames, "; "));
		else
			setValue(nil);
		end

		-- Update visibility
		local bSectionToggle = (window.activatetargeting and (window.activatetargeting.getValue() == 1)) or
				(window.getSectionToggle and (window.getSectionToggle("targets") == true));
		local bShow = (#aTargetNames > 0) and not bSectionToggle;
		setVisible(bShow);
	end
end
