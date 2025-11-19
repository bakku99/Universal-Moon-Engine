--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- SEE NOTES IN STORY MANAGER SCRIPT

function onTabletopInit()
	StoryIndexManager.initStoryRecordIndex();
	StoryIndexManager.initBookPaths();
	StoryIndexManager.initCampaignIndexes();
end

function initCampaignIndexes()
	StoryIndexManager.initCampaignIndexHelper("");
	for sModule, _ in pairs(ModuleManager.getAllLoadedModuleInfo()) do
		StoryIndexManager.initCampaignIndexHelper(sModule);
	end
end
function initCampaignIndexHelper(sModule)
	StoryIndexManager.rebuildBookIndex(sModule);
	StoryIndexManager.rebuildNonBookIndex(sModule);
end

--
--	BOOK - DATA - INDEX
--

function initBookPaths()
	StoryIndexManager.addStandardBookPaths();
	StoryIndexManager.addBookPathHandlers();
end
function addStandardBookPaths()
	StoryIndexManager.addBookPath(StoryManager.DEFAULT_BOOK_INDEX);
end
function addBookPathHandlers()
	for _,sPath in ipairs(StoryIndexManager.getBookPaths()) do
		local sPageListPath = string.format("%s.%s.*.%s.*.%s@*", sPath, StoryManager.DEFAULT_BOOK_INDEX_CHAPTER_LIST, StoryManager.DEFAULT_BOOK_INDEX_SECTION_LIST, StoryManager.DEFAULT_BOOK_INDEX_PAGE_LIST);
		DB.addHandler(sPageListPath, "onChildDeleted", StoryIndexManager.onBookIndexPageDeleted);
		DB.addHandler(DB.getPath(sPageListPath, "*.order"), "onUpdate", StoryIndexManager.onBookIndexPageOrderChanged);
	end
	Module.addEventHandler("onModuleLoad", self.onModuleLoad);
	Module.addEventHandler("onModuleUnload", self.onModuleUnload);
end
function onBookIndexPageDeleted(nodeList)
	StoryIndexManager.rebuildBookIndex(DB.getModule(nodeList));
end
function onBookIndexPageOrderChanged(nodeOrder)
	local sModule = DB.getModule(nodeOrder);
	local wBook = StoryManager.findBook(sModule);
	if not wBook then
		return;
	end
	local sFocusSection, nFocusChunk = StoryManager.getBookFocusSectionAndChunk(wBook);
	local sPageSection, nOldChunk = StoryIndexManager.getBookPageSectionAndChunk(DB.getPath(DB.getParent(nodeOrder)));

	StoryIndexManager.rebuildBookIndex(sModule);

	if sFocusSection == sPageSection then
		local _, nNewChunk = StoryIndexManager.getBookPageSectionAndChunk(DB.getPath(DB.getParent(nodeOrder)));
		if (nOldChunk == nFocusChunk) and (nNewChunk == nFocusChunk) then
			StoryManager.applyBookFocusSort(sModule);
		elseif (nOldChunk ~= nNewChunk) and ((nOldChunk == nFocusChunk) or (nNewChunk == nFocusChunk)) then
			StoryManager.rebuildBookFocus(sModule);
		end
	end
end
function onModuleLoad(sModule)
	StoryIndexManager.rebuildBookIndex(sModule);
	StoryIndexManager.rebuildNonBookIndex(sModule);
end
function onModuleUnload(sModule)
	StoryIndexManager.clearBookIndex(sModule);
	StoryIndexManager.clearNonBookIndex(sModule);
end

local _tBookPaths = {};
function getBookPaths()
	return _tBookPaths;
end
function addBookPath(s)
	if (s or "") == "" then
		return;
	end
	table.insert(_tBookPaths, s);
end

--
--	STORY RECORD - INDEX
--

function initStoryRecordIndex()
	local tMappings = RecordDataManager.getDataPaths("story");
	for _,sMapping in ipairs(tMappings) do
		DB.addHandler(DB.getPath(sMapping, "*@*"), "onAdd", StoryIndexManager.onStoryRecordAdd);
		DB.addHandler(DB.getPath(sMapping, "*@*"), "onDelete", StoryIndexManager.onStoryRecordDelete);
		DB.addHandler(DB.getPath(sMapping, "*.name@*"), "onUpdate", StoryIndexManager.onStoryRecordRename);
	end
end
function onStoryRecordAdd(node)
	StoryIndexManager.addToStoryRecordIndex(node);
end
function onStoryRecordDelete(node)
	StoryIndexManager.removeFromStoryRecordIndex(node);
	if DB.getModule(node) == "" then
		StoryIndexManager.deleteBookIndexRecordByStoryRecord(DB.getPath(node));
	end
end
function onStoryRecordRename(nodeName)
	StoryIndexManager.updateStoryRecordIndexName(DB.getParent(nodeName));
end

local _tStoryRecords = {};
function getStoryRecordIndex(sModule, bInit)
	local tRecords = _tStoryRecords[sModule or ""];
	if not tRecords then
		if bInit then
			tRecords = {};
			_tStoryRecords[sModule or ""] = tRecords;
			RecordManager.callForEachModuleRecord("story", sModule, StoryIndexManager.addToStoryRecordIndex);
		else
			return;
		end
	end
	return tRecords;
end
function addToStoryRecordIndex(node)
	if not node then
		return;
	end

	local sModule = DB.getModule(node);
	local tRecords = StoryIndexManager.getStoryRecordIndex(sModule);
	if not tRecords then
		return;
	end

	local tRecord = {};
	tRecord.vNode = node;
	tRecord.sDisplayName = DB.getValue(node, "name", "");
	tRecord.sDisplayNameLower = Utility.convertStringToLower(tRecord.sDisplayName);
	tRecords[node] = tRecord;
end
function removeFromStoryRecordIndex(node)
	local sModule = DB.getModule(node);
	local tRecords = StoryIndexManager.getStoryRecordIndex(sModule);
	if not tRecords then
		return;
	end

	tRecords[node] = nil;
end
function updateStoryRecordIndexName(node)
	local sModule = DB.getModule(node);
	local tRecords = StoryIndexManager.getStoryRecordIndex(sModule);
	if not tRecords then
		return;
	end
	local tRecord = tRecords[node];
	if not tRecord then
		return;
	end
	tRecord.sDisplayName = DB.getValue(node, "name", "");
	tRecord.sDisplayNameLower = Utility.convertStringToLower(tRecord.sDisplayName);
end

--
--	STORY BOOKS - INDEX
--

-- NOTE: Book pages are added via index order; so no need to sort additionally
function rebuildBookIndex(sModule)
	local nodeIndex = StoryIndexManager.getBookIndexNode(sModule);
	if not nodeIndex then
		StoryIndexManager.clearBookIndex(sModule);
		return;
	end

	local tBookPages = StoryIndexManager.clearBookPages(sModule);
	local tBookSections = StoryIndexManager.clearBookSections(sModule);

	for _,nodeChapter in ipairs(UtilityManager.getSortedNodeList(DB.getChildList(nodeIndex, StoryManager.DEFAULT_BOOK_INDEX_CHAPTER_LIST), { "order" })) do
		for _,nodeSection in ipairs(UtilityManager.getSortedNodeList(DB.getChildList(nodeChapter, StoryManager.DEFAULT_BOOK_INDEX_SECTION_LIST), { "order" })) do
			local nPageIndex = 0;
			for _,nodePage in ipairs(UtilityManager.getSortedNodeList(DB.getChildList(nodeSection, StoryManager.DEFAULT_BOOK_INDEX_PAGE_LIST), { "order" })) do
				local _,sRecord = DB.getValue(nodePage, "listlink", "", "");
				if sRecord ~= "" then
					nPageIndex = nPageIndex + 1;
					local tData = {
						sTargetRecord = sRecord,
						nPageIndex = nPageIndex,
						nSectionChunk = StoryIndexManager.calcBookSectionChunkFromPageIndex(nPageIndex),
						sPageRecord = DB.getPath(nodePage),
						sSectionRecord = DB.getPath(nodeSection),
						sChapterRecord = DB.getPath(nodeChapter),
					};
					table.insert(tBookPages, tData);
				end
			end
			table.insert(tBookSections, { sPath = DB.getPath(nodeSection), nChunks = StoryIndexManager.calcBookSectionChunkFromPageIndex(nPageIndex), });
		end
	end
end
function clearBookIndex(sModule)
	StoryIndexManager.clearBookPages(sModule);
	StoryIndexManager.clearBookSections(sModule);
end
local _tBookIndexPath = {};
function getAllBookIndexNodes()
	local tResults = {};
	for _,sModule in ipairs(Module.getModules()) do
		local node = StoryIndexManager.getBookIndexNode(sModule);
		if node then
			table.insert(tResults, node);
		end
	end
	return tResults;
end
function getBookIndexNode(sModule)
	local sPath = StoryIndexManager.getBookIndexPath(sModule);
	if (sPath or "") == "" then
		return nil;
	end
	return DB.findNode(sPath);
end
function getBookIndexPath(sModule)
	if not _tBookIndexPath[sModule or ""] then
		local node = StoryIndexManager.getBookIndexPathHelper(sModule);
		if node then
			_tBookIndexPath[sModule or ""] = DB.getPath(node);
		else
			_tBookIndexPath[sModule or ""] = string.format("%s@%s", StoryManager.DEFAULT_BOOK_INDEX, sModule or "");
		end
	end
	return _tBookIndexPath[sModule or ""];
end
function getBookIndexPathHelper(sModule)
	for _,sPath in ipairs(StoryIndexManager.getBookPaths()) do
		local node = DB.findNode(string.format("%s@%s", sPath, sModule or ""));
		if node then
			return node;
		end
	end
	return nil;
end
local _tBookPages = {};
function getAllBookPages()
	return _tBookPages;
end
function getBookPages(sModule)
	return _tBookPages[sModule or ""] or {};
end
function clearBookPages(sModule)
	_tBookPages[sModule or ""] = {};
	return _tBookPages[sModule or ""];
end
function getBookPageRecord(sPageRecord)
	if (sPageRecord or "") == "" then
		return nil;
	end
	for _,v in ipairs(StoryIndexManager.getBookPages(DB.getModule(sPageRecord))) do
		if v.sPageRecord == sPageRecord then
			return v;
		end
	end
	return nil;
end
function getBookPageSectionAndChunk(sPageRecord)
	local tPageData = StoryIndexManager.getBookPageRecord(sPageRecord);
	if not tPageData then
		return "", 1;
	end
	return tPageData.sSectionRecord, tPageData.nSectionChunk;
end
local _tBookSections = {};
function getAllBookSections()
	return _tBookSections;
end
function getBookSections(sModule)
	return _tBookSections[sModule or ""] or {};
end
function clearBookSections(sModule)
	_tBookSections[sModule or ""] = {};
	return _tBookSections[sModule or ""];
end
function calcBookSectionChunkFromPageIndex(n)
	return math.max(math.ceil((n or 1) / StoryManager.SECTION_PAGE_BREAK), 1);
end

function getBookModuleFromStoryRecord(sRecord)
	if (sRecord or "") == "" then
		return nil;
	end
	for sModule, _ in pairs(StoryIndexManager.getAllBookPages()) do
		local tBookPages = StoryIndexManager.getBookPages(sModule);
		for _,v in ipairs(tBookPages) do
			if v.sTargetRecord == sRecord then
				return sModule;
			end
		end
	end
	return nil;
end
function isBookStoryRecord(sRecord)
	return (StoryIndexManager.getBookModuleFromStoryRecord(sRecord) ~= nil);
end
function getFirstBookStoryRecord(sModule)
	local tBookPages = StoryIndexManager.getBookPages(sModule);
	if not tBookPages[1] then
		return "";
	end
	return tBookPages[1].sTargetRecord or "";
end
function getPrevBookStoryRecord(sRecord)
	if (sRecord or "") == "" then
		return "";
	end
	for sModule, _ in pairs(StoryIndexManager.getAllBookPages()) do
		local tBookPages = StoryIndexManager.getBookPages(sModule);
		for kPage,v in ipairs(tBookPages) do
			if v.sTargetRecord == sRecord then
				return tBookPages[kPage - 1] and tBookPages[kPage - 1].sTargetRecord or "";
			end
		end
	end
	return "";
end
function getNextBookStoryRecord(sRecord)
	if (sRecord or "") == "" then
		return "";
	end
	for sModule, _ in pairs(StoryIndexManager.getAllBookPages()) do
		local tBookPages = StoryIndexManager.getBookPages(sModule);
		for kPage,v in ipairs(tBookPages) do
			if v.sTargetRecord == sRecord then
				return tBookPages[kPage + 1] and tBookPages[kPage + 1].sTargetRecord or "";
			end
		end
	end
	return "";
end

function getBookIndexPathsFromStoryRecord(sTargetRecord)
	local sModule = StoryIndexManager.getBookModuleFromStoryRecord(sTargetRecord);
	if not sModule then
		return "", "";
	end
	for _,v in ipairs(StoryIndexManager.getBookPages(sModule)) do
		if v.sTargetRecord == sTargetRecord then
			return v.sPageRecord or "", v.sSectionRecord or "", v.nSectionChunk or 1;
		end
	end
	return "", "";
end
function deleteBookIndexRecordByStoryRecord(sRecord)
	if (sRecord or "") == "" then
		return;
	end
	for sModule, _ in pairs(StoryIndexManager.getAllBookPages()) do
		local tBookPages = StoryIndexManager.getBookPages(sModule, true);
		for kPage,v in ipairs(tBookPages) do
			if v.sTargetRecord == sRecord then
				DB.deleteNode(v.sPageRecord);
				table.remove(tBookPages, kPage);
				break;
			end
		end
	end
end

--
--	STORY RECORDS (NON-BOOK) - INDEX
--

-- NOTE: Non-book pages are added in any order; so additional sort needed
function rebuildNonBookIndex(sModule)
	local tRecords = StoryIndexManager.getStoryRecordIndex(sModule, true);
	local tModulePages = StoryIndexManager.clearNonBookPages(sModule);
	for k,v in pairs(tRecords) do
		if not StoryIndexManager.isBookStoryRecord(DB.getPath(k)) then
			local sCategory = DB.getCategory(v.vNode);
			tModulePages[sCategory] = tModulePages[sCategory] or {};
			table.insert(tModulePages[sCategory], v);
		end
	end
	for _,tPages in pairs(tModulePages) do
		table.sort(tPages, StoryIndexManager.sortFuncNonBookIndex);
	end
end
function clearNonBookIndex(sModule)
	StoryIndexManager.clearNonBookPages(sModule);
end
local _tNonBookPages = {};
function getNonBookPages(sModule, sCategory)
	if not _tNonBookPages[sModule or ""] then
		return {};
	end
	return _tNonBookPages[sModule or ""][sCategory or ""] or {};
end
function clearNonBookPages(sModule)
	_tNonBookPages[sModule or ""] = {};
	return _tNonBookPages[sModule or ""];
end
function sortFuncNonBookIndex(a, b)
	if a.sDisplayNameLower ~= b.sDisplayNameLower then
		return a.sDisplayNameLower < b.sDisplayNameLower;
	end

	return DB.getPath(a.vNode) < DB.getPath(b.vNode);
end
function getPrevNonBookPageRecord(sRecord)
	if (sRecord or "") == "" then
		return "";
	end
	local tNonBookPages = StoryIndexManager.getNonBookPages(DB.getModule(sRecord), DB.getCategory(sRecord));
	for kPage,v in ipairs(tNonBookPages) do
		if DB.getPath(v.vNode) == sRecord then
			if tNonBookPages[kPage - 1] then
				return DB.getPath(tNonBookPages[kPage - 1].vNode);
			else
				return "";
			end
		end
	end
	return "";
end
function getNextNonBookPageRecord(sRecord)
	if (sRecord or "") == "" then
		return "";
	end
	local tNonBookPages = StoryIndexManager.getNonBookPages(DB.getModule(sRecord), DB.getCategory(sRecord));
	for kPage,v in ipairs(tNonBookPages) do
		if DB.getPath(v.vNode) == sRecord then
			if tNonBookPages[kPage + 1] then
				return DB.getPath(tNonBookPages[kPage + 1].vNode);
			else
				return "";
			end
		end
	end
	return "";
end

--
--	STORY RECORD - NAVIGATION
--

function getPrevStoryRecord(sRecord)
	local sBookRecord = StoryIndexManager.getPrevBookStoryRecord(sRecord);
	if (sBookRecord or "") ~= "" then
		return sBookRecord;
	end
	return StoryIndexManager.getPrevNonBookPageRecord(sRecord);
end
function getNextStoryRecord(sRecord)
	local sBookRecord = StoryIndexManager.getNextBookStoryRecord(sRecord);
	if (sBookRecord or "") ~= "" then
		return sBookRecord;
	end
	return StoryIndexManager.getNextNonBookPageRecord(sRecord);
end

function getPrevStorySection(sSectionRecord, nChunk)
	local tSections = StoryIndexManager.getBookSections(DB.getModule(sSectionRecord));
	if #tSections == 0 then
		return "", 1;
	end

	for k,v in ipairs(tSections) do
		if v.sPath == sSectionRecord then
			if nChunk <= 1 then
				if not tSections[k - 1] then
					return "", 1;
				end
				return tSections[k - 1].sPath, tSections[k - 1].nChunks;
			end
			return v.sPath, nChunk - 1;
		end
	end
	return "", 1;
end
function getNextStorySection(sSectionRecord, nChunk)
	local tSections = StoryIndexManager.getBookSections(DB.getModule(sSectionRecord));
	if #tSections == 0 then
		return "", 1;
	end

	for k,v in ipairs(tSections) do
		if v.sPath == sSectionRecord then
			if nChunk >= v.nChunks then
				if not tSections[k + 1] then
					return "", 1;
				end
				return tSections[k + 1].sPath, 1;
			end
			return v.sPath, nChunk + 1;
		end
	end
	return "", 1;
end
