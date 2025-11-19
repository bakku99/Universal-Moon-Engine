--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

MAX_COLUMNS = 30;

function onInit()
	Comm.registerSlashHandler("rollon", TableManager.processTableRoll, "[table name] <-c [column name]> <-d dice> <-hide>");
	ActionsManager.registerResultHandler("table", TableManager.onTableRoll);
end

function performRoll(draginfo, rActor, rTableRoll, bUseModStack)
	-- If dice or modifier not provided, then use the right one for this table
	if (#(rTableRoll.aDice or {}) == 0) and ((rTableRoll.nMod or 0) == 0) then
		rTableRoll.aDice, rTableRoll.nMod = TableManager.getTableDice(rTableRoll.nodeTable);
	end

	local rRoll = {};
	rRoll.sType = "table";
	rRoll.sDesc = string.format("[%s] %s", Interface.getString("table_tag"), StringManager.capitalizeAll(DB.getValue(rTableRoll.nodeTable, "name", "")));
	if rTableRoll.nColumn and rTableRoll.nColumn > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [" .. rTableRoll.nColumn .. " - " .. DB.getValue(rTableRoll.nodeTable, "labelcol" .. rTableRoll.nColumn) .. "]";
	end
	rRoll.sNodeTable = DB.getPath(rTableRoll.nodeTable);

	rRoll.aDice = rTableRoll.aDice;
	rRoll.nMod = rTableRoll.nMod;

	if rTableRoll.bSecret then
		rRoll.bSecret = rTableRoll.bSecret;
	elseif Session.IsHost then
		rRoll.bSecret = (DB.getValue(rTableRoll.nodeTable, "hiderollresults", 0) == 1);
	end
	if rTableRoll.sOutput then
		rRoll.sOutput = rTableRoll.sOutput;
		if rTableRoll.nodeOutput then
			rRoll.sOutputNode = DB.getPath(rTableRoll.nodeOutput);
		end
	elseif Session.IsHost then
		rRoll.sOutput = DB.getValue(rTableRoll.nodeTable, "output", "");
	end

	-- Add modifier stack
	if bUseModStack and not ModifierStack.isEmpty() then
		local sStackDesc, nStackMod = ModifierStack.getStack(true);
		rRoll.sDesc = rRoll.sDesc .. " [" .. sStackDesc .. "]";
		rRoll.nMod = rRoll.nMod + nStackMod;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getTableDice(nodeTable)
	local aDice = DB.getValue(nodeTable, "dice", {});
	local nMod;
	if type(aDice) == "string" then
		aDice = DiceManager.convertStringToDice(aDice);
	end

	if #aDice == 0 then
		aDice, nMod = TableManager.getTableDiceFromRowData(nodeTable);
	else
		nMod = DB.getValue(nodeTable, "mod", 0);

		-- Backward compatibility fix for old module data
		if (#aDice == 2) then
			if (aDice[1] == "d10") and (aDice[2] == "d100") and (nMod == 0) then
				local aRowDice = TableManager.getTableDiceFromRowData(nodeTable);
				if (#aRowDice == 1) and (aRowDice[1] == "d100") then
					table.remove(aDice, 1);
				end
			elseif (aDice[1] == "d100") and (aDice[2] == "d10") and (nMod == 0) then
				local aRowDice = TableManager.getTableDiceFromRowData(nodeTable);
				if (#aRowDice == 1) and (aRowDice[1] == "d100") then
					table.remove(aDice, 2);
				end
			end
		end
	end

	return aDice, nMod;
end
function getTableDiceFromRowData(nodeTable)
	local aDice = {};
	local nMod = 0;

	local nMin = nil;
	local nMax = nil;
	for _,v in ipairs(DB.getChildList(nodeTable, "tablerows")) do
		local nFrom = DB.getValue(v, "fromrange", 0);
		local nTo = DB.getValue(v, "torange", 0);

		if nTo == 0 then
			nMax = math.max(nFrom, nMax or nFrom);
		else
			nMax = math.max(nTo, nMax or nTo);
		end
		nMin = math.min(nFrom, nMin or nFrom);
	end

	local nRange = 0;
	if nMin and nMin == 0 then
		nMin = 1;
	end
	if nMin and nMax then
		nRange = math.max(nMax - nMin + 1, 0);
	end

	if nRange == 2 then
		table.insert(aDice, "d2");
	elseif nRange == 3 then
		table.insert(aDice, "d3");
	elseif nRange == 4 then
		table.insert(aDice, "d4");
	elseif nRange == 6 then
		table.insert(aDice, "d6");
	elseif nRange == 8 then
		table.insert(aDice, "d8");
	elseif nRange == 10 then
		table.insert(aDice, "d10");
	elseif nRange == 12 then
		table.insert(aDice, "d12");
	elseif nRange == 20 then
		table.insert(aDice, "d20");
	elseif nRange == 100 then
		table.insert(aDice, "d100");
	elseif nRange > 0 then
		table.insert(aDice, "d" .. nRange);
	end

	if nMin then
		nMod = nMod + (nMin - 1);
	end

	nMod = nMod + DB.getValue(nodeTable, "mod", 0);
	return aDice, nMod;
end
function findTable(sTable)
	return RecordManager.findRecordByString("table", "name", sTable);
end
function findColumn(nodeTable, sColumn)
	local nResultColumn = 0;

	if sColumn and sColumn ~= "" then
		local sFind = StringManager.trim(sColumn);
		local nColumns = DB.getValue(nodeTable, "resultscols", 0);
		for i = 1, nColumns do
			if StringManager.trim(DB.getValue(nodeTable, "labelcol" .. i, "")) == sFind then
				nResultColumn = i;
				break;
			end
		end
	end

	return nResultColumn;
end
function getResults(nodeTable, nTotal, nColumn)
	local nodeResults = nil;
	local nMin, nMax;
	local nodeMin, nodeMax;
	for _,v in ipairs(DB.getChildList(nodeTable, "tablerows")) do
		local nFrom = DB.getValue(v, "fromrange", 0);
		local nTo = DB.getValue(v, "torange", 0);
		if nTo == 0 then
			nTo = nFrom;
		end
		if (nTotal >= nFrom) and (nTotal <= nTo) then
			nodeResults = DB.getChild(v, "results");
			break;
		end
		if not nMin or nFrom < nMin then
			nMin = nFrom;
			nodeMin = DB.getChild(v, "results");
		end
		if not nMax or nTo > nMax then
			nMax = nFrom;
			nodeMax = DB.getChild(v, "results");
		end
	end
	if not nodeResults then
		if nMin and nTotal < nMin then
			nodeResults = nodeMin;
		elseif nMax and nTotal > nMax then
			nodeResults = nodeMax;
		end
	end
	if not nodeResults then
		return nil;
	end

	local aChildren = DB.getChildren(nodeResults);
	local aKeys = {};
	for k,_ in pairs(aChildren) do
		table.insert(aKeys, k);
	end
	table.sort(aKeys);

	local aResults = {};
	if (nColumn or 0) > 0 then
		if not aKeys[nColumn] then
			return nil;
		end
		local rResult = {};
		rResult.sText = StringManager.trim(DB.getValue(aChildren[aKeys[nColumn]], "result", ""));
		rResult.sClass, rResult.sRecord = DB.getValue(aChildren[aKeys[nColumn]], "resultlink");
		rResult.sLabel = DB.getValue(nodeTable, "labelcol" .. nColumn);
		table.insert(aResults, rResult);
	else
		for k = 1, #aKeys do
			local rResult = {};
			rResult.sText = StringManager.trim(DB.getValue(aChildren[aKeys[k]], "result", ""));
			rResult.sClass, rResult.sRecord = DB.getValue(aChildren[aKeys[k]], "resultlink");
			rResult.sLabel = DB.getValue(nodeTable, "labelcol" .. k);
			table.insert(aResults, rResult);
		end
	end

	return aResults;
end

local _tTableRollStack = {};
function onTableRoll(rSource, _, rRoll)
	local nodeTable = DB.findNode(rRoll.sNodeTable);
	if not nodeTable then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_tablematch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end

	local sOutput = rRoll.sOutput or "";
	local nTotal = ActionsManager.total(rRoll);
	local nColumn = 0;
	local sPattern2 = "%[" .. Interface.getString("table_tag") .. "%] [^[]+%[(%d+) %- ([^)]*)%]";
	local sColumn = (rRoll.sDesc or ""):match(sPattern2);
	if sColumn then
		nColumn = tonumber(sColumn) or 0;
	end

	local aResults = TableManager.getResults(nodeTable, nTotal, nColumn);
	if not aResults then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_columnmatch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end

	for _,v in ipairs(aResults) do
		v.aMult = {};

		v.aTableLinks = {};
		v.aOtherLink = nil;

		if (v.sClass or "") ~= "" then
			if v.sClass == "table" then
				table.insert(v.aTableLinks, { sClass = v.sClass, sRecord = v.sRecord });
			else
				v.aOtherLink = { sClass = v.sClass, sRecord = v.sRecord };
			end
		end

		if v.sText ~= "" then
			local sResult = v.sText;

			local aMathResults = {};
			for nStartTag, sTag, nEndTag in v.sText:gmatch("()%[([^%]]+)%]()") do
				local bMult = false;
				local sPotentialRoll = sTag;
				if sPotentialRoll:match("x$") then
					sPotentialRoll = sPotentialRoll:sub(1, -2);
					bMult = true;
				end
				if DiceManager.isDiceMathString(sPotentialRoll) then
					local nMathResult = DiceManager.evalDiceMathExpression(sPotentialRoll);
					if bMult then
						table.insert(v.aMult, nMathResult);
						if sOutput == "parcel" then
							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "" });
						else
							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = string.format("[%dx]", nMathResult) });
						end
					else
						table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
					end
				else
					local nodeTable = TableManager.findTable(sTag);
					if nodeTable then
						table.insert(v.aTableLinks, { sClass = "table", sRecord = DB.getPath(nodeTable) });
					end
				end
			end
			for i = #aMathResults,1,-1 do
				sResult = sResult:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sResult:sub(aMathResults[i].nEnd);
			end

			v.sText = sResult;
		end
	end

	local nodeTarget = nil;
	local bTopTable = true;
	if sOutput ~= "" and rRoll.sOutputNode then
		nodeTarget = DB.findNode(rRoll.sOutputNode);
		if nodeTarget then
			bTopTable = false; -- Only relevant for parcel and story output
		end
	end

	local sResultName = string.format("[%s] %s", Interface.getString("table_result_tag"), DB.getValue(nodeTable, "name", ""));
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Build chat messages with links as needed
	local aAddChatMessages = {};
	rMessage.shortcuts = {};
	if sOutput == "story" then
		if not nodeTarget then
			local sRootMapping = RecordDataManager.getDataPathRoot("story");
			nodeTarget = DB.createChild(sRootMapping);
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				RecordManager.openRecordWindow("story", nodeTarget);
			end
		end

		if bTopTable then
			local sClass = RecordDataManager.getRecordTypeDisplayClass("story");
			table.insert(rMessage.shortcuts, { description = sResultName, class = sClass, recordname = DB.getPath(nodeTarget) });
		end

		local sAddDesc = "";
		for _,v in ipairs(aResults) do
			local sText = v.sText;
			sText = sText:gsub("%[[^%]]*%]", "");
			sText = StringManager.trim(sText);
			if sText:match("^%([%d]*%)$") then
				sText = "";
			end

			if sText ~= "" and sText ~= "-" then
				if v.aOtherLink then
					sAddDesc = sAddDesc .. "<linklist><link class=\"" ..
						UtilityManager.encodeXML(v.aOtherLink.sClass) ..
						"\" recordname=\"" .. UtilityManager.encodeXML(v.aOtherLink.sRecord) .. "\">" ..
						UtilityManager.encodeXML(sText) ..
						"</link></linklist>";
				elseif (bTopTable or (#v.aTableLinks == 0)) then
					if sText:match("^<[biu]>") then
						sAddDesc = sAddDesc .. "<p>" .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>") .. "</p>";
					elseif sText:match("^<[ph]>") then
						sAddDesc = sAddDesc .. UtilityManager.encodeXML(sText):gsub("&lt;(/?[phbiu])&gt;", "<%1>");
					else
						sAddDesc = sAddDesc .. "<list><li>" .. UtilityManager.encodeXML(sText) .. "</li></list>";
					end
				end
			end
		end

		if sAddDesc ~= "" then
			DB.setValue(nodeTarget, "text", "formattedtext", DB.getValue(nodeTarget, "text", "") .. sAddDesc);
		end

	elseif sOutput == "parcel" then
		if not nodeTarget then
			local sRootMapping = RecordDataManager.getDataPathRoot("treasureparcel");
			nodeTarget = DB.createChild(sRootMapping);
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				RecordManager.openRecordWindow("treasureparcel", nodeTarget);
			end
		end

		if bTopTable then
			local sClass = RecordDataManager.getRecordTypeDisplayClass("treasureparcel");
			table.insert(rMessage.shortcuts, { description = sResultName, class = sClass, recordname = DB.getPath(nodeTarget) });
		end

		for _,v in ipairs(aResults) do
			local bHandled = false;
			if v.aOtherLink then
				bHandled = ItemManager.addLinkToParcel(nodeTarget, v.aOtherLink.sClass, v.aOtherLink.sRecord, v.aMult[1]);
			end
			if not bHandled and (#v.aTableLinks == 0) then
				ItemManager.handleString(nodeTarget, v.sText, v.aMult[1]);
			end
		end

	elseif sOutput == "encounter" then
		if not nodeTarget then
			local sRootMapping = RecordDataManager.getDataPathRoot("battle");
			nodeTarget = DB.createChild(sRootMapping);
			if nodeTarget then
				DB.setValue(nodeTarget, "name", "string", sResultName);
				RecordManager.openRecordWindow("battle", nodeTarget);
			end
		end

		if bTopTable then
			local sClass = RecordDataManager.getRecordTypeDisplayClass("battle");
			table.insert(rMessage.shortcuts, { description = sResultName, class = sClass, recordname = DB.getPath(nodeTarget) });
		end

		for _,v in ipairs(aResults) do
			if v.aOtherLink then
				NPCManager.addLinkToBattle(nodeTarget, v.aOtherLink.sClass, v.aOtherLink.sRecord, v.aMult[1]);
			end
		end

	else -- Chat output
		rMessage.text = rMessage.text .. " = ";

		local bResultLinks = false;
		for _,v in ipairs(aResults) do
			if v.aOtherLink then
				bResultLinks = true;
			end
		end

		for _,v in ipairs(aResults) do
			local sResult = v.sText;
			if ((v.sLabel or "") ~= "") and (#aResults > 1) then
				sResult = v.sLabel .. " = " .. sResult;
			end

			local rResultMsg = { font = "systemfont", secret = rMessage.secret };
			if bResultLinks then
				rResultMsg.text = sResult;
				if v.aOtherLink then
					rResultMsg.shortcuts = {};
					table.insert(rResultMsg.shortcuts, { class = v.aOtherLink.sClass, recordname = v.aOtherLink.sRecord });
				end
			else
				rResultMsg.text = sResult;
			end

			table.insert(aAddChatMessages, rResultMsg);
		end
	end

	-- Output any chat messages
	if rMessage.secret then
		Comm.addChatMessage(rMessage);
		for _,vMsg in ipairs(aAddChatMessages) do
			Comm.addChatMessage(vMsg);
		end
	else
		Comm.deliverChatMessage(rMessage);
		for _,vMsg in ipairs(aAddChatMessages) do
			Comm.deliverChatMessage(vMsg);
		end
	end

	-- Follow cascading table links
	local aLocalTableStack = {};
	for _,v in ipairs(aResults) do
		for kLink,vLink in ipairs(v.aTableLinks) do
			local nMult = v.aMult[kLink] or 1;

			for _ = 1, nMult do
				local rTableRoll = {};
				rTableRoll.nodeTable = DB.findNode(vLink.sRecord);
				rTableRoll.bSecret = rRoll.bSecret;
				rTableRoll.sOutput = rRoll.sOutput;
				rTableRoll.nodeOutput = nodeTarget;

				table.insert(aLocalTableStack, rTableRoll);
			end
		end
	end
	for i = #aLocalTableStack, 1, -1 do
		table.insert(_tTableRollStack, aLocalTableStack[i]);
	end
	if #_tTableRollStack > 0 then
		local rTableRoll = table.remove(_tTableRollStack);
		if not rTableRoll then
			local sTable = DB.getValue(nodeTable, "name", "");
			ChatManager.SystemMessage(Interface.getString("table_error_sequentialfail") .. " (" .. sTable .. ")");
			_tTableRollStack = {};
			return;
		end

		if not Interface.isDiceRollingDisabled() then
			Interface.disableDiceRolling(true);
			TableManager.performRoll(nil, rSource, rTableRoll, false);
			Interface.disableDiceRolling(false);
		else
			TableManager.performRoll(nil, rSource, rTableRoll, false);
		end
	end
end
function processTableRoll(_, sParams)
	sParams = StringManager.trim(sParams);

	local bHide = false;
	if sParams:match(" %-hide") then
		sParams = sParams:gsub(" %-hide", "");
		bHide = true;
	end

	local sDice = sParams:match(" %-d(.+)$");
	if sDice then
		sDice = StringManager.trim(sDice);
		sParams = sParams:gsub(" %-d.+$", "");
	end

	local sColumn = sParams:match(" %-c(.+)$");
	if sColumn then
		sColumn = StringManager.trim(sColumn);
		sParams = sParams:gsub(" %-c.+$", "");
	end

	local sTable = StringManager.trim(sParams);
	if sTable == "" then
		ChatManager.SystemMessage("Usage: /rollon tablename -c [column name] [-d dice] [-hide]");
		return;
	end
	local nodeTable = TableManager.findTable(sTable);
	if not nodeTable then
		ChatManager.SystemMessage(Interface.getString("table_error_lookupfail") .. " (" .. sTable .. ")");
		return;
	end

	local rTableRoll = {};
	rTableRoll.nodeTable = nodeTable;
	if bHide then
		rTableRoll.bSecret = true;
	end
	rTableRoll.nColumn = TableManager.findColumn(nodeTable, sColumn);
	if sDice then
		rTableRoll.aDice, rTableRoll.nMod = DiceManager.convertStringToDice(sDice);
	else
		rTableRoll.aDice, rTableRoll.nMod = TableManager.getTableDice(nodeTable);
	end
	TableManager.performRoll(nil, nil, rTableRoll, false);
end

function createRows(nodeNewTable, nRows, nStep, bSpecial)
	local nodeTableRows = DB.createChild(nodeNewTable, "tablerows");

	if bSpecial then
		local nFrom;
		local nTo = 0;

		for i = 1, nRows do
			local nodeRow = DB.createChild(nodeTableRows);

			if i == 1 then
				nFrom = 1;
				nTo = 1;
			elseif i == nRows then
				nFrom = nTo + 1;
				nTo = nFrom;
			else
				if i == 2 then
					nFrom = (i * tonumber(nStep));
				else
					nFrom = nTo + 1;
				end
				nTo = nFrom + 1;
			end

			DB.setValue(nodeRow, "fromrange", "number", nFrom);
			DB.setValue(nodeRow, "torange", "number", nTo);
		end
	else
		for i = 1, nRows do
			local nodeRow = DB.createChild(nodeTableRows);

			local nFrom = i;
			if nFrom ~= 1 then
				nFrom = (i * tonumber(nStep) + 1) - tonumber(nStep);
			end
			local nTo = i * tonumber(nStep);

			DB.setValue(nodeRow, "fromrange", "number", nFrom);
			DB.setValue(nodeRow, "torange", "number", nTo);
		end
	end
end
