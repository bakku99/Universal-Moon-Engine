--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function addEntry()
	return DB.createChild(window.getDatabaseNode());
end

function onDrop(_, _, draginfo)
	if Session.IsHost then
		local rEffect = EffectManager.decodeEffectFromDrag(draginfo);
		if rEffect then
			local node = self.addEntry();
			if node then
				EffectManager.setEffect(node, rEffect);
			end
		end
		return true;
	end
end
function onListChanged()
	WindowManager.callOuterWindowFunction(window, "onListChanged");
end
