--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	Registrations and Handlers
--

local _sActionsPath = "actions";
function registerPowerActionsPath(s)
	_sActionsPath = s;
end
function getPowerActionsPath()
	return _sActionsPath;
end

local _tHandlers = nil;
function registerPowerHandlers(tPowerItemHandlers)
	_tHandlers = tPowerItemHandlers;
end

function getPowerActorNode(node)
	if _tHandlers and _tHandlers.fnGetActorNode then
		return _tHandlers.fnGetActorNode(node);
	end
	return nil;
end
function usePower(node)
	if _tHandlers and _tHandlers.fnUsePower then
		_tHandlers.fnUsePower(node);
		return;
	end
	PowerManagerCore.performDefaultPowerUse(node);
end
function parsePower(node)
	if _tHandlers and _tHandlers.fnParse then
		_tHandlers.fnParse(node);
		return;
	end
end
function updatePowerDisplay(w)
	if _tHandlers and _tHandlers.fnUpdateDisplay then
		_tHandlers.fnUpdateDisplay(w);
		return;
	end
end

--
--	Common Functions
--

function getPowerName(node)
	return DB.getValue(node, "name", "");
end
function getPowerOutput(node)
	local sShort = DB.getValue(node, "shortdescription", "");
	if sShort == "" then
		return string.format("%s - %s", PowerManagerCore.getPowerName(node), sShort);
	end
	return PowerManagerCore.getPowerName(node);
end

function performDefaultPowerUse(node)
	local rActor = ActorManager.resolveActor(PowerManagerCore.getPowerActorNode(node));
	ChatManager.Message(PowerManagerCore.getPowerOutput(node), ActorManager.isPC(rActor), rActor);
end

function handleDefaultPowerInitParse(node)
	local nParse = DB.getValue(node, "parse", 0);
	if nParse ~= 0 then
		DB.deleteChild(node, "parse");
		PowerManagerCore.parsePower(node);
	end
end

--
--	Context Menu Functions
--

function registerDefaultPowerMenu(w)
	w.registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	w.registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);

	local tTypes = PowerActionManagerCore.getSortedActionTypes();
	if #tTypes > 0 then
		w.registerMenuItem(Interface.getString("power_menu_action_add"), "pointer", 3);
		local nBaseIndex = PowerManagerCore.getDefaultPowerMenuBaseIndex(tTypes);
		for k,v in ipairs(tTypes) do
			local subselection = ((nBaseIndex + k - 2) % 8) + 1;
			w.registerMenuItem(Interface.getString("power_menu_action_add_" .. v), "radial_power_action_" .. v, 3, subselection);
			if k == 7 then
				break;
			end
		end
	end

	if _tHandlers and _tHandlers.fnParse then
		w.registerMenuItem(Interface.getString("power_menu_action_reparse"), "textlist", 4);
	end
end
function onDefaultPowerMenuSelection(w, selection, subselection)
	if selection == 6 and subselection == 7 then
		DB.deleteNode(w.getDatabaseNode());
	elseif selection == 4 then
		PowerManagerCore.parsePower(w.getDatabaseNode());
		if w.activatedetail then
			w.activatedetail.setValue(1);
		end
	elseif selection == 3 then
		local tTypes = PowerActionManagerCore.getSortedActionTypes();
		local nBaseIndex = PowerManagerCore.getDefaultPowerMenuBaseIndex(tTypes);
		local nActionIndex = ((subselection - nBaseIndex) % 8) + 1;
		local sType = tTypes[nActionIndex];
		if sType then
			PowerManagerCore.createPowerAction(w, sType);
		end
	end
end
function getDefaultPowerMenuBaseIndex(tActionTypes)
	local nActionTypes = #tActionTypes;
	if nActionTypes > 6 then
		return 8;
	elseif nActionTypes > 4 then
		return 1;
	elseif nActionTypes > 1 then
		return 2;
	end
	return 3;
end
function createPowerAction(w, sType)
	local node = w.getDatabaseNode();
	if node then
		local nodeActions = DB.createChild(node, PowerManagerCore.getPowerActionsPath());
		if nodeActions then
			local nodeAction = DB.createChild(nodeActions);
			if nodeAction then
				DB.setValue(nodeAction, "type", "string", sType);
				if w.activatedetail then
					w.activatedetail.setValue(1);
				end
			end
		end
	end
end
