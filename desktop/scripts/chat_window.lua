--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onDragStart(_, _, _, draginfo)
	return ActionsManager.onChatDragStart(draginfo);
end
function onDrop(_, _, draginfo)
	if ChatManager.onDrop(draginfo) then
		return true;
	end
	if ActionsManager.actionDrop(draginfo) then
		return true;
	end
end
