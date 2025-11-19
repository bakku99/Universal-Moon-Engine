--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onClickDown(button)
	if button == 1 then
		return true;
	end
end
function onClickRelease(button)
	if button == 1 then
		return CombatManager.handleCTTokenPressed(window.getDatabaseNode());
	end
end
function onDoubleClick()
	CombatManager.handleCTTokenDoubleClick(window.getDatabaseNode());
end
function onWheel(notches)
	return CombatManager.handleCTTokenWheel(window.getDatabaseNode(), notches);
end
function onDragStart(_, _, _, draginfo)
	return CombatManager.handleCTTokenDragStart(window.getDatabaseNode(), draginfo);
end
function onDragEnd(draginfo)
	return CombatManager.handleCTTokenDragEnd(window.getDatabaseNode(), draginfo);
end
function onDrop(_, _, draginfo)
	return CombatManager.handleCTTokenDrop(window.getDatabaseNode(), draginfo);
end
