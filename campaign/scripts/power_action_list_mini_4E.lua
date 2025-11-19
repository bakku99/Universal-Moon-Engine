--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.rebuild();
	DB.addHandler(window.getDatabaseNode(), "onChildUpdate", self.rebuild);
	DB.addHandler(window.getDatabaseNode(), "onChildDeleted", self.rebuild);
end
function onClose()
	DB.removeHandler(window.getDatabaseNode(), "onChildUpdate", self.rebuild);
	DB.removeHandler(window.getDatabaseNode(), "onChildDeleted", self.rebuild);
end

function rebuild()
	closeAll();

	local node = DB.getChild(window.getDatabaseNode(), "abilities");
	if node then
		local tAbilityNodes = DB.getChildren(node);
		local tSortedAbilityNodes = {};
		for _,v in pairs(tAbilityNodes) do
			table.insert(tSortedAbilityNodes, v);
		end
		table.sort(tSortedAbilityNodes, function(a,b) return DB.getValue(a, "order", 0) < DB.getValue(b, "order", 0); end);
		for _,v in ipairs(tSortedAbilityNodes) do
			self.createEntries(v);
		end
	end
end
function createEntries(node)
	self.createEntryWindow(node);
	if DB.getValue(node, "type", "") == "attack" then
		self.createEntryWindow(node, "damage");
	end
end
function createEntryWindow(node, sSubRoll)
	local tData = PowerActionManagerCore.resolveActionTypeData(node);
	tData.sSubRoll = sSubRoll;
	local sActionText = PowerManager.getPowerActionText(node, tData);
	if sActionText ~= "" then
		local w = createWindow(node);

		local sButton, sButtonDown = PowerActionManagerCore.getActionButtonIcons(node, tData);
		w.button.setIcons(sButton, sButtonDown);
		w.button.setTooltipText(PowerActionManagerCore.getActionTooltip(node, tData));
		if sSubRoll then
			w.button.subroll = { sSubRoll };
		end
	end
end
