--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "*.name"), "onUpdate", self.onNameUpdated);
	DB.addHandler(DB.getPath(node, "*.nonid_name"), "onUpdate", self.onNameUpdated);
	DB.addHandler(DB.getPath(node, "*.isidentified"), "onUpdate", self.onNameUpdated);
end
function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "*.name"), "onUpdate", self.onNameUpdated);
	DB.removeHandler(DB.getPath(node, "*.nonid_name"), "onUpdate", self.onNameUpdated);
	DB.removeHandler(DB.getPath(node, "*.isidentified"), "onUpdate", self.onNameUpdated);
end

function onNameUpdated()
	for _,w in pairs(getWindows()) do
		w.summary_targets.onTargetsChanged();
	end
end
function onOptionCTSIChanged()
	for _,v in pairs(getWindows()) do
		v.updateDisplay();
	end
	applySort();
end

function onSortCompare(w1, w2)
	return CombatManager.onSortCompare(w1.getDatabaseNode(), w2.getDatabaseNode());
end

function onFilter(w)
	local node = w.getDatabaseNode();
	return (DB.getValue(node, "friendfoe", "") == "friend") or (DB.getValue(node, "tokenvis", 0) ~= 0);
end

function onClickDown(button)
	if button == 1 then
		return true;
	end
end
function onClickRelease(button, x, y)
	if button == 1 then
		local w = getWindowAt(x, y);
		if w then
			return CombatManager.handleCTTokenPressed(w.getDatabaseNode());
		end
	end
end
function onDrop(x, y, draginfo)
	local sCTNode = WindowManager.getDatabasePath(getWindowAt(x,y));
	return CombatDropManager.handleAnyDrop(draginfo, sCTNode);
end
