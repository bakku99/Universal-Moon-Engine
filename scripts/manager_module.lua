--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onTabletopInit()
	ModuleManager.initModuleData();

	Module.addEventHandler("onModuleLoad", ModuleManager.onModuleLoad);
	Module.addEventHandler("onModuleUnload", ModuleManager.onModuleUnload);

	Module.addEventHandler("onModuleAdded", ModuleManager.onModuleAdded);
	Module.addEventHandler("onModuleUpdated", ModuleManager.onModuleUpdated);
	Module.addEventHandler("onModuleRemoved", ModuleManager.onModuleRemoved);
end

--
-- 	Data Management
--

local _tAllModuleInfo = {};
function getAllModuleInfo()
	return _tAllModuleInfo;
end
function getModuleInfo(sModule)
	return _tAllModuleInfo[sModule];
end
function setModuleInfo(sModule, tInfo)
	_tAllModuleInfo[sModule] = tInfo;
end
function isModuleInstalled(sModule)
	return (self.getModuleInfo(sModule) ~= nil);
end
function getModuleDisplayName(sModule)
	if (sModule or "") == "" then
		return Interface.getString("campaign");
	end
	local tInfo = Module.getModuleInfo(sModule);
	if not tInfo then
		return sModule;
	end
	return tInfo.displayname or sModule;
end

local _tLoadedModuleInfo = {};
function getAllLoadedModuleInfo()
	return _tLoadedModuleInfo;
end
function getLoadedModuleInfo(sModule)
	return _tLoadedModuleInfo[sModule];
end
function setLoadedModuleInfo(sModule, tInfo, bSkipUpdateLibrary)
	_tLoadedModuleInfo[sModule] = tInfo;

	if tInfo then
		if ((tInfo.category or "") == "") then
			local nodeChild = DB.getChildList("library@" .. sModule)[1];
			if nodeChild then
				tInfo.category = DB.getValue(nodeChild, "categoryname", "");
			end
		end
		ModuleManager.setLibraryCategory(tInfo.category, bSkipUpdateLibrary);
	else
		ModuleManager.rebuildLoadedCategories();
	end
end
function isModuleLoaded(sModule)
	return (self.getLoadedModuleInfo(sModule) ~= nil)
end

local _tAuxBookInfo = {};
function getAllAuxBookInfo()
	return _tAuxBookInfo;
end
function getAuxBookInfo(sModule)
	return _tAuxBookInfo[sModule];
end
function setAuxBookInfo(sModule, tInfo)
	_tAuxBookInfo[sModule] = tInfo;
	if tInfo then
		ModuleManager.onLibraryAuxBookAdded(sModule, tInfo);
	else
		ModuleManager.onLibraryAuxBookRemoved(sModule);
	end
end

local _tLibraryCategories = {};
function getLibraryCategories()
	return _tLibraryCategories;
end
function setLibraryCategories(tCategories)
	_tLibraryCategories = tCategories;
end
function setLibraryCategory(sCategory, bSkipUpdateLibrary)
	if (sCategory or "") ~= "" then
		if not _tLibraryCategories[sCategory] then
			_tLibraryCategories[sCategory] = true;
			if not bSkipUpdateLibrary then
				ModuleManager.onLibraryCategoryAdded(sCategory);
			end
		end
	end
end
function isLibraryCategory(sCategory)
	return (_tLibraryCategories[sCategory] ~= nil)
end

--
-- 	Module Management
--

function initModuleData()
	for _,sModule in ipairs(Module.getModules()) do
		local tInfo = Module.getModuleInfo(sModule);
		if tInfo then
			ModuleManager.setModuleInfo(sModule, tInfo);
			if tInfo.loaded then
				ModuleManager.setLoadedModuleInfo(sModule, tInfo, true);
			end
		end
	end
end

function onModuleLoad(sModule)
	local tInfo = ModuleManager.getModuleInfo(sModule);
	if tInfo and tInfo.loaded then
		ModuleManager.setLoadedModuleInfo(sModule, tInfo);
		ModuleManager.onLibraryModuleLoad(sModule, tInfo);
	end
end
function onModuleUnload(sModule)
	if ModuleManager.isModuleLoaded(sModule) then
		ModuleManager.setLoadedModuleInfo(sModule, nil);
		ModuleManager.onLibraryModuleUnload(sModule);
	end
end
function onModuleAdded(sModule)
	local tInfo = Module.getModuleInfo(sModule);
	if tInfo then
		ModuleManager.setModuleInfo(sModule, tInfo);
		if tInfo.loaded then
			ModuleManager.setLoadedModuleInfo(sModule, tInfo);
			ModuleManager.onLibraryModuleLoad(sModule, tInfo);
		end
		ModuleManager.onModuleActivationAdded(sModule);
	end
end
function onModuleUpdated(sModule)
	local tInfo = Module.getModuleInfo(sModule);
	if tInfo then
		ModuleManager.setModuleInfo(sModule, tInfo);
		ModuleManager.onModuleActivationUpdated(sModule);
	end
end
function onModuleRemoved(sModule)
	ModuleManager.setModuleInfo(sModule, nil);
	ModuleManager.setLoadedModuleInfo(sModule, nil);
	ModuleManager.onLibraryModuleUnload(sModule);
	ModuleManager.onModuleActivationRemoved(sModule);
end

function rebuildLoadedCategories()
	local tNewCategories = {};
	for _,tInfo in pairs(ModuleManager.getAllLoadedModuleInfo()) do
		if (tInfo.category or "") ~= "" then
			tNewCategories[tInfo.category] = true;
		end
	end
	for _,tInfo in pairs(ModuleManager.getAllAuxBookInfo()) do
		if (tInfo.category or "") ~= "" then
			tNewCategories[tInfo.category] = true;
		end
	end

	local wLibrary = ModuleManager.getLibraryWindow();
	if wLibrary then
		for sCategory,_ in pairs(ModuleManager.getLibraryCategories()) do
			if not tNewCategories[sCategory] then
				ModuleManager.onLibraryCategoryRemoved(sCategory, wLibrary);
			end
		end
		for sCategory,_ in pairs(tNewCategories) do
			if not ModuleManager.isLibraryCategory(sCategory) then
				ModuleManager.onLibraryCategoryAdded(sCategory, wLibrary);
			end
		end
	end

	ModuleManager.setLibraryCategories(tNewCategories);
end

--
-- 	Window Management
--

function getLibraryWindow()
	return Interface.findWindow("library", "");
end
function initLibraryWindow(wLibrary)
	for sModule,tInfo in pairs(ModuleManager.getAllLoadedModuleInfo()) do
		ModuleManager.onLibraryModuleLoad(sModule, tInfo, wLibrary);
	end
	for sModule,tInfo in pairs(ModuleManager.getAllAuxBookInfo()) do
		ModuleManager.onLibraryAuxBookAdded(sModule, tInfo, wLibrary);
	end

	for sCategory,_ in pairs(ModuleManager.getLibraryCategories()) do
		ModuleManager.onLibraryCategoryAdded(sCategory, wLibrary);
	end
end
function onLibraryModuleLoad(sModule, tInfo, wLibrary)
	if not wLibrary then
		wLibrary = ModuleManager.getLibraryWindow();
		if not wLibrary then
			return;
		end
	end

	local wBook = wLibrary.booklist.createWindow();
	if not wBook then
		return;
	end

	wBook.setData(sModule, tInfo);
end
function onLibraryModuleUnload(sModule, wLibrary)
	if not wLibrary then
		wLibrary = ModuleManager.getLibraryWindow();
		if not wLibrary then
			return;
		end
	end

	for _,wBook in ipairs(wLibrary.booklist.getWindows()) do
		if (wBook.getClass() == "library_booklistentry") and not wBook.isAuxBook() and (wBook.getName() == sModule) then
			wBook.close();
			break;
		end
	end
end
function onLibraryAuxBookAdded(sModule, tInfo, wLibrary)
	if not wLibrary then
		wLibrary = ModuleManager.getLibraryWindow();
		if not wLibrary then
			return;
		end
	end

	local wBook = wLibrary.booklist.createWindow();
	if not wBook then
		return;
	end

	wBook.setAuxBookData(sModule, tInfo);
end
function onLibraryAuxBookRemoved(sModule, wLibrary)
	if not wLibrary then
		wLibrary = ModuleManager.getLibraryWindow();
		if not wLibrary then
			return;
		end
	end

	for _,wBook in ipairs(wLibrary.booklist.getWindows()) do
		if (wBook.getClass() == "library_booklistentry") and wBook.isAuxBook() and (wBook.getName() == sModule) then
			wBook.close();
			break;
		end
	end
end
function onLibraryCategoryAdded(sCategory, wLibrary)
	if not wLibrary then
		wLibrary = ModuleManager.getLibraryWindow();
		if not wLibrary then
			return;
		end
	end

	local wCategory = wLibrary.booklist.createWindowWithClass("library_booklistcategory");
	if not wCategory then
		return;
	end

	wCategory.setData(sCategory);
end
function onLibraryCategoryRemoved(sCategory, wLibrary)
	if not wLibrary then
		wLibrary = ModuleManager.getLibraryWindow();
		if not wLibrary then
			return;
		end
	end

	for _,wCategory in ipairs(wLibrary.booklist.getWindows()) do
		if (wCategory.getClass() == "library_booklistcategory") and (wCategory.getCategory() == sCategory) then
			wCategory.close();
			break;
		end
	end
end
function onLibraryModuleActivate(sModule)
	local wLibrary = ModuleManager.getLibraryWindow();
	if not wLibrary then
		return;
	end

	local nodeSource = nil;
	if (sModule or "") ~= "" then
		local nodeChild = DB.getChildList("library@" .. sModule)[1];
		if nodeChild then
			nodeSource = DB.getChild(nodeChild, "entries");
		end
	end
	wLibrary.list.setDatabaseNode(nodeSource);
	wLibrary.list.setEmptyText(Interface.getString("library_empty_pages"));
end
function onLibraryAuxBookActivate(sModule)
	local wLibrary = ModuleManager.getLibraryWindow();
	if not wLibrary then
		return;
	end

	local tInfo = ModuleManager.getAuxBookInfo(sModule) or {};
	wLibrary.list.setDatabaseNode(DB.findNode(tInfo.sourcepath));
	wLibrary.list.setEmptyText(Interface.getString("library_empty_pages"));
end

function getModuleActivationWindow()
	return Interface.findWindow("moduleselection", "");
end
function onModuleActivationAdded()
	local wModules = ModuleManager.getModuleActivationWindow();
	if not wModules then
		return;
	end

	ListManager.refreshDisplayList(wModules);
end
function onModuleActivationUpdated(sModule)
	local wModules = ModuleManager.getModuleActivationWindow();
	if not wModules then
		return;
	end

	local bHandled = false;
	for _,wModule in ipairs(wModules.list.getWindows()) do
		if wModule.getModuleName() == sModule then
			local tInfo = ModuleManager.getModuleInfo(sModule);
			if wModules.isFilteredRecord(tInfo) then
				wModule.update(tInfo);
				bHandled = true;
			end
			break;
		end
	end
	if not bHandled then
		ListManager.refreshDisplayList(wModules);
	end
end
function onModuleActivationRemoved()
	local wModules = ModuleManager.getModuleActivationWindow();
	if not wModules then
		return;
	end

	ListManager.refreshDisplayList(wModules);
end

--
-- 	Module Link Identification and Loading Helpers
--

function handleRecordModulesLoad(tRecordPaths, fCallback, vCustom)
	local tNonInstalledModules, tNonLoadedModules, tMissingWildcardPaths = ModuleManager.checkRecordModules(tRecordPaths);
	local bErrorExit = false;
	if #tMissingWildcardPaths > 0 then
		ChatManager.SystemMessage(Interface.getString("module_message_missinglink_wildcard"));
		for _,v in ipairs(tMissingWildcardPaths) do
			ChatManager.SystemMessage(string.format("  (%s)", v));
		end
		bErrorExit = true;
	end
	if #tNonInstalledModules > 0 then
		ChatManager.SystemMessage(Interface.getString("module_message_noinstall"));
		for _,v in ipairs(tNonInstalledModules) do
			ChatManager.SystemMessage(string.format("  (%s)", v));
		end
		bErrorExit = true;
	end
	if bErrorExit then
		return true;
	end
	if #tNonLoadedModules > 0 then
		local wSelect = Interface.openWindow("module_dialog_missinglink", "");
		wSelect.initialize(tNonLoadedModules, fCallback, vCustom);
		return true;
	end
	return false;
end
function checkRecordModules(tRecordPaths)
	local tRecordModules = {};
	local tMissingWildcardPaths = {};
	for _,v in ipairs(tRecordPaths) do
		local sModule = v:match("@(.*)$");
		if sModule then
			if sModule == "*" then
				if not DB.findNode(v) then
					table.insert(tMissingWildcardPaths, v);
				end
			elseif sModule ~= "" then
				tRecordModules[sModule] = true;
			end
		end
	end
	local tNonInstalledModules = {};
	local tNonLoadedModules = {};
	for k,_ in pairs(tRecordModules) do
		if not ModuleManager.isModuleInstalled(k) then
			table.insert(tNonInstalledModules, k);
		elseif not ModuleManager.isModuleLoaded(k) then
			table.insert(tNonLoadedModules, k);
		end
	end
	table.sort(tNonInstalledModules);
	table.sort(tNonLoadedModules);
	return tNonInstalledModules, tNonLoadedModules, tMissingWildcardPaths;
end

--
--	ACTIONS
--

function performRevert(sModule)
	if (sModule or "") == "" then
		return;
	end

	local tData = {
		sTitleRes = "revert_dialog_title",
		sModule = sModule,
		fnCallback = ModuleManager.handleRevertDialog,
	};
	local sDisplayText = Interface.getString("revert_module_dialog_text");
	local sDisplayName = ModuleManager.getModuleInfo(sModule).displayname;
	tData.sText = string.format("%s\r\r%s", sDisplayText, sDisplayName);

	DialogManager.openDialog("dialog_okcancel", tData);
end
function handleRevertDialog(sResult, tData)
	if sResult == "ok" then
		Module.revert(tData.sModule);
	end
end
