--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	DATA
--

local _tData;
function initData(tData)
	if not tData or ((tData.sPath or "") == "") then
		return;
	end
	_tData = tData;
	self.registerMenuItems();
end
function getData()
	return _tData;
end
function getRecordPath()
	if not _tData then
		return "";
	end
	return _tData.sPath or "";
end
function getRecordNode()
	if not _tData or ((_tData.sPath or "") == "") then
		return nil;
	end
	return DB.findNode(_tData.sPath);
end
function isOwned()
	if not _tData or ((_tData.sPath or "") == "") then
		return false;
	end
	if Session.IsHost then
		return true;
	end
	return DB.isOwner(_tData.sPath);
end

--
--	UI
--

function registerMenuItems()
	resetMenuItems();
	if Session.IsHost and (self.getRecordPath() ~= "") then
		registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
		registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
	end
end
function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local sPath = self.getRecordPath();
		if sPath ~= "" then
			DB.deleteNode(sPath);
		end
	end
end

function onClickDown(button)
	if button == 1 then
		return true;
	end
end
function onClickRelease(button)
	if button == 1 then
		local rActor = ActorManager.resolveActor(self.getRecordPath());
		if Input.isControlPressed() then
			CombatManager.handleCTTokenPressed(ActorManager.getCTNode(rActor));
		else
			if ActorManager.isOwner(rActor) then
				Interface.toggleWindow(ActorManager.getRecordType(rActor), ActorManager.getCreatureNode(rActor));
			end
		end
		return true;
	end
end
function onDragStart(_, _, _, draginfo)
	local sPath = self.getRecordPath();
	if ActorManager.isOwner(sPath) then
		return CombatManager.handleCTTokenDragStart(DB.findNode(sPath), draginfo);
	end
	return true;
end
function onDragEnd(draginfo)
	return CombatManager.handleCTTokenDragEnd(DB.findNode(self.getRecordPath()), draginfo);
end
function onDrop(_, _, draginfo)
	return CombatDropManager.handleAnyDrop(draginfo, self.getRecordPath());
end
