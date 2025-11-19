--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
--	Registrations and Handlers
--

local _tAllTypeData = {};
function registerActionType(sType, tTypeData)
	_tAllTypeData[sType] = tTypeData;
	if tTypeData and (sType ~= "") and not tTypeData.nOrder then
		tTypeData.nOrder = PowerActionManagerCore.calcNextActionTypeOrder();
	end
end
function overrideActionType(sType, tTypeData)
	if _tAllTypeData[sType] then
		for k,v in pairs(tTypeData) do
			_tAllTypeData[sType][k] = v;
		end
	else
		_tAllTypeData[sType] = tTypeData;
	end
end
function calcNextActionTypeOrder()
	local nMax = 0;
	for _,v in pairs(_tAllTypeData) do
		if v.nOrder and v.nOrder > nMax then
			nMax = v.nOrder;
		end
	end
	return nMax + 1;
end

function getSortedActionTypes()
	local tSortedTypes = {};
	for k,_ in pairs(_tAllTypeData) do
		if k ~= "" then
			table.insert(tSortedTypes, k);
		end
	end
	table.sort(tSortedTypes, PowerActionManagerCore.sortfuncActionTypes);
	return tSortedTypes;
end
function sortfuncActionTypes(sType1, sType2)
	local nOrder1 = _tAllTypeData[sType1].nOrder or 1;
	local nOrder2 = _tAllTypeData[sType2].nOrder or 1;
	if nOrder1 ~= nOrder2 then
		return nOrder1 < nOrder2;
	end
	return sType1 < sType2;
end

function getActionType(node)
	return DB.getValue(node, "type", "");
end
function resolveActionTypeData(node, tData)
	if not tData then
		tData = {};
	end
	tData.sType = PowerActionManagerCore.getActionType(node);
	return tData;
end
function callActionTypeFunction(sFunction, node, tData)
	if not tData or (tData.sType or "") == "" then
		return nil;
	end

	local v = _tAllTypeData[tData.sType] and _tAllTypeData[tData.sType][sFunction];
	if not v then
		v = _tAllTypeData[""] and _tAllTypeData[""][sFunction];
	end
	if not v then
		return nil;
	end

	if type(v) == "function" then
		return v(node, tData);
	end
	return v;
end

function getActionButtonIcons(node, tData)
	local tData = PowerActionManagerCore.resolveActionTypeData(node, tData);
	local sButton1, sButton2 = PowerActionManagerCore.callActionTypeFunction("fnGetButtonIcons", node, tData);
	if sButton1 then
		return sButton1, sButton2;
	end
	return "", "";
end
function getActionText(node, tData)
	local tData = PowerActionManagerCore.resolveActionTypeData(node, tData);
	return PowerActionManagerCore.callActionTypeFunction("fnGetText", node, tData) or "";
end
function getActionTooltip(node, tData)
	local tData = PowerActionManagerCore.resolveActionTypeData(node, tData);
	return PowerActionManagerCore.callActionTypeFunction("fnGetTooltip", node, tData) or "";
end
function performAction(draginfo, node, tData)
	local tData = PowerActionManagerCore.resolveActionTypeData(node, tData);
	tData.draginfo = draginfo;
	return PowerActionManagerCore.callActionTypeFunction("fnPerform", node, tData) or "";
end

--
--	Common Functions
--

function getActionEffectTooltip(node, tData)
	if tData and tData.sSubRoll == "duration" then
		return string.format("%s: %s", Interface.getString("power_tooltip_duration"), PowerActionManagerCore.getActionEffectText(node, tData));
	end
	return string.format("%s: %s", Interface.getString("power_tooltip_effect"), PowerActionManagerCore.getActionEffectText(node, tData));
end

function getActionEffectText(node, tData)
	local tOutput = {};

	if tData and tData.sSubRoll == "duration" then
		local nDuration = DB.getValue(node, "durmod", 0);
		if nDuration ~= 0 then
			table.insert(tOutput, tostring(nDuration) or "");

			local sUnits = DB.getValue(node, "durunit", "");
			if sUnits ~= "" then
				if sUnits == "minute" then
					table.insert(tOutput, "min");
				elseif sUnits == "hour" then
					table.insert(tOutput, "hr");
				elseif sUnits == "day" then
					table.insert(tOutput, "dy");
				else
					table.insert(tOutput, "rd");
				end
			end
		end
		return table.concat(tOutput, " ");
	end

	local sLabel = DB.getValue(node, "label", "");
	if sLabel ~= "" then
		table.insert(tOutput, sLabel);

		local sApply = DB.getValue(node, "apply", "");
		if sApply == "action" then
			table.insert(tOutput, "[ACTION]");
		elseif sApply == "roll" then
			table.insert(tOutput, "[ROLL]");
		elseif sApply == "single" then
			table.insert(tOutput, "[SINGLE]");
		end

		local sTargeting = DB.getValue(node, "targeting", "");
		if sTargeting == "self" then
			table.insert(tOutput, "[SELF]");
		end
	end

	return table.concat(tOutput, "; ");
end
