--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals gmrollable gmrollable2 rollable rollable2 wheel

function onInit()
	if rollable or (gmrollable and Session.IsHost) then
		addBitmapWidget({ icon = "field_rollable", position="bottomleft", x = -1, y = -4 });
		setHoverCursor("hand");
	elseif rollable2 or (gmrollable2 and Session.IsHost) then
		local w = addBitmapWidget({ icon = "field_rollable_transparent", position="topright", x = 0, y = 2 });
		w.sendToBack();
		setHoverCursor("hand");
	end
end

function onDrop(_, _, draginfo)
	if draginfo.getType() ~= "number" then
		return false;
	end
end
