--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function sendToStoreDLC(sProductID)
	if (sProductID or "") == "" then
		ChatManager.SystemMessage("UtilityManager.sendToStoreDLC - Missing product ID");
		return;
	end

	local sUser = Utility.encodeURL(Session.UserName);
	local sURL = "https://server.fantasygrounds.com/gostore_dlc?productid=" .. sProductID .. "&username=" .. sUser;
	Interface.openWindow("url", sURL)
end
function sendToStoreAssetType(sAssetType)
	if (sAssetType or "") == "" then
		ChatManager.SystemMessage("UtilityManager.sendToStoreAssetType - Missing asset type");
		return;
	end

	local sURL = "https://server.fantasygrounds.com/gostore?source=" .. sAssetType .. "&ruleset=" .. Session.RulesetName;
	Interface.openWindow("url", sURL)
end
function sendToStoreDLCModule(sProductID)
	if (sProductID or "") == "" then
		ChatManager.SystemMessage("UtilityManager.sendToStoreDLCModule - Missing product ID");
		return;
	end

	local sURL = "https://www.fantasygrounds.com/store/product.php?id=" .. sProductID;
	Interface.openWindow("url", sURL);
end
function sendToLink(sURL)
	if (sURL or "") == "" then
		ChatManager.SystemMessage("UtilityManager.sendToLink - Missing URL");
		return;
	end

	Interface.openWindow("url", sURL);
end
function sendToHelpLink(sURL)
	if (sURL or "") == "" then
		ChatManager.SystemMessage("UtilityManager.sendToHelpLink - Missing URL");
		return;
	end

	if StringManager.startsWith(sURL, "https://server.fantasygrounds.com/links_ruleset.php") then
		sURL = sURL .. "&ruleset=" .. Session.RulesetName;
	end
	Interface.openWindow("url", sURL);
end

-- NOTE: Converts table into numerically indexed table, based on sort order of original keys. Original keys are not included in new table.
function getSortedTable(aOriginal)
	local aSorter = {};
	for k,_ in pairs(aOriginal) do
		table.insert(aSorter, k);
	end
	table.sort(aSorter);

	local aSorted = {};
	for _,v in ipairs(aSorter) do
		table.insert(aSorted, aOriginal[v]);
	end
	return aSorted;
end

-- NOTE: Performs a structure deep copy. Does not copy meta table information.
function copyDeep(v)
	if type(v) == "table" then
		local v2 = {};
		for kTable, vTable in next, v, nil do
			v2[UtilityManager.copyDeep(kTable)] = UtilityManager.copyDeep(vTable);
		end
		return v2;
	end

	return v;
end

-- 	XML elements must follow these naming rules:
-- 		Element names are case-sensitive
-- 		Element names must start with a letter or underscore
-- 		Element names cannot start with the letters xml (or XML, or Xml, etc)
-- 		Element names can contain letters, digits, hyphens, underscores, and periods
-- 		Element names cannot contain spaces
-- NOTE: Will also trim extra spaces on beginning, end or in middle
function encodeXMLTag(s)
	if not s then
		return nil;
	end
	return StringManager.trim(s):gsub("^[^%a_]", "_"):gsub("^[xX][mM][lL]", "_"):gsub("%s%s+", " "):gsub("[^%w-_]", "_");
end
function encodeXML(s)
	if not s then
		return "";
	end
	return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;"):gsub("'", "&apos;");
end

--
--	Database helper functions
--

function parsePath(sPath)
	if (sPath or "") == "" then
		return {}, "";
	end

	local sModule = nil;
	local tModuleSplit = StringManager.splitByPattern(sPath, "@");
	if #tModuleSplit > 1 then
		sModule = table.concat(tModuleSplit, "@", 2);
	end
	local tPath = StringManager.splitByPattern(tModuleSplit[1], "%.");

	return tPath, sModule or "";
end
function isPathMatch(sPath1, sPath2, bCompareModule)
	local tPath1, sModule1 = UtilityManager.parsePath(sPath1);
	local tPath2, sModule2 = UtilityManager.parsePath(sPath2);

	if bCompareModule then
		if sModule1 ~= sModule2 then
			return false;
		end
	end

	if #tPath1 ~= #tPath2 then
		return false;
	end

	for k,v in ipairs(tPath1) do
		if (v ~= "*") and (tPath2[k] ~= "*") then
			if (v ~= tPath2[k]) then
				return false;
			end
		end
	end

	return true;
end
function doesPathStartWith(sPath, sStartPath)
	local tPath1 = UtilityManager.parsePath(sPath);
	local tPath2 = UtilityManager.parsePath(sStartPath);

	if #tPath1 < #tPath2 then
		return false;
	end

	for k,v in ipairs(tPath1) do
		if not tPath2[k] then
			break;
		end
		if (v ~= "*") and (tPath2[k] ~= "*") then
			if (v ~= tPath2[k]) then
				return false;
			end
		end
	end

	return true;
end
function getPathSplit(sPath)
	local tPath = UtilityManager.parsePath(sPath);
	if #tPath == 0 then
		return "";
	end
	return unpack(tPath);
end

function parseDataBaseNodePath(vNode)
	return UtilityManager.parsePath(DB.getPath(vNode));
end
function isDataBaseNodePathMatch(vNode, sMatchPath, bCompareModule)
	return UtilityManager.isPathMatch(DB.getPath(vNode), DB.getPath(sMatchPath), bCompareModule);
end
function doesDataBasePathStartWith(vNode, sStartPath)
	return UtilityManager.doesPathStartWith(DB.getPath(vNode), DB.getPath(sStartPath));
end
function getDataBaseNodePathSplit(vNode)
	return UtilityManager.getPathSplit(DB.getPath(vNode));
end

function getNodeAccessLevel(vNode)
	if vNode then
		if DB.isPublic(vNode) then
			return 2;
		else
			if Session.IsHost then
				local sOwner = DB.getOwner(vNode);
				local aHolderNames = {};
				local aHolders = DB.getHolders(vNode);
				for _,sHolder in pairs(aHolders) do
					if (sOwner or "") ~= "" then
						if sOwner ~= sHolder then
							table.insert(aHolderNames, sHolder);
						end
					else
						table.insert(aHolderNames, sHolder);
					end
				end

				if #aHolderNames > 0 then
					return 1, aHolderNames;
				end
			end
		end
	end
	return 0;
end

function getNodeSortedChildren(...)
	return UtilityManager.getSortedTable(DB.getChildren(...));
end

function getRootNodeName(vNode)
	local nodeResult = nil;
	local nodeTemp = nil;
	if type(vNode) == "databasenode" then
		nodeTemp = vNode;
	elseif type(vNode) == "string" then
		nodeTemp = DB.findNode(vNode);
	end
	while nodeTemp do
		nodeResult = nodeTemp;
		nodeTemp = DB.getParent(nodeTemp);
	end
	if nodeResult then
		return DB.getName(nodeResult);
	end
	return "";
end

function getSortedNodeList(tChildList, tFields, tDesc)
	local tSorter = {};
	for k,v in pairs(tChildList) do
		local tChild = {
			index = k,
			sPath = DB.getPath(v),
			tFields = {},
			tDesc = tDesc,
		};
		for _,sField in ipairs(tFields or {}) do
			table.insert(tChild.tFields, DB.getValue(v, sField));
		end
		table.insert(tSorter, tChild);
	end
	table.sort(tSorter, UtilityManager.sortfuncSortedNodeList);

	local tSorted = {};
	for _,v in ipairs(tSorter) do
		table.insert(tSorted, tChildList[v.index]);
	end
	return tSorted;
end
function sortfuncSortedNodeList(a, b)
	for kFieldA,vFieldA in ipairs(a.tFields) do
		if vFieldA ~= b.tFields[kFieldA] then
			if a.tDesc and a.tDesc[kFieldA] then
				return vFieldA > b.tFields[kFieldA];
			end
			if b.tFields[kFieldA] then
				return vFieldA < b.tFields[kFieldA];
			end
		end
	end
	return a.sPath < b.sPath;
end

--
--	Window/control helper functions
--

function resolveLinkedControl(c)
	if not c or not c.window then
		return;
	end
	if c.isEmpty() then
		local sControl = c.getName();
		local sValue = DB.getValue(c.window.getDatabaseNode(), sControl, "");
		if sValue == "" then
			local cLink = c.linktarget and c.window[c.linktarget[1]] or c.window.link;
			if cLink then
				sValue = DB.getValue(cLink.getTargetDatabaseNode(), sControl, "");
			end
		end
		c.setValue(sValue);
	end
end

function resolvePipedStringRes(s)
	if (s or "") == "" then
		return "";
	end
	local tSplitRes = StringManager.split(s, "|", true);
	local tResults = {};
	for k,v in ipairs(tSplitRes) do
		tResults[k] = Interface.getString(v);
	end
	return table.concat(tResults, "|");
end

function getFontColorSansAlpha(sFont)
	local sFontColor;
	if Interface.isFont(sFont) then
		sFontColor = Interface.getFontColor(sFont);
	else
		sFontColor = Interface.getFontColor("sheettext");
	end
	if sFontColor then
		if #sFontColor == 8 then
			return sFontColor:sub(3,8);
		end
		if #sFontColor == 9 then
			return sFontColor:sub(4,9);
		end
	end
	return "000000";
end
function getControlFontColor(w, sControl)
	if w[sControl] then
		return UtilityManager.getFontColorSansAlpha(w[sControl].getFont());
	end
	return UtilityManager.getFontColorSansAlpha("sheettext");
end
function getFullAndDisabledFontColors(sFont, sDisabledAlpha)
	local sFontColorSansAlpha = UtilityManager.getFontColorSansAlpha(sFont);
	return string.format("FF%s", sFontColorSansAlpha), string.format("%s%s", sDisabledAlpha or "80", sFontColorSansAlpha);
end
function getFullAndDisabledControlFontColors(w, sControl, sDisabledAlpha)
	if w[sControl] then
		return UtilityManager.getFullAndDisabledFontColors(w[sControl].getFont(), sDisabledAlpha);
	end
	return UtilityManager.getFullAndDisabledFontColors("sheettext", sDisabledAlpha);
end

--
--  Callback helper functions
--

function registerCallback(t, fn)
	if not t or not fn then
		return;
	end
	for _,v in ipairs(t) do
		if v == fn then
			return;
		end
	end
	table.insert(t, fn);
end
function unregisterCallback(t, fn)
	if not t or not fn then
		return;
	end
	for k,v in ipairs(t) do
		if v == fn then
			table.remove(t, k);
			return;
		end
	end
end
function performCallbacks(t, ...)
	if not t then
		return nil;
	end
	for _,fn in ipairs(t) do
		if fn(...) then
			return true;
		end
	end
	return nil;
end
function performAllCallbacks(t, ...)
	if not t then
		return;
	end
	for _,fn in ipairs(t) do
		fn(...);
	end
end

function registerKeyCallback(t, sKey, fn)
	if not t or not sKey then
		return;
	end
	if not t[sKey] then
		t[sKey] = {};
	end
	UtilityManager.registerCallback(t[sKey], fn);
end
function unregisterKeyCallback(t, sKey, fn)
	if not t or not sKey then
		return;
	end
	if t[sKey] then
		UtilityManager.unregisterCallback(t[sKey], fn);
		if #(t[sKey]) == 0 then
			t[sKey] = nil;
		end
	end
end
function performKeyCallbacks(t, sKey, ...)
	if not t or not sKey then
		return;
	end
	if t[sKey] then
		return UtilityManager.performCallbacks(t[sKey], ...);
	end
	return nil;
end
function performAllKeyCallbacks(t, sKey, ...)
	if not t or not sKey then
		return;
	end
	if t[sKey] then
		UtilityManager.performAllCallbacks(t[sKey], ...);
	end
end

function setKeySingleCallback(t, sKey, fn)
	if not t or not sKey then
		return;
	end
	t[sKey] = fn;
end
function getKeySingleCallback(t, sKey)
	if not t or not sKey then
		return nil;
	end
	return t[sKey];
end
function hasKeySingleCallback(t, sKey)
	return (UtilityManager.getKeySingleCallback(t, sKey) ~= nil);
end
function performKeySingleCallback(t, sKey, ...)
	if not t or not sKey then
		return nil;
	end
	local fn = t[sKey];
	if fn then
		return fn(...);
	end
	return nil;
end

--
--	OOB Helpers
--

function encodeRollToOOB(rRoll)
	local msgOOB = UtilityManager.copyDeep(rRoll);

	for k,v in pairs(rRoll) do
		if type(v) == "boolean" then
			if v then
				msgOOB[k] = 1;
			else
				msgOOB[k] = 0;
			end
		end
	end

	return msgOOB;
end
function decodeRollFromOOB(msgOOB)
	local rRoll = UtilityManager.copyDeep(msgOOB);

	for k,_ in pairs(msgOOB) do
		if k:match("n[A-Z]") then
			rRoll[k] = tonumber(rRoll[k]) or nil;
		elseif k:match("b[A-Z]") then
			rRoll[k] = ((tonumber(rRoll[k]) or 0) == 1);
		end
	end

	return rRoll;
end

--
--	Token Resolution Helpers
--

function resolveDisplayToken(sToken, sName)
	if ((sToken or "") ~= "") and Interface.isToken(sToken) then
		return sToken;
	end

	local sLetter;
	if (sName or "") ~= "" then
		sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
	end
	if not sLetter then
		sLetter = "z";
	end
	return string.format("tokens/Medium/%s.png@Letter Tokens", sLetter:lower());
end
function resolveActorToken(v)
	local rActor = ActorManager.resolveActor(v);

	local sToken;
	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		sToken = DB.getValue(nodeCT, "token", "");
	end
	if (sToken or "") == "" then
		local nodeCreature = ActorManager.getCreatureNode(rActor);
		if nodeCreature then
			sToken = DB.getValue(nodeCreature, "token", "");
		end
	end
	return UtilityManager.resolveDisplayToken(sToken, ActorManager.getDisplayName(rActor));
end
function getAssetBaseFileName(s)
	local sSansModule = StringManager.split(s, "@")[1];
	local tSplit = StringManager.split(sSansModule, "/");
	if #tSplit <= 0 then
		return s;
	end

	local tNameSplit = StringManager.split(tSplit[#tSplit], ".");
	if #tNameSplit <= 0 or not StringManager.contains({"png", "PNG", "jpg", "JPG", "jpeg", "JPEG", "webp", "WEBP", "webm", "WEBM"}, tNameSplit[#tNameSplit]) then
		return tSplit[#tSplit];
	end

	tNameSplit[#tNameSplit] = nil;
	return table.concat(tNameSplit, ".");
end

--
--	Lua Table manipulation
--

function simplifyEncode(t, sKeyLimiter)
	if sKeyLimiter then
		local tLimiter = t[sKeyLimiter];
		if tLimiter and type(tLimiter) == "table" then
			UtilityManager.helperSimplifyEncode(t, tLimiter, "_" .. sKeyLimiter);
			t[sKeyLimiter] = nil;
		end
	else
		local tRemove = {};
		for k,v in pairs(t) do
			if type(v) == "table" then
				UtilityManager.helperSimplifyEncode(t, v, "_" .. k);
				table.insert(tRemove, k);
			end
		end
		for _,v in ipairs(tRemove) do
			t[v] = nil;
		end
	end
end
function helperSimplifyEncode(t, tEncode, sKeyPrefix)
	if type(tEncode) ~= "table" then
		t[sKeyPrefix] = tEncode;
	else
		for k,v in pairs(tEncode) do
			UtilityManager.helperSimplifyEncode(t, v, sKeyPrefix .. "_" .. k);
		end
	end
end
function simplifyDecode(t, sKeyLimiter)
	local sKeyPrefix = "_";
	if sKeyLimiter then
		sKeyPrefix = sKeyPrefix .. sKeyLimiter;
	end

	local tAdd = {};
	local tRemove = {};
	for k,v in pairs(t) do
		if StringManager.startsWith(k, sKeyPrefix) then
			local tSplit = StringManager.splitByPattern(k, "_", true);
			-- First split will be empty; make sure there is more
			if #tSplit > 1 then
				local tTemp = tAdd;
				for i = 2, #tSplit - 1 do
					local sKey = tSplit[i];
					if sKey:match("^%d+$") then
						sKey = tonumber(sKey);
					end
					if tTemp[sKey] then
						tTemp = tTemp[sKey];
					else
						local tNew = {};
						tTemp[sKey] = tNew;
						tTemp = tNew;
					end
				end
				local sKey = tSplit[#tSplit];
				if sKey:match("^%d+$") then
					sKey = tonumber(sKey);
				end
				if v:match("^[%+%-]?%d+$") then
					v = tonumber(v);
				end
				tTemp[sKey] = v;
			end
			tRemove[k] = true;
		end
	end
	for k,_ in pairs(tRemove) do
		t[k] = nil;
	end
	for k,v in pairs(tAdd) do
		t[k] = v;
	end
end

--
--	Key/Value Pair String Encoding
--
--	NOTE: Key/Value Pairs separated by |&|; Key/Value separated by |=|
--

function encodeKVPToString(t)
	if not t then
		return "";
	end
	local tResults = {};
	for k,v in pairs(t) do
		table.insert(tResults, string.format("%s|=|%s", tostring(k), tostring(v)));
	end
	return table.concat(tResults, "|&|");
end
function decodeKVPFromString(s)
	if not s then
		return {};
	end
	local tResults = {};
	local tKVPSplit = StringManager.splitByPattern(s, "|&|", true);
	for _,sKVP in ipairs(tKVPSplit) do
		local tKVSplit = StringManager.splitByPattern(sKVP, "|=|", true);
		if #tKVSplit == 2 then
			tResults[tKVSplit[1]] = tKVSplit[2];
		end
	end
	return tResults;
end

--
--	DEPRECATED (2024-05-28)
--

function getNodeCategory(vNode)
	Debug.console("UtilityManager.getNodeCategory - DEPRECATED - 2024-05-28 - Use DB.getCategory");
	ChatManager.SystemMessage("UtilityManager.getNodeCategory - DEPRECATED - 2024-05-28 - Contact ruleset/extension/forge author");
	return DB.getCategory(vNode) or "";
end
function getNodeModule(vNode)
	Debug.console("UtilityManager.getNodeModule - DEPRECATED - 2024-05-28 - Use DB.getModule");
	ChatManager.SystemMessage("UtilityManager.getNodeModule - DEPRECATED - 2024-05-28 - Contact ruleset/extension/forge author");
	return DB.getModule(vNode) or "";
end

-- DEPRECATED - 2025-08

function getWindowDatabasePath(w)
	return WindowManager.getDatabasePath(w);
end
function getTopWindow(w)
	return WindowManager.getTopWindow(w);
end
function safeDeleteWindow(w)
	WindowManager.safeDelete(w);
end
