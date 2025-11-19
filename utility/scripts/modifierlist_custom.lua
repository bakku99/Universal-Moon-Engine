--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function addEntry()
	return DB.createChild(window.getDatabaseNode());
end

function onListChanged()
	WindowManager.callOuterWindowFunction(window, "onListChanged");
end
function onDrop(_, _, draginfo)
	if Session.IsHost then
		if draginfo.getType() == "number" then
			local node = self.addEntry(true);
			if node then
				DB.setValue(node, "label", "string", draginfo.getDescription());
				DB.setValue(node, "bonus", "number", draginfo.getNumberData());
			end
			return true;
		end
	end
end
