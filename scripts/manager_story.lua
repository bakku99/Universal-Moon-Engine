--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

DEFAULT_BOOK_INDEX = "reference.refmanualindex";
DEFAULT_BOOK_CONTENT = "reference.refmanualdata";

DEFAULT_BOOK_INDEX_CHAPTER_LIST = "chapters";
DEFAULT_BOOK_INDEX_SECTION_LIST = "subchapters";
DEFAULT_BOOK_INDEX_PAGE_LIST = "refpages";
SECTION_PAGE_BREAK = 25;

MIN_PAGE_BLOCK_WIDTH = 500;
DEFAULT_IMAGE_SCALE = 100;
MIN_IMAGE_SCALE = 10;
MAX_IMAGE_SCALE = 100;
MISSING_IMAGE_WIDTH = 100;
MAX_IMAGE_FULL_WIDTH = 600;
MAX_IMAGE_COL_WIDTH = 300;

-- NOTE: Assume that only one manual exists per module
-- NOTE: Assume that the reference manual exists in a specific location in each module
--			(unless alternate read-only location specified)

function onTabletopInit()
	StoryManager.registerCopyPasteToolbarButtons();
end

function addBookPath(s)
	StoryIndexManager.addBookPath(s);
end

--
--	GENERAL - THEMING
--

local _sBlockIconColor = "000000";
function setBlockButtonIconColor(s)
	_sBlockIconColor = s;
end
function getBlockButtonIconColor()
	return _sBlockIconColor;
end

--
--	GENERAL - THEMING - FRAMES
--

local _tBlockFrames = {
	"sidebar",
	"text1",
	"text2",
	"text3",
	"text4",
	"text5",
	"book",
	"page",
	"picture",
	"pink",
	"blue",
	"brown",
	"green",
	"yellow",
};

function getBlockFrames()
	return _tBlockFrames;
end
function addBlockFrame(sName)
	if (sName or "") == "" then
		return;
	end
	for _,s in ipairs(_tBlockFrames) do
		if sName == s then
			return;
		end
	end
	table.insert(_tBlockFrames, sName);
end
function removeBlockFrame(sName)
	if (sName or "") == "" then
		return;
	end
	for k,s in ipairs(_tBlockFrames) do
		if sName == s then
			table.remove(_tBlockFrames, k);
			return;
		end
	end
end

--
--	GENERAL - PAGE CONTROLS
--

function updatePageSub(cSub, sRecord)
	if not cSub or not cSub.subwindow then
		return;
	end

	local sModule = DB.getModule(sRecord);
	StoryIndexManager.rebuildBookIndex(sModule);
	StoryIndexManager.rebuildNonBookIndex(sModule);

	local bBookRecord = StoryIndexManager.isBookStoryRecord(sRecord);
	local sPrevPath = StoryIndexManager.getPrevStoryRecord(sRecord) or "";
	local sNextPath = StoryIndexManager.getNextStoryRecord(sRecord) or "";

	if not bBookRecord and (sPrevPath == "") and (sNextPath == "") then
		cSub.setVisible(false);
		return;
	end

	cSub.setVisible(true);
	local bManual = StoryManager.isBookWindow(WindowManager.getTopWindow(cSub.subwindow));
	cSub.subwindow.page_top.setVisible(bBookRecord and not bManual);
	cSub.subwindow.page_prev.setVisible(sPrevPath ~= "");
	cSub.subwindow.page_next.setVisible(sNextPath ~= "");
end

function handlePageTop(w, sRecord)
	local sModule = StoryIndexManager.getBookModuleFromStoryRecord(sRecord);
	if not sModule then
		return;
	end
	local wBook = StoryManager.openBook(sModule);
	if not wBook then
		return;
	end
	StoryManager.activateLink(wBook, w.getClass(), sRecord);
end
function handlePagePrev(w, sRecord)
	if (sRecord or "") == "" then
		return;
	end
	local sPath = StoryIndexManager.getPrevStoryRecord(sRecord) or "";
	if sPath ~= "" then
		StoryManager.activateLink(w, nil, sPath);
	end
end
function handlePageNext(w, sRecord)
	if (sRecord or "") == "" then
		return;
	end
	local sPath = StoryIndexManager.getNextStoryRecord(sRecord) or "";
	if sPath ~= "" then
		StoryManager.activateLink(w, nil, sPath);
	end
end

--
--	GENERAL - SECTION CONTROLS
--

function performBookNavDisplayUpdate(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return;
	end

	local sPrevPath, sNextPath;
	local sRecord, nChunk = StoryManager.getBookFocusSectionAndChunk(w);
	if (sRecord or "") ~= "" then
		sPrevPath = StoryIndexManager.getPrevStorySection(sRecord, nChunk);
		sNextPath = StoryIndexManager.getNextStorySection(sRecord, nChunk);
	end

	local wNav = w.sub_paging.subwindow;
	wNav.section_prev.setVisible((sPrevPath or "") ~= "");
	wNav.section_next.setVisible((sNextPath or "") ~= "");
end
function handleSectionPrev(w)
	local sRecord, nChunk = StoryManager.getBookFocusSectionAndChunk(w);
	if (sRecord or "") == "" then
		return;
	end

	local sPrevRecord, nPrevChunk = StoryIndexManager.getPrevStorySection(sRecord, nChunk);
	StoryManager.handleSectionSelect(w, sPrevRecord, nPrevChunk);
end
function handleSectionNext(w)
	local sRecord, nChunk = StoryManager.getBookFocusSectionAndChunk(w);
	if (sRecord or "") == "" then
		return;
	end

	local sNextRecord, nNextChunk = StoryIndexManager.getNextStorySection(sRecord, nChunk);
	StoryManager.handleSectionSelect(w, sNextRecord, nNextChunk);
end

--
--	GENERAL - LINK HANDLING
--

function onLinkActivated(w, sClass, sRecord)
	if StoryManager.isBookWindow(WindowManager.getTopWindow(w)) then
		StoryManager.activateLink(w, sClass, sRecord, Input.isShiftPressed());
	else
		StoryManager.activateLink(w, sClass, sRecord, true);
	end
end
function activateLink(w, sClass, sRecord, bPopOut)
	local wTop = WindowManager.getTopWindow(w);
	local bManual = StoryManager.isBookWindow(wTop);
	if not bManual then
		local tRecordTypes = RecordDataManager.getAllRecordTypesFromDisplayClass(wTop.getClass());
		if not StringManager.contains(tRecordTypes, "story") then
			if sClass then
				Interface.openWindow(sClass, sRecord);
			end
			return;
		end
	end

	if not sClass then
		sClass = RecordDataManager.getRecordTypeDisplayClass(RecordDataManager.getRecordTypeFromRecordPath(sRecord), sRecord);
		if (sClass or "") == "" then
			sClass = "referencemanualpage";
		end
	end

	if bManual then
		local sBookModule = DB.getModule(wTop.getDatabaseNode());
		local sRecordBookModule = StoryIndexManager.getBookModuleFromStoryRecord(sRecord);
		if not sRecordBookModule or (sBookModule ~= sRecordBookModule) then
			if sRecordBookModule then
				local wNew = Interface.openWindow("reference_manual", string.format("%s@%s", StoryManager.DEFAULT_BOOK_INDEX, sRecordBookModule));
				StoryManager.activateLink(wNew, sClass, sRecord);
			else
				StoryManager.openLinkInNewWindow(sClass, sRecord);
			end
			return;
		end
	end

	if bPopOut then
		StoryManager.openLinkInNewWindow(sClass, sRecord);
	else
		StoryManager.activateEmbeddedLink(wTop, sClass, sRecord);
	end
end
function activateEmbeddedLink(w, sClass, sRecord)
	if not w or (sClass or "") == "" then
		return;
	end

	if not StoryManager.handleEmbeddedStandaloneLink(w, sClass, sRecord) then
		if not StoryManager.handleEmbeddedManualLink(w, sClass, sRecord) then
			StoryManager.handleEmbeddedInlineLink(w, sClass, sRecord);
		end
	end
end
function handleEmbeddedStandaloneLink(w, sClass, sRecord)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual or not StringManager.contains({ "encounter", "referencemanualpage", }, sClass) then
		local sRecordType = RecordDataManager.getRecordTypeFromDisplayClass(sClass);
		if sRecordType ~= "story" then
			if (sClass or "") ~= "" then
				Interface.openWindow(sClass, sRecord);
			end
			return true;
		end
	end
	return false;
end
function handleEmbeddedManualLink(w, _, sRecord)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return false;
	end

	local sPagePath, sSectionPath, nChunk = StoryIndexManager.getBookIndexPathsFromStoryRecord(sRecord);
	if (sPagePath == "") or (sSectionPath == "") then
		return false;
	end

	if not StoryManager.handleSectionSelect(w, sSectionPath, nChunk) then
		return false;
	end

	StoryManager.handlePageScroll(w, sPagePath);
	return true;
end
function handleEmbeddedInlineLink(w, sClass, sRecord)
	local wNew = Interface.openWindow(sClass, sRecord);
	if not wNew then
		return false;
	end

	if (w.getDatabaseNode() == wNew.getDatabaseNode()) then
		return true;
	end

	local nWinX,nWinY = w.getPosition();
	local nWinW,nWinH = w.getSize();
	wNew.setPosition(nWinX, nWinY);
	wNew.setSize(nWinW, nWinH);
	w.close();
	return true;
end
function openLinkInNewWindow(sClass, sRecord)
	if StringManager.contains({ "story_book_page_advanced", "reference_manualtextwide", }, sClass) then
		sClass = "referencemanualpage";
	elseif sClass == "story_book_page_simple" then
		sClass = "encounter";
	end
	Interface.openWindow(sClass, sRecord);
end

function handleSectionSelect(w, sSectionPath, nChunk, bForceRebuild)
	if (sSectionPath or "") == "" then
		return false;
	end
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return false;
	end

	w.content.setValue("story_book_section", sSectionPath);

	local cList = w.content.subwindow.list;
	local sCurrPath, nCurrChunk = cList.getData();
	if bForceRebuild or (sCurrPath ~= sSectionPath) or (nChunk ~= nCurrChunk) then
		cList.setData(sSectionPath, nChunk);
		cList.closeAll();
		for _,tPageData in ipairs(StoryIndexManager.getBookPages(DB.getModule(sSectionPath))) do
			if tPageData.sSectionRecord == sSectionPath and tPageData.nSectionChunk == nChunk then
				cList.createWindow(tPageData.sPageRecord);
			end
		end
	end

	StoryManager.handleBookScroll(w);
	StoryManager.performBookIndexDisplayUpdate(w);
	StoryManager.performBookNavDisplayUpdate(w);
	return true;
end
function handlePageScroll(w, sPagePath)
	if (sPagePath or "") == "" then
		return;
	end
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return;
	end

	for _,wChild in ipairs(w.content.subwindow.list.getWindows(true)) do
		if sPagePath == wChild.getDatabasePath() then
			w.content.subwindow.list.scrollToWindow(wChild, nil, true);
			break;
		end
	end
end

--
--	GENERAL - UTILITY
--

function isBookWindow(w)
	return (w.getClass() == "reference_manual");
end

function getWindowOrderValue(w)
	return DB.getValue(w.getDatabaseNode(), "order", 0);
end
function setWindowOrderValue(w, nOrder)
	DB.setValue(w.getDatabaseNode(), "order", "number", nOrder);
end

function updateOrderValues(cList)
	local tChildRecords = {};
	for _,wChild in ipairs(cList.getWindows()) do
		local nodeChild = wChild.getDatabaseNode();
		table.insert(tChildRecords, { win = wChild, sName = DB.getName(nodeChild), nOrder = DB.getValue(nodeChild, "order", 0) });
	end
	table.sort(tChildRecords, function (a, b) if a.nOrder ~= b.nOrder then return a.nOrder < b.nOrder; end return a.sName < b.sName end);

	local tResults = {};
	for kChildWinRecord,tChildWinRecord in ipairs(tChildRecords) do
		if tChildWinRecord.nOrder ~= kChildWinRecord then
			StoryManager.setWindowOrderValue(tChildWinRecord.win, kChildWinRecord);
		end
		tResults[kChildWinRecord] = tChildWinRecord.win;
	end
	return tResults;
end

--
--	BOOK - UI - INDEX
--

function openBook(sModule)
	local node = StoryIndexManager.getBookIndexNode(sModule);
	if not node then
		if Session.IsHost and ((sModule or "") == "") then
			node = DB.createNode(StoryManager.DEFAULT_BOOK_INDEX);
		end
		if not node then
			return nil;
		end
	end
	return Interface.openWindow("reference_manual", node);
end
function findBook(sModule)
	local node = StoryIndexManager.getBookIndexNode(sModule);
	if not node then
		return nil;
	end
	return Interface.findWindow("reference_manual", node);
end
function rebuildBookFocus(sModule)
	local wBook = StoryManager.findBook(sModule);
	if not wBook then
		return;
	end
	local sFocusSection, nFocusChunk = StoryManager.getBookFocusSectionAndChunk(wBook);
	StoryManager.handleSectionSelect(wBook, sFocusSection, nFocusChunk, true);
end
function applyBookFocusSort(sModule)
	local wBook = StoryManager.findBook(sModule);
	if not wBook then
		return;
	end
	local cList = wBook.content.subwindow and wBook.content.subwindow.list;
	if not cList then
		return;
	end
	cList.applySort();
end
function performBookDisplayInit(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return;
	end

	StoryManager.handleBookTitleInit(w);
	if not StoryManager.loadBookViewState(w) then
		StoryManager.handleBookFirstPageInit(w);
	end
end
function performBookDisplayClose(w)
	StoryManager.saveBookViewState(w);
end
function handleBookTitleInit(w)
	local tModuleInfo = Module.getModuleInfo(DB.getModule(w.getDatabaseNode()));
	local sModuleDisplay = tModuleInfo and tModuleInfo.displayname or Interface.getString("campaign");
	local sTitle = string.format("%s - %s", Interface.getString("library_recordtype_single_story_book"), sModuleDisplay);
	w.title.setValue(sTitle);
	w.setTooltipText(sTitle);
end
function handleBookFirstPageInit(w)
	local sPath = StoryIndexManager.getFirstBookStoryRecord(DB.getModule(w.getDatabaseNode()));
	if sPath ~= "" then
		StoryManager.activateLink(w, nil, sPath);
	end
end
function loadBookViewState(w)
	local sRecord = w.getDatabasePath();
	if (sRecord or "") == "" then
		return false;
	end

	local sClass = w.getClass();
	local tState = CampaignRegistry and CampaignRegistry.windowstate and
			CampaignRegistry.windowstate[sClass] and CampaignRegistry.windowstate[sClass][sRecord];
	if not tState or ((tState.sPageRecord or "") == "") then
		return false;
	end

	local sPageBookSection, nPageBookChunk = StoryIndexManager.getBookPageSectionAndChunk(tState.sPageRecord);
	if not StoryManager.handleSectionSelect(w, sPageBookSection, nPageBookChunk, true) then
		return false;
	end
	StoryManager.handlePageScroll(w, tState.sPageRecord);
	return true;
end
function saveBookViewState(w)
	if not CampaignRegistry then
		return;
	end
	local sRecord = w.getDatabasePath();
	if (sRecord or "") == "" then
		return;
	end
	local sClass = w.getClass();
	local sPageRecord = StoryManager.getBookFocusPage(w);
	if sPageRecord ~= "" then
		CampaignRegistry.windowstate = CampaignRegistry.windowstate or {};
		CampaignRegistry.windowstate[sClass] = CampaignRegistry.windowstate[sClass] or {};
		CampaignRegistry.windowstate[sClass][sRecord] = { sPageRecord = sPageRecord, };
	else
		local tState = CampaignRegistry and CampaignRegistry.windowstate
				and CampaignRegistry.windowstate[sClass] and CampaignRegistry.windowstate[sClass][sRecord];
		if tState then
			CampaignRegistry.windowstate[sClass][sRecord] = nil;
		end
	end
end

function getBookIndexWindow(w)
	return w and w.sub_index and w.sub_index.subwindow;
end
function performBookIndexLockModeChanged(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return;
	end

	if StoryManager.isBookIndexFiltered(w) then
		StoryManager.clearBookIndexFilter(w);
	else
		StoryManager.performBookIndexDisplayUpdate(w);
	end
end

function performBookIndexDisplayUpdate(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return;
	end

	StoryManager.handleBookIndexDisplayControls(w);

	if StoryManager.isBookIndexFiltered(w) then
		StoryManager.handleBookIndexDisplaySearch(w);
	elseif StoryManager.isBookIndexLocked(w) then
		StoryManager.handleBookIndexDisplayStandard(w);
	else
		StoryManager.handleBookIndexDisplayEdit(w);
	end
end
function handleBookIndexDisplayControls(w)
	local bIndexVisible = w.sub_index.isVisible();
	local bReadOnly = WindowManager.getReadOnlyState(w.getDatabaseNode());
	local bFiltered = StoryManager.isBookIndexFiltered(w);

	local cLock = StoryManager.getBookIndexLockControl(w);
	if cLock then
		cLock.setVisible(bIndexVisible and not bFiltered);
	end

	local cFilter = StoryManager.getBookIndexFilterControl(w);
	if cFilter then
		cFilter.setVisible(bIndexVisible and bReadOnly);
	end
end
function handleBookIndexDisplaySearch(w)
	local wIndex = StoryManager.getBookIndexWindow(w);
	if not wIndex then
		return;
	end

	local sFilter = StoryManager.getBookIndexFilter(w);

	for _,wChapter in ipairs(wIndex.list.getWindows()) do
		local bChapterMatch = false;
		for _,wSection in ipairs(wChapter.list.getWindows()) do
			local bSectionMatch = false;
			for _,wPage in ipairs(wSection.list.getWindows()) do
				local bPageMatch = true;
				if sFilter ~= "" then
					local sKeyWordsLower = wPage.keywords.getValue():lower();
					for sWord in sFilter:gmatch("%w+") do
						if not sKeyWordsLower:find(sWord, 0, true) then
							bPageMatch = false;
						end
					end
				end
				wPage.hidden.setValue(bPageMatch and 0 or 1);
				if bPageMatch then
					bSectionMatch = true;
				end
			end
			wSection.hidden.setValue(bSectionMatch and 0 or 1);
			wSection.list.setVisible(bSectionMatch);
			wSection.list.applyFilter();
			if bSectionMatch then
				bChapterMatch = true;
			end
		end
		wChapter.hidden.setValue(bChapterMatch and 0 or 1);
		wChapter.list.setVisible(bChapterMatch);
		wChapter.list.applyFilter();
	end
	wIndex.list.applyFilter();

	local bEmpty = (wIndex.list.getWindowCount(true) == 0);
	wIndex.label_empty.setVisible(bEmpty);
	wIndex.label_empty.setValue(Interface.getString("story_book_index_empty_search"));
end
function handleBookIndexDisplayStandard(w)
	local wIndex = StoryManager.getBookIndexWindow(w);
	if not wIndex then
		return;
	end

	local _,sSectionPath = w.content.getValue();
	for _,wChapter in ipairs(wIndex.list.getWindows()) do
		for _,wSection in ipairs(wChapter.list.getWindows()) do
			local bSectionMatch = (wSection.getDatabasePath() == sSectionPath);
			for _,wPage in ipairs(wSection.list.getWindows()) do
				wPage.hidden.setValue(0);
			end
			wSection.hidden.setValue(0);
			wSection.list.setVisible(bSectionMatch);
			wSection.list.applyFilter();
		end
		wChapter.hidden.setValue(0);
		wChapter.list.setVisible(true);
		wChapter.list.applyFilter();
	end
	wIndex.list.applyFilter(true);

	local bEmpty = (wIndex.list.getWindowCount(true) == 0);
	wIndex.label_empty.setVisible(bEmpty);
	wIndex.label_empty.setValue(Interface.getString("story_book_index_empty"));
end
function handleBookIndexDisplayEdit(w)
	local wIndex = StoryManager.getBookIndexWindow(w);
	if not wIndex then
		return;
	end

	for _,wChapter in ipairs(wIndex.list.getWindows()) do
		for _,wSection in ipairs(wChapter.list.getWindows()) do
			for _,wPage in ipairs(wSection.list.getWindows()) do
				wPage.hidden.setValue(0);
			end
			wSection.hidden.setValue(0);
			wSection.list.setVisible(true);
			wSection.list.applyFilter();
		end
		wChapter.hidden.setValue(0);
		wChapter.list.setVisible(true);
		wChapter.list.applyFilter();
	end
	wIndex.list.applyFilter(true);

	wIndex.label_empty.setVisible(false);
	wIndex.label_empty.setValue("");
end

function refreshIndexHighlight(w)
	StoryManager.performBookIndexPageHighlight(w, StoryManager.getBookFocusPage(w));
end
function performBookIndexPageHighlight(w, sPagePath)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return false;
	end

	for _,wChapter in ipairs(w.sub_index.subwindow and w.sub_index.subwindow.list.getWindows() or {}) do
		for _,wSection in ipairs(wChapter.list.getWindows()) do
			for _,wPage in ipairs(wSection.list.getWindows()) do
				local bHighlight = (sPagePath == wPage.getDatabasePath());
				wPage.setHighlight(bHighlight);
				if bHighlight then
					wSection.list.scrollToWindow(wPage, nil, true);
				end
			end
		end
	end
end

function handleBookScroll(w)
	StoryManager.refreshIndexHighlight(w);
	SoundsetManager.updateStoryContext();
end
function getBookFocusSectionAndChunk(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return "", 1;
	end

	local tPageData = StoryIndexManager.getBookPageRecord(StoryManager.getBookFocusPage(w));
	if tPageData then
		return tPageData.sSectionRecord, tPageData.nSectionChunk;
	end
	return w.content.subwindow and w.content.subwindow.getDatabasePath() or "", 1;
end
function getBookFocusPage(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return "";
	end
	if not w.content.subwindow or not w.content.subwindow.list then
		return "";
	end

	local sPagePath;
	local _, nListY = w.content.subwindow.getTabletopPosition();
	local _, nListH = w.content.subwindow.getTabletopSize();
	for _,wChild in ipairs(w.content.subwindow.list.getWindows(true)) do
		local _, nChildY = wChild.getTabletopPosition();
		if nChildY >= nListY then
			if nChildY < (nListY + (nListH / 2)) then
				sPagePath = wChild.getDatabasePath();
			end
			break;
		end
		sPagePath = wChild.getDatabasePath();
	end
	return sPagePath or "";
end
function getBookFocusPageRecord(w)
	local sPagePath = StoryManager.getBookFocusPage(w);
	if (sPagePath or "") == "" then
		return "";
	end

	local _, sRecord = DB.getValue(DB.getPath(sPagePath, "listlink"), "", "");
	return sRecord;
end

function getBookIndexLockControl(w)
	return w and w.sub_index and w.sub_index.subwindow and w.sub_index.subwindow.locked;
end
function isBookIndexLocked(w)
	local cLock = StoryManager.getBookIndexLockControl(w);
	if not cLock then
		return true;
	end
	return (cLock.getValue() == 1);
end
function setBookIndexLocked(w)
	local cLock = StoryManager.getBookIndexLockControl(w);
	if not cLock then
		return;
	end
	cLock.setValue(1);
end

function getBookIndexFilterControl(w)
	return w and w.filter;
end
function isBookIndexFiltered(w)
	return (StoryManager.getBookIndexFilter(w) ~= "");
end
function getBookIndexFilter(w)
	local cFilter = StoryManager.getBookIndexFilterControl(w);
	if not cFilter then
		return "";
	end
	return cFilter.getValue():lower();
end
function clearBookIndexFilter(w)
	local cFilter = StoryManager.getBookIndexFilterControl(w);
	if cFilter then
		cFilter.setValue("");
	end
end
function onBookIndexFilterChanged(w)
	if StoryManager.isBookIndexLocked(w) then
		StoryManager.performBookIndexDisplayUpdate(w);
	else
		StoryManager.setBookIndexLocked(w);
	end
end

function onBookIndexTogglePressed(w)
	local bManual = StoryManager.isBookWindow(w);
	if not bManual then
		return;
	end

	local bShow = (w.button_index_show.getValue() == 0);
	w.frame_index.setVisible(bShow);
	w.sub_index.setVisible(bShow);

	StoryManager.performBookIndexDisplayUpdate(w);
end
function onBookIndexChapterPressed(wChapter)
	if not wChapter then
		return;
	end
	StoryManager.onBookIndexSectionPressed(wChapter.list.getNextWindow(nil));
end
function onBookIndexSectionPressed(wSection)
	if not wSection then
		return;
	end
	StoryManager.onBookIndexPagePressed(wSection.list.getNextWindow(nil));
end
function onBookIndexPagePressed(wPage, bPopOut)
	if not wPage then
		return;
	end
	local sClass, sRecord = DB.getValue(wPage.getDatabaseNode(), "listlink", "", "");
	StoryManager.activateLink(wPage, nil, sRecord, bPopOut);
end

function onBookIndexAdd(w)
	local nodeList = w.list.getDatabaseNode();
	if not nodeList or DB.isStatic(nodeList) then
		return;
	end

	local sClass = w.getClass();
	if sClass == "story_book_index" then
		local wChapter = StoryManager.onBookIndexAddEndHelper(w.list);
		if wChapter then
			wChapter.name.setFocus();
		end
	elseif sClass == "story_book_index_chapter" then
		local wSection = StoryManager.onBookIndexAddEndHelper(w.list);
		if wSection then
			wSection.name.setFocus();
		end
	elseif sClass == "story_book_index_section" then
		local wTop = WindowManager.getTopWindow(w);
		local sCurrBookSection, nCurrBookChunk = StoryManager.getBookFocusSectionAndChunk(wTop);
		local wRecord = StoryManager.onBookIndexAddEndHelper(w.list);
		if wRecord then
			local nodePage = DB.createChild(StoryManager.DEFAULT_BOOK_CONTENT);
			wRecord.setLink("story_book_page_advanced", DB.getPath(nodePage));
			local sPageBookSection, nPageBookChunk = StoryIndexManager.getBookPageSectionAndChunk(wRecord.getDatabasePath());
			if (sCurrBookSection ~= "") and (sCurrBookSection == sPageBookSection) and (nCurrBookChunk == nPageBookChunk) then
				StoryManager.handleSectionSelect(wTop, sPageBookSection, nPageBookChunk, true);
			else
				StoryManager.onBookIndexPagePressed(wRecord);
			end
			wRecord.name.setFocus();
		end
	end
end
function onBookIndexAddEndHelper(cList)
	local nCount = #(StoryManager.updateOrderValues(cList));
	return StoryManager.onBookIndexAddHelper(cList, nCount + 1);
end
function onBookIndexAddHelper(cList, nOrder)
	local wAdd = cList.createWindow();
	StoryManager.setWindowOrderValue(wAdd, nOrder);
	return wAdd;
end

function onBookIndexDelete(w)
	local node = w.getDatabaseNode();
	if not node or DB.isStatic(node) then
		return;
	end
	if w.getClass() == "story_book_index_page" then
		local wTop = WindowManager.getTopWindow(w);
		if StoryManager.isBookWindow(wTop) then
			local _, sPath = wTop.content.getValue();
			if sPath ~= "" then
				local _, sLinkPath = w.listlink.getValue();
				if sLinkPath == sPath then
					wTop.content.setValue("", "");
				end
			end
		end
	end
	DB.deleteNode(node);
end

function onBookIndexMoveUp(w)
	local cParentList = w.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or DB.isStatic(nodeList) then
		return;
	end
	local tOrderedChildren = StoryManager.updateOrderValues(cParentList);

	local sClass = w.getClass();
	local nOrder = StoryManager.getWindowOrderValue(w);

	-- Determine move distance: 1, 5 (Shift), Top (Control)
	local nMoveStep = 1;
	if Input.isShiftPressed() then
		nMoveStep = 5;
	elseif Input.isControlPressed() then
		nMoveStep = nOrder - 1;
	end

	if sClass == "story_book_index_chapter" then
		if nOrder > 1 then
			local nNewOrder = math.max(1, nOrder - nMoveStep); -- Ensure we don't move above the first position

			-- Remove the current chapter and shift all chapters in between
			for i = nOrder - 1, nNewOrder, -1 do
				local wOther = tOrderedChildren[i];
				local nOtherOrder = StoryManager.getWindowOrderValue(wOther);
				StoryManager.setWindowOrderValue(wOther, nOtherOrder + 1);
			end
			StoryManager.setWindowOrderValue(tOrderedChildren[nOrder], nNewOrder);
			StoryManager.updateOrderValues(cParentList);
			cParentList.applySort();
		end
	elseif sClass == "story_book_index_section" then
		if nOrder > 1 then
			local nNewOrder = math.max(1, nOrder - nMoveStep); -- Ensure we don't move above the first position

			-- Remove the current subchapter and shift all subchapters in between
			for i = nOrder - 1, nNewOrder, -1 do
				local wOther = tOrderedChildren[i];
				local nOtherOrder = StoryManager.getWindowOrderValue(wOther);
				StoryManager.setWindowOrderValue(wOther, nOtherOrder + 1);
			end
			StoryManager.setWindowOrderValue(w, nNewOrder);
			StoryManager.updateOrderValues(cParentList);
			cParentList.applySort();

		elseif nOrder == 1 then
			local wChapter = w.windowlist.window;
			local cChapterParentList = wChapter.windowlist;
			local tChapterOrderedChildren = StoryManager.updateOrderValues(cChapterParentList);
			local nChapterOrder = StoryManager.getWindowOrderValue(wChapter);
			local wPrevChapter = nil;
			if nChapterOrder > 1 then
				wPrevChapter = tChapterOrderedChildren[nChapterOrder - 1];
			end
			if wPrevChapter then
				StoryManager.onBookIndexMoveHelper(w, wPrevChapter.list, false);
			end
		end
	elseif sClass == "story_book_index_page" then
		if nOrder > 1 then
			local nNewOrder = math.max(1, nOrder - nMoveStep); -- Ensure we don't move above the first position

			-- Remove the current page and shift all pages in between
			for i = nOrder - 1, nNewOrder, -1 do
				local wOther = tOrderedChildren[i];
				local nOtherOrder = StoryManager.getWindowOrderValue(wOther);
				StoryManager.setWindowOrderValue(wOther, nOtherOrder + 1);
			end
			StoryManager.setWindowOrderValue(w, nNewOrder);
			StoryManager.updateOrderValues(cParentList);
			cParentList.applySort();
			StoryManager.updateOrderValues(cParentList);

		elseif nOrder == 1 then
			local wSection = w.windowlist.window;
			local cSectionParentList = wSection.windowlist;
			local tSectionOrderedChildren = StoryManager.updateOrderValues(cSectionParentList);
			local nSectionOrder = StoryManager.getWindowOrderValue(wSection);
			local wPrevSection = nil;
			if nSectionOrder > 1 then
				wPrevSection = tSectionOrderedChildren[nSectionOrder - 1];
			elseif nSectionOrder == 1 then
				local wChapter = wSection.windowlist.window;
				local cChapterParentList = wChapter.windowlist;
				local tChapterOrderedChildren = StoryManager.updateOrderValues(cChapterParentList);
				local nChapterOrder = StoryManager.getWindowOrderValue(wChapter);
				if nChapterOrder > 1 then
					local wPrevChapter = tChapterOrderedChildren[nChapterOrder - 1];
					local tPrevChapterOrderedChildren = StoryManager.updateOrderValues(wPrevChapter.list);
					if #tPrevChapterOrderedChildren > 0 then
						wPrevSection = tPrevChapterOrderedChildren[#tPrevChapterOrderedChildren];
					else
						wPrevSection = StoryManager.onBookIndexAddHelper(wPrevChapter.list, 1);
					end
				end
			end
			if wPrevSection then
				StoryManager.onBookIndexMoveHelper(w, wPrevSection.list, false);
			end
		end
	end
end
function onBookIndexMoveDown(w)
	local cParentList = w.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or DB.isStatic(nodeList) then
		return;
	end
	local tOrderedChildren = StoryManager.updateOrderValues(cParentList);

	local sClass = w.getClass();
	local nOrder = StoryManager.getWindowOrderValue(w);

	-- Determine move distance: 1, 5 (Shift), Bottom (Control)
	local nMoveStep = 1;
	if Input.isShiftPressed() then
		nMoveStep = 5;
	elseif Input.isControlPressed() then
		nMoveStep = (#tOrderedChildren - nOrder) +1;
	end

	if sClass == "story_book_index_chapter" then
		if nOrder < #tOrderedChildren then
			-- Ensure it doesn't go beyond the last position
			local nNewOrder = math.min(#tOrderedChildren, nOrder + nMoveStep);

			-- Remove the current chapter and shift all chapters in between
			for i = nOrder + 1, nNewOrder do
				local wOther = tOrderedChildren[i];
				local nOtherOrder = StoryManager.getWindowOrderValue(wOther);
				StoryManager.setWindowOrderValue(wOther, nOtherOrder - 1);
			end
			StoryManager.setWindowOrderValue(w, nNewOrder);

			StoryManager.updateOrderValues(cParentList);
			cParentList.applySort();
			StoryManager.updateOrderValues(cParentList);
		end
	elseif sClass == "story_book_index_section" then
		if nOrder < #tOrderedChildren then
			-- Ensure it doesn't go beyond the last position
			local nNewOrder = math.min(#tOrderedChildren, nOrder + nMoveStep);

			-- Remove the current subchapter and shift all subchapters in between
			for i = nOrder + 1, nNewOrder do
				local wOther = tOrderedChildren[i];
				local nOtherOrder = StoryManager.getWindowOrderValue(wOther);
				StoryManager.setWindowOrderValue(wOther, nOtherOrder - 1);
			end
			StoryManager.setWindowOrderValue(w, nNewOrder);

			tOrderedChildren = StoryManager.updateOrderValues(cParentList);
			cParentList.applySort();

		elseif nOrder == #tOrderedChildren then
			-- Move to the top of the next chapter
			local wChapter = w.windowlist.window;
			local cChapterParentList = wChapter.windowlist;
			local tChapterOrderedChildren = StoryManager.updateOrderValues(cChapterParentList);
			local nChapterOrder = StoryManager.getWindowOrderValue(wChapter);
			local wNextChapter = nil;
			if nChapterOrder < #tChapterOrderedChildren then
				wNextChapter = tChapterOrderedChildren[nChapterOrder + 1];
			end
			if wNextChapter then
				StoryManager.onBookIndexMoveHelper(w, wNextChapter.list, true);
			end
		end
	elseif sClass == "story_book_index_page" then
		if nOrder < #tOrderedChildren then
			-- Ensure it doesn't go beyond the last position
			local nNewOrder = math.min(#tOrderedChildren, nOrder + nMoveStep);

			-- Remove teh current page and shift all pages in between
			for i = nOrder + 1, nNewOrder do
				local wOther = tOrderedChildren[i];
				local nOtherOrder = StoryManager.getWindowOrderValue(wOther);
				StoryManager.setWindowOrderValue(wOther, nOtherOrder - 1);
			end
			StoryManager.setWindowOrderValue(w, nNewOrder);

			StoryManager.updateOrderValues(cParentList);
			cParentList.applySort();

		elseif nOrder == #tOrderedChildren then
			-- Move to the bottom of the list
			local wSection = w.windowlist.window;
			local cSectionParentList = wSection.windowlist;
			local tSectionOrderedChildren = StoryManager.updateOrderValues(cSectionParentList);
			local nSectionOrder = StoryManager.getWindowOrderValue(wSection);
			local wNextSection = nil;
			if nSectionOrder < #tSectionOrderedChildren then
				wNextSection = tSectionOrderedChildren[nSectionOrder + 1];
			elseif nSectionOrder == #tSectionOrderedChildren then
				local wChapter = wSection.windowlist.window;
				local cChapterParentList = wChapter.windowlist;
				local tChapterOrderedChildren = StoryManager.updateOrderValues(cChapterParentList);
				local nChapterOrder = StoryManager.getWindowOrderValue(wChapter);
				if nChapterOrder < #tChapterOrderedChildren then
					local wNextChapter = tChapterOrderedChildren[nChapterOrder + 1];
					local tNextChapterOrderedChildren = StoryManager.updateOrderValues(wNextChapter.list);
					if #tNextChapterOrderedChildren > 0 then
						wNextSection = tNextChapterOrderedChildren[1];
					else
						wNextSection = StoryManager.onBookIndexAddHelper(wNextChapter.list, 1);
					end
				end
			end
			if wNextSection then
				StoryManager.onBookIndexMoveHelper(w, wNextSection.list, true);
			end
		end
	end
end
function onBookIndexMoveHelper(w, cList, bDown)
	local tOrderedChildren = StoryManager.updateOrderValues(cList);
	if bDown then
		for kChild,wChild in ipairs(tOrderedChildren) do
			StoryManager.setWindowOrderValue(wChild, kChild + 1);
		end
	end

	local wNew = cList.createWindow();
	local nodeOld = w.getDatabaseNode();
	DB.copyNode(nodeOld, wNew.getDatabaseNode());
	DB.deleteNode(nodeOld);

	if bDown then
		StoryManager.setWindowOrderValue(wNew, 1);
	else
		StoryManager.setWindowOrderValue(wNew, #tOrderedChildren + 1);
	end
end

function onBookIndexDrop(w, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();
		local sRecordType = RecordDataManager.getRecordTypeFromRecordPath(sRecord);
		if sRecordType == "story" then
			return StoryManager.onBookIndexStoryDrop(w, sClass, sRecord);
		end
	end
end
function onBookIndexStoryDrop(w, sClass, sRecord)
	local sIndexClass = w.getClass();
	if sIndexClass == "story_book_index_chapter" then
		local tOrderedSections = StoryManager.updateOrderValues(w.list);
		local wSection = tOrderedSections[1] or StoryManager.onBookIndexAddEndHelper(w.list);
		return StoryManager.onBookIndexStoryDrop(wSection, sClass, sRecord);

	elseif sIndexClass == "story_book_index_section" then
		local tOrderedPages = StoryManager.updateOrderValues(w.list);
		for i = 1, #tOrderedPages do
			StoryManager.setWindowOrderValue(tOrderedPages[i], i + 1);
		end
		local wPage = StoryManager.onBookIndexAddHelper(w.list, 1);
		wPage.setLink(sClass, sRecord);
		return true;

	elseif sIndexClass == "story_book_index_page" then
		local tOrderedPages = StoryManager.updateOrderValues(w.windowlist);
		local nOrder = StoryManager.getWindowOrderValue(w);
		for i = nOrder + 1, #tOrderedPages do
			StoryManager.setWindowOrderValue(tOrderedPages[i], i + 1);
		end
		local wPage = StoryManager.onBookIndexAddHelper(w.windowlist, nOrder + 1);
		wPage.setLink(sClass, sRecord);
		return true;

	elseif sIndexClass == "story_book_index" then
		local tOrderedChapters = StoryManager.updateOrderValues(w.list);
		local wChapter = tOrderedChapters[#tOrderedChapters];
		if not wChapter then
			wChapter = StoryManager.onBookIndexAddEndHelper(w.list);
		end
		local tOrderedSections = StoryManager.updateOrderValues(wChapter.list);
		local wSection = tOrderedSections[#tOrderedSections];
		if not wSection then
			wSection = StoryManager.onBookIndexAddEndHelper(wChapter.list);
		end
		local wPage = StoryManager.onBookIndexAddEndHelper(wSection.list);
		wPage.setLink(sClass, sRecord);
		return true;
	end
end

--
--	BOOK - EXPORT - KEYWORD GEN
--

local tKeywordIgnore = {
	["a"] = true,
	["about"] = true,
	["above"] = true,
	["after"] = true,
	["again"] = true,
	["against"] = true,
	["all"] = true,
	["am"] = true,
	["an"] = true,
	["and"] = true,
	["any"] = true,
	["are"] = true,
	["aren't"] = true,
	["as"] = true,
	["at"] = true,
	["be"] = true,
	["because"] = true,
	["been"] = true,
	["before"] = true,
	["being"] = true,
	["below"] = true,
	["between"] = true,
	["both"] = true,
	["but"] = true,
	["by"] = true,
	["can't"] = true,
	["cannot"] = true,
	["could"] = true,
	["couldn't"] = true,
	["did"] = true,
	["didn't"] = true,
	["do"] = true,
	["does"] = true,
	["doesn't"] = true,
	["doing"] = true,
	["don't"] = true,
	["down"] = true,
	["during"] = true,
	["each"] = true,
	["few"] = true,
	["for"] = true,
	["from"] = true,
	["further"] = true,
	["got"] = true,
	["had"] = true,
	["hadn't"] = true,
	["has"] = true,
	["hasn't"] = true,
	["have"] = true,
	["haven't"] = true,
	["having"] = true,
	["he"] = true,
	["he'd"] = true,
	["he'll"] = true,
	["he's"] = true,
	["her"] = true,
	["here"] = true,
	["here's"] = true,
	["hers"] = true,
	["herself"] = true,
	["him"] = true,
	["himself"] = true,
	["his"] = true,
	["how"] = true,
	["how's"] = true,
	["i"] = true,
	["i'd"] = true,
	["i'll"] = true,
	["i'm"] = true,
	["i've"] = true,
	["if"] = true,
	["in"] = true,
	["into"] = true,
	["is"] = true,
	["isn't"] = true,
	["it"] = true,
	["it's"] = true,
	["its"] = true,
	["itself"] = true,
	["let's"] = true,
	["like"] = true,
	["me"] = true,
	["more"] = true,
	["most"] = true,
	["mustn't"] = true,
	["my"] = true,
	["myself"] = true,
	["no"] = true,
	["nor"] = true,
	["not"] = true,
	["of"] = true,
	["off"] = true,
	["on"] = true,
	["once"] = true,
	["only"] = true,
	["or"] = true,
	["other"] = true,
	["ought"] = true,
	["our"] = true,
	["ours"] = true,
	["ourselves"] = true,
	["out"] = true,
	["over"] = true,
	["own"] = true,
	["same"] = true,
	["shan't"] = true,
	["she"] = true,
	["she'd"] = true,
	["she'll"] = true,
	["she's"] = true,
	["should"] = true,
	["shouldn't"] = true,
	["so"] = true,
	["some"] = true,
	["such"] = true,
	["than"] = true,
	["that"] = true,
	["that's"] = true,
	["the"] = true,
	["their"] = true,
	["theirs"] = true,
	["them"] = true,
	["themselves"] = true,
	["then"] = true,
	["there"] = true,
	["there's"] = true,
	["these"] = true,
	["they"] = true,
	["they'd"] = true,
	["they'll"] = true,
	["they're"] = true,
	["they've"] = true,
	["this"] = true,
	["those"] = true,
	["through"] = true,
	["to"] = true,
	["too"] = true,
	["under"] = true,
	["until"] = true,
	["up"] = true,
	["very"] = true,
	["was"] = true,
	["wasn't"] = true,
	["we"] = true,
	["we'd"] = true,
	["we'll"] = true,
	["we're"] = true,
	["we've"] = true,
	["were"] = true,
	["weren't"] = true,
	["what"] = true,
	["what's"] = true,
	["when"] = true,
	["when's"] = true,
	["where"] = true,
	["where's"] = true,
	["which"] = true,
	["while"] = true,
	["who"] = true,
	["who's"] = true,
	["whom"] = true,
	["why"] = true,
	["why'd"] = true,
	["why's"] = true,
	["with"] = true,
	["won't"] = true,
	["would"] = true,
	["wouldn't"] = true,
	["you"] = true,
	["you'd"] = true,
	["you'll"] = true,
	["you're"] = true,
	["you've"] = true,
	["your"] = true,
	["yours"] = true,
	["yourself"] = true,
	["yourselves"] = true,
}

function onBookKeywordGen()
	for _,nodeChapter in ipairs(DB.getChildList(DB.getPath(StoryManager.DEFAULT_BOOK_INDEX, StoryManager.DEFAULT_BOOK_INDEX_CHAPTER_LIST))) do
		for _,nodeSection in ipairs(DB.getChildList(nodeChapter, StoryManager.DEFAULT_BOOK_INDEX_SECTION_LIST)) do
			for _,nodePage in ipairs(DB.getChildList(nodeSection, StoryManager.DEFAULT_BOOK_INDEX_PAGE_LIST)) do
				StoryManager.onBookKeywordGenPage(nodePage);
			end
		end
	end
end
function onBookKeywordGenPage(nodePage)
	local tKeywords = {};

	StoryManager.helperGetKeywordsFromText(DB.getValue(nodePage, "name", ""), tKeywords);

	local _,sRecord = DB.getValue(nodePage, "listlink", "", "");
	local nodeRefPage = DB.findNode(sRecord);
	if nodeRefPage then
		for _,nodeBlock in ipairs(DB.getChildList(nodeRefPage, "blocks")) do
			StoryManager.helperGetKeywordsFromText(DB.getText(nodeBlock, "text", ""), tKeywords);
			StoryManager.helperGetKeywordsFromText(DB.getText(nodeBlock, "text2", ""), tKeywords);
		end
	end

	local tKeywords2 = {};
	for sWord,_ in pairs(tKeywords) do
		table.insert(tKeywords2, sWord);
	end
	DB.setValue(nodePage, "keywords", "string", table.concat(tKeywords2, " "));
end
function helperGetKeywordsFromText(sText, tKeywords)
	local tWords = StringManager.parseWords(sText);
	for _,sWord in pairs(tWords) do
		local sWordLower = sWord:lower();
		if not tKeywordIgnore[sWordLower] and not sWord:match("^%d+$") then
			tKeywords[sWordLower] = true;
		end
	end
end

--
--	STORY (ADVANCED) - UI - BLOCK EDIT/DROP
--

function onBlockAddEndHelper(cList)
	local nCount = #(StoryManager.updateOrderValues(cList));
	return StoryManager.onBookIndexAddHelper(cList, nCount + 1);
end
function onBlockAddHelper(cList, nOrder)
	local wAdd = cList.createWindow();
	StoryManager.setWindowOrderValue(wAdd, nOrder);
	return wAdd;
end

function onBlockAdd(wRecord, sBlockType)
	local nodeList = wRecord.blocks.getDatabaseNode();
	if not nodeList or DB.isStatic(nodeList) then
		return;
	end

	local wNew = StoryManager.onBlockAddEndHelper(wRecord.blocks);

	-- Setting block type should come last, since it forces block rebuild
	local nodeBlock = wNew.getDatabaseNode()
	if sBlockType == "textrimagel" then
		DB.setValue(nodeBlock, "imagelink", "windowreference", "", "");
		DB.setValue(nodeBlock, "blocktype", "string", "imageleft");
	elseif sBlockType == "textlimager" then
		DB.setValue(nodeBlock, "imagelink", "windowreference", "", "");
		DB.setValue(nodeBlock, "blocktype", "string", "imageright");
	elseif sBlockType == "image" then
		DB.setValue(nodeBlock, "imagelink", "windowreference", "", "");
		DB.setValue(nodeBlock, "blocktype", "string", "image");
	elseif sBlockType == "header" then
		DB.setValue(nodeBlock, "blocktype", "string", "header");
	elseif sBlockType == "dualtext" then
		DB.setValue(nodeBlock, "blocktype", "string", "dualtext");
	elseif sBlockType == "text" then
		DB.setValue(nodeBlock, "blocktype", "string", "singletext");
	end
	wRecord.blocks.scrollToWindow(wNew, nil, true);
end
function onBlockDelete(wBlock)
	DB.deleteNode(wBlock.getDatabaseNode());
end

function onBlockMoveUp(wBlock)
	local cParentList = wBlock.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or DB.isStatic(nodeList) then
		return;
	end
	local tOrderedChildren = StoryManager.updateOrderValues(cParentList);

	local nOrder = StoryManager.getWindowOrderValue(wBlock);

	-- If Alt key is pressed, duplicate the block and place it before the current block
	if Input.isAltPressed() then
		-- Create a duplicate block
		local newBlock = cParentList.createWindow();
		DB.copyNode(wBlock.getDatabaseNode(), newBlock.getDatabaseNode());
		StoryManager.onBlockNodeRebuild(newBlock.getDatabaseNode());

		-- Shift all blocks after the current one down by 1
		for i = #tOrderedChildren, nOrder, -1 do
			StoryManager.setWindowOrderValue(tOrderedChildren[i], i + 1);
		end

		-- Set the order for the new duplicate block
		StoryManager.setWindowOrderValue(newBlock, nOrder);

		-- Apply sorting to reflect the new order
		cParentList.applySort();
		StoryManager.updateOrderValues(cParentList);
		return; -- Exit after duplication and reordering
	end

	-- Determine the move step based on Shift or Control keys
	local nMoveStep = 1; -- Default move by 1
	if Input.isShiftPressed() then
		-- move the block up 5 spots
		nMoveStep = 5; -- Move by 5 if Shift is pressed
	elseif Input.isControlPressed() then
		-- Move the block to the top of the list
		nMoveStep = nOrder - 1; -- Move to the top if Control is pressed
	end

	-- Move the block up by the determined step
	if nOrder > 1 then
		local nNewOrder = math.max(1, nOrder - nMoveStep); -- Ensure it doesn't move above the first position

		-- Remove the current block and shift all blocks in between
		for i = nOrder, nNewOrder + 1, -1 do
			StoryManager.setWindowOrderValue(tOrderedChildren[i - 1], i);
		end

		-- Set the new order for the current block
		StoryManager.setWindowOrderValue(wBlock, nNewOrder);

		-- Apply sorting to reflect the changes
		cParentList.applySort();
	end
end

function onBlockMoveDown(wBlock)
	local cParentList = wBlock.windowlist;
	local nodeList = cParentList.getDatabaseNode();
	if not nodeList or DB.isStatic(nodeList) then
		return;
	end
	local tOrderedChildren = StoryManager.updateOrderValues(cParentList);

	local nOrder = StoryManager.getWindowOrderValue(wBlock);

	-- If Alt key is pressed, duplicate the block and place it below the current block
	if Input.isAltPressed() then

		-- Create a duplicate block
		local newBlock = cParentList.createWindow();
		DB.copyNode(wBlock.getDatabaseNode(), newBlock.getDatabaseNode());
		StoryManager.onBlockNodeRebuild(newBlock.getDatabaseNode());

		-- Shift all blocks after the current one down by 1
		for i = #tOrderedChildren, nOrder + 1, -1 do
			StoryManager.setWindowOrderValue(tOrderedChildren[i], i + 1);
		end

		-- Set the order for the new duplicate block
		StoryManager.setWindowOrderValue(newBlock, nOrder + 1);

		-- Apply sorting to reflect the new order
		cParentList.applySort();
		return; -- Exit after duplication and reordering
	end

	-- Determine the move step based on Shift or Control keys
	local nMoveStep = 1; -- Default move by 1
	if Input.isShiftPressed() then
		-- Move the block down by 5 spots
		nMoveStep = 5; -- Move by 5 if Shift is pressed
	elseif Input.isControlPressed() then
		-- move the block to the bottom of the list
		nMoveStep = #tOrderedChildren - nOrder; -- Move to the end if Control is pressed
	end

	-- Move the block down by the determined step
	if nOrder < #tOrderedChildren then
		local nNewOrder = math.min(#tOrderedChildren, nOrder + nMoveStep); -- Ensure it doesn't go beyond the last position

		-- Remove the current block and shift all blocks in between
		for i = nOrder, nNewOrder - 1 do
			StoryManager.setWindowOrderValue(tOrderedChildren[i + 1], i);
		end

		-- Set the new order for the current block
		StoryManager.setWindowOrderValue(wBlock, nNewOrder);

		-- Apply sorting to reflect the changes
		cParentList.applySort();
	end
end

function onBlockDrop(wBlock, draginfo)
	if not wBlock then
		return false;
	end

	local bReadOnly = WindowManager.getReadOnlyState(wBlock.windowlist.window.getDatabaseNode());
	if bReadOnly then
		return false;
	end

	local sDragType = draginfo.getType();
	if sDragType == "shortcut" then
		local sClass,sRecord = draginfo.getShortcutData();
		if RecordDataManager.getRecordTypeFromDisplayClass(sClass) == "image" then
			local nodeDrag = draginfo.getDatabaseNode();
			local sAsset = DB.getText(nodeDrag, "image", "");
			local sName = DB.getValue(nodeDrag, "name", "");

			StoryManager.onBlockImageDropHelper(wBlock, sAsset, sName, sClass, sRecord);
			return true;
		end
	elseif (sDragType == "image") or (sDragType == "token") then
		local sAsset = draginfo.getTokenData();
		StoryManager.onBlockImageDropHelper(wBlock, sAsset);
		return true;
	end

	return false;
end
function onBlockImageDropHelper(wBlock, sAsset, sName, sClass, sRecord)
	if sAsset == "" then
		return;
	end

	local nodeWin = wBlock.getDatabaseNode();
	DB.setValue(nodeWin, "image", "image", sAsset);
	DB.setValue(nodeWin, "caption", "string", sName or "");
	DB.setValue(nodeWin, "imagelink", "windowreference", sClass or "", sRecord or "");

	-- Remove any old scaling/size information from previous images
	DB.deleteChild(nodeWin, "scale");
	DB.deleteChild(nodeWin, "size");

	StoryManager.onBlockNodeRebuild(wBlock.getDatabaseNode());
end

function onBlockScaleUp(wBlock)
	local nScale = StoryManager.getBlockImageScale(wBlock);
	if nScale < MAX_IMAGE_SCALE then
		local nodeWin = wBlock.getDatabaseNode();
		nScale = math.min(nScale + 10, MAX_IMAGE_SCALE);
		DB.setValue(nodeWin, "scale", "number", nScale);
		DB.deleteChild(nodeWin, "size");
	end
end
function onBlockScaleDown(wBlock)
	local nScale = StoryManager.getBlockImageScale(wBlock);
	if nScale > MIN_IMAGE_SCALE then
		local nodeWin = wBlock.getDatabaseNode();
		nScale = math.max(nScale - 10, MIN_IMAGE_SCALE);
		DB.setValue(nodeWin, "scale", "number", nScale);
		DB.deleteChild(nodeWin, "size");
	end
end
function onBlockSizeClear(wBlock)
	local nodeWin = wBlock.getDatabaseNode();
	DB.deleteChild(nodeWin, "size");
end

--
--	STORY (ADVANCED) - UI - DISPLAY
--

function getBlockReadOnlyState(wBlock)
	return WindowManager.getReadOnlyState(DB.getChild(wBlock.getDatabaseNode(), "..."));
end

function onRecordNodeRebuild(nodeRecord)
	-- Check any open manuals to rebuild
	local tManualWindows = Interface.getWindows("reference_manual");
	for _,wManual in ipairs(tManualWindows) do
		local wPage = wManual.content.subwindow;
		if wPage and (wPage.getDatabaseNode() == nodeRecord) and (wPage.getClass() == "story_book_page_advanced") then
			StoryManager.onRecordRebuild(wPage.content.subwindow);
		end
	end

	-- Check open reference manual pages to rebuild
	local w = Interface.findWindow("referencemanualpage", nodeRecord);
	if w then
		StoryManager.onRecordRebuild(w.content.subwindow);
	end
end
function onRecordRebuild(wRecord)
	for _,wBlock in ipairs(wRecord.blocks.getWindows()) do
		StoryManager.onBlockRebuild(wBlock);
	end
end

function onBlockNodeRebuild(nodeBlock)
	local nodePage = DB.getChild(nodeBlock, "...");

	-- Check any open manuals to rebuild
	local tManualWindows = Interface.getWindows("reference_manual");
	for _,wManual in ipairs(tManualWindows) do
		local wPage = wManual.content.subwindow;
		if wPage and (wPage.getDatabaseNode() == nodePage) and (wPage.getClass() == "story_book_page_advanced") then
			for _,wBlock in ipairs(wPage.content.subwindow.blocks.getWindows()) do
				if wBlock.getDatabaseNode() == nodeBlock then
					StoryManager.onBlockRebuild(wBlock);
					break;
				end
			end
		end
	end

	-- Check open reference manual pages to rebuild
	local w = Interface.findWindow("referencemanualpage", nodePage);
	if w then
		for _,wBlock in ipairs(w.content.subwindow.blocks.getWindows()) do
			if wBlock.getDatabaseNode() == nodeBlock then
				StoryManager.onBlockRebuild(wBlock);
				break;
			end
		end
	end
end

-- Basic block types: dualtext, header, image, imageleft, imageright, text
-- Legacy block types: dualsidebar, picture, pictureleft, pictureright, sidebarleft, sidebarright, singletext, specialimage, specialimageleft, specialimageright
-- Deprecated block types: icon
local _tBlockTypeDualText = { "dualtext", "dualsidebar", "sidebarleft", "sidebarright", };
local _tBlockTypeImageLeft = { "imageleft", "pictureleft", "specialimageleft", };
local _tBlockTypeImageRight = { "imageright", "pictureright", "specialimageright", };
local _tBlockTypeImage = { "image", "picture", "specialimage", };
local _tBlockTypeText = { "text", "", "singletext", };
local _tBlockTypeIcon = { "icon", };

function getBlockType(nodeBlock)
	local sBlockType = DB.getValue(nodeBlock, "blocktype", "");
	if StringManager.contains(_tBlockTypeImage, sBlockType) then
		-- Legacy dual column image/text handling
		local sAlign = DB.getValue(nodeBlock, "align", "");
		local tAlign = StringManager.split(sAlign, ",");
		if #tAlign >= 2 then
			if tAlign[2] == "left" then
				return "imageleft";
			elseif tAlign[2] == "right" then
				return "imageright";
			end
		end
	end
	return sBlockType;
end
function getBlockWrapMode(wBlock)
	local nodeBlock = wBlock.getDatabaseNode();
	local sBlockType = StoryManager.getBlockType(nodeBlock);
	if StringManager.contains(_tBlockTypeDualText, sBlockType) then
		local nW = wBlock.getSize();
		return (StoryManager.MIN_PAGE_BLOCK_WIDTH >= nW);
	elseif StringManager.contains(_tBlockTypeImageLeft, sBlockType) then
		local nW = wBlock.getSize();
		local tSize = StoryManager.getBlockImageSize(wBlock, "left");
		return (((tSize.w or 0) >= nW / 2) and nW < StoryManager.MIN_PAGE_BLOCK_WIDTH);
	elseif StringManager.contains(_tBlockTypeImageRight, sBlockType) then
		local nW = wBlock.getSize();
		local tSize = StoryManager.getBlockImageSize(wBlock, "right");
		return (((tSize.w or 0) >= nW / 2) and nW < StoryManager.MIN_PAGE_BLOCK_WIDTH);
	end
	return false;
end

local bUpdating = false;
function onBlockRebuild(wBlock)
	if bUpdating then
		return
	end
	bUpdating = true;
	local nodeBlock = wBlock.getDatabaseNode();
	local sBlockType = StoryManager.getBlockType(nodeBlock);
	if StringManager.contains(_tBlockTypeDualText, sBlockType) then
		if StoryManager.getBlockWrapMode(wBlock) then
			wBlock.contents.setValue("story_block_contents_stack", nodeBlock);
		else
			wBlock.contents.setValue("story_block_contents_dual", nodeBlock);
		end
	elseif StringManager.contains(_tBlockTypeImageLeft, sBlockType) then
		if StoryManager.getBlockWrapMode(wBlock) then
			wBlock.contents.setValue("story_block_contents_stack", nodeBlock);
		else
			wBlock.contents.setValue("story_block_contents_imageleft", nodeBlock);
		end
	elseif StringManager.contains(_tBlockTypeImageRight, sBlockType) then
		if StoryManager.getBlockWrapMode(wBlock) then
			wBlock.contents.setValue("story_block_contents_stack_reverse", nodeBlock);
		else
			wBlock.contents.setValue("story_block_contents_imageright", nodeBlock);
		end
	else
		wBlock.contents.setValue("story_block_contents_center", nodeBlock);
	end
	bUpdating = false;
end
function rebuildCenterBlock(wBlock)
	local nodeBlock = wBlock.getDatabaseNode();
	local sFrame = StoryManager.getBlockFrame(wBlock, "right");
	if sFrame ~= "" and Interface.isFrame("referenceblock-" .. sFrame) then
		wBlock.block_center.setValue("story_block_contents_framed", nodeBlock);
	else
		wBlock.block_center.setValue("story_block_contents_unframed", nodeBlock);
	end
end
function rebuildDualBlock(wBlock)
	local nodeBlock = wBlock.getDatabaseNode();
	local sFrame = StoryManager.getBlockFrame(wBlock, "right");
	local sFrameLeft = StoryManager.getBlockFrame(wBlock, "left");
	local bFrame = (sFrame ~= "") and Interface.isFrame("referenceblock-" .. sFrame);
	local bFrameLeft = (sFrameLeft ~= "") and Interface.isFrame("referenceblock-" .. sFrameLeft);
	if bFrame then
		if bFrameLeft then
			wBlock.block_left.setValue("story_block_contents_framed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_framed", nodeBlock);
		else
			wBlock.block_left.setValue("story_block_contents_unframed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_framed", nodeBlock);
		end
	else
		if bFrameLeft then
			wBlock.block_left.setValue("story_block_contents_framed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_unframed", nodeBlock);
		else
			wBlock.block_left.setValue("story_block_contents_unframed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_unframed", nodeBlock);
		end
	end
end
function rebuildStackedBlock(wBlock)
	local nodeBlock = wBlock.getDatabaseNode();
	local sFrame = StoryManager.getBlockFrame(wBlock, "right");
	local sFrameLeft = StoryManager.getBlockFrame(wBlock, "left");
	local bFrame = (sFrame ~= "") and Interface.isFrame("referenceblock-" .. sFrame);
	local bFrameLeft = (sFrameLeft ~= "") and Interface.isFrame("referenceblock-" .. sFrameLeft);
	if bFrame then
		if bFrameLeft then
			wBlock.block_left.setValue("story_block_contents_framed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_framed", nodeBlock);
		else
			wBlock.block_left.setValue("story_block_contents_unframed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_framed", nodeBlock);
		end
	else
		if bFrameLeft then
			wBlock.block_left.setValue("story_block_contents_framed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_unframed", nodeBlock);
		else
			wBlock.block_left.setValue("story_block_contents_unframed", nodeBlock);
			wBlock.block_right.setValue("story_block_contents_unframed", nodeBlock);
		end
	end
end

function rebuildBlockContent(wBlock)
	local sDisplayClass = StoryManager.getBlockContentDisplayClass(wBlock);
	wBlock.block.setValue(sDisplayClass, wBlock.getDatabaseNode());

	local sFrame = StoryManager.getBlockFrame(wBlock, StoryManager.getBlockContentAlign(wBlock));
	if sFrame == "" or not Interface.isFrame("referenceblock-" .. sFrame) then
		wBlock.block.setFrame();
	else
		wBlock.block.setFrame("referenceblock-" .. sFrame, 20, 35, 20, 35);
	end
end
function getBlockContentDisplayClass(wBlock)
	local sBlockType = StoryManager.getBlockType(wBlock.getDatabaseNode());
	if StringManager.contains(_tBlockTypeDualText, sBlockType) then
		if StoryManager.getBlockContentAlign(wBlock) == "right" then
			return "story_block_text2";
		end
		return "story_block_text";
	elseif StringManager.contains(_tBlockTypeImageLeft, sBlockType) then
		if StoryManager.getBlockContentAlign(wBlock) == "left" then
			return "story_block_image";
		end
		return "story_block_text";
	elseif StringManager.contains(_tBlockTypeImageRight, sBlockType) then
		if StoryManager.getBlockContentAlign(wBlock) == "right" then
			return "story_block_image";
		end
		return "story_block_text";
	elseif StringManager.contains(_tBlockTypeImage, sBlockType) then
		return "story_block_image";
	elseif StringManager.contains(_tBlockTypeText, sBlockType) then
		return "story_block_text";
	elseif StringManager.contains(_tBlockTypeIcon, sBlockType) then
		return "story_block_icon";
	end
	local sDisplayClass = ("story_block_%s"):format(sBlockType);
	if Interface.isWindowClass(sDisplayClass) then
		return sDisplayClass;
	end
	return "story_block_text";
end
function getBlockContentAlign(wBlock)
	local sBlockAlign = wBlock.parentcontrol.getName():gsub("block_", "");
	if sBlockAlign == "left" then
		return "left";
	end
	return "right";
end
function isBlockContentImage(wBlock, sAlign)
	local sBlockType = StoryManager.getBlockType(wBlock.getDatabaseNode());
	if StringManager.contains(_tBlockTypeImage, sBlockType) then
		return true;
	end

	if StringManager.contains(_tBlockTypeImageLeft, sBlockType) then
		return (sAlign == "left");
	elseif StringManager.contains(_tBlockTypeImageRight, sBlockType) then
		return (sAlign == "right");
	end
	return false;
end
function getBlockFrame(wBlock, sAlign)
	if StoryManager.isBlockContentImage(wBlock, sAlign) then
		return "";
	end
	local sFrame;
	if sAlign == "left" then
		sFrame = DB.getValue(wBlock.getDatabaseNode(), "frameleft", "");
	else
		sFrame = DB.getValue(wBlock.getDatabaseNode(), "frame", "");
	end
	if sFrame == "noframe" then
		sFrame = "";
	end
	return sFrame;
end

function rebuildBlockContentImage(wBlock)
	local nodeBlock = wBlock.getDatabaseNode();
	local sAsset = DB.getText(nodeBlock, "image", "");
	if sAsset == "" then
		sAsset = DB.getText(nodeBlock, "picture", "");
	end
	local cImage = wBlock.image or wBlock.icon;
	local tSize;
	if sAsset == "" then
		cImage.setIcon("button_ref_block_image");
		cImage.setColor(StoryManager.getBlockButtonIconColor());
		cImage.setFrame("border");

		tSize = { w = StoryManager.MISSING_IMAGE_WIDTH, h = StoryManager.MISSING_IMAGE_WIDTH, };
	else
		cImage.setData(sAsset);
		cImage.setColor("");
		cImage.setFrame("");

		local sBlockType = StoryManager.getBlockType(nodeBlock);
		local sGraphicAlign = "";
		if StringManager.contains(_tBlockTypeImageLeft, sBlockType) then
			sGraphicAlign = "left";
		elseif StringManager.contains(_tBlockTypeImageRight, sBlockType) then
			sGraphicAlign = "right";
		end

		tSize = StoryManager.getBlockImageSize(wBlock, sGraphicAlign);
	end

	cImage.setAnchoredHeight(tSize and tSize.h or 0);

	local wFullBlockParent = wBlock.parentcontrol.window.parentcontrol.window;
	local sClass = wFullBlockParent.getClass();
	if sClass == "story_block_contents_imageleft" then
		wFullBlockParent.block_left.setAnchoredWidth((tSize and tSize.w or 0) + 20);
	elseif sClass == "story_block_contents_imageright" then
		wFullBlockParent.block_right.setAnchoredWidth((tSize and tSize.w or 0) + 20);
	end
end
function getBlockImageSize(wBlock, sAlign)
	local node = wBlock.getDatabaseNode();
	local sAsset = DB.getText(node, "image", "");
	if sAsset == "" then
		sAsset = DB.getText(node, "picture", "");
	end

	local tImageSize = {};
	tImageSize.w, tImageSize.h = Interface.getAssetSize(sAsset);

	local tLegacySize = StoryManager.getBlockImageLegacySize(wBlock);
	if tLegacySize then
		StoryManager.applyBlockGraphicSizeMaxHelper(tImageSize, tLegacySize.w, tLegacySize.h);
	end

	if (sAlign == "left") or (sAlign == "right") then
		StoryManager.applyBlockGraphicSizeMaxHelper(tImageSize, MAX_IMAGE_COL_WIDTH);
	else
		StoryManager.applyBlockGraphicSizeMaxHelper(tImageSize, MAX_IMAGE_FULL_WIDTH);
	end

	local nScale = StoryManager.getBlockImageScale(wBlock);
	if nScale ~= 100 then
		tImageSize.w = math.ceil((tImageSize.w * nScale) / 100);
		tImageSize.h = math.ceil((tImageSize.h * nScale) / 100);
	end

	if tImageSize.w == 0 then
		tImageSize.w = MISSING_IMAGE_WIDTH;
		tImageSize.h = tImageSize.w;
	end

	return tImageSize;
end
function getBlockImageScale(wBlock)
	local nScale = tonumber(DB.getValue(wBlock.getDatabaseNode(), "scale")) or StoryManager.DEFAULT_IMAGE_SCALE;
	nScale = math.min(math.max(nScale, StoryManager.MIN_IMAGE_SCALE), StoryManager.MAX_IMAGE_SCALE);
	return nScale;
end
function getBlockImageLegacySize(wBlock)
	local sLegacySize = DB.getValue(wBlock.getDatabaseNode(), "size", "");
	if sLegacySize == "" then
		return nil;
	end
	local sSizeDataW, sSizeDataH = sLegacySize:match("(%d+),(%d+)");
	if not sSizeDataW or not sSizeDataH then
		return nil;
	end
	return {
		w = tonumber(sSizeDataW) or StoryManager.MISSING_IMAGE_WIDTH,
		h = tonumber(sSizeDataH) or StoryManager.MISSING_IMAGE_WIDTH,
	};
end
function applyBlockGraphicSizeMaxHelper(tImageSize, nMaxW, nMaxH)
	if nMaxW and (tImageSize.w > nMaxW) then
		local nScale = tImageSize.w / nMaxW;
		tImageSize.w = nMaxW;
		tImageSize.h = math.ceil(tImageSize.h / nScale);
	end
	if nMaxH and (tImageSize.h > nMaxH) then
		local nScale = tImageSize.h / nMaxH;
		tImageSize.h = nMaxH;
		tImageSize.w = math.ceil(tImageSize.w / nScale);
	end
end

function rebuildBlockContentIcon(wBlock)
	local sAsset = DB.getText(wBlock.getDatabaseNode(), "icon", "");
	local tSize = StoryManager.getBlockIconSize(wBlock);
	local cIcon = wBlock.icon;
	if sAsset == "" then
		cIcon.setIcon("button_ref_block_image");
		cIcon.setColor(StoryManager.getBlockButtonIconColor());
		cIcon.setFrame("border");
	else
		cIcon.setData(sAsset);
		cIcon.setColor("");
		cIcon.setFrame("");
	end
	cIcon.setAnchoredWidth(tSize.w);
	cIcon.setAnchoredHeight(tSize.h);
end
function getBlockIconSize(wBlock)
	local tLegacySize = StoryManager.getBlockImageLegacySize(wBlock);
	if tLegacySize then
		return tLegacySize;
	end

	return {
		w = StoryManager.MISSING_IMAGE_WIDTH,
		h = StoryManager.MISSING_IMAGE_WIDTH,
	};
end

--
--	STORY (ADVANCED) - UI - IMAGE
--

function onImageDrag(wBlock, draginfo)
	if not draginfo or not wBlock or not wBlock.image then
		return;
	end

	local sClass, sRecord = DB.getValue(wBlock.getDatabaseNode(), "imagelink", "", "");
	if (sClass ~= "") and (sRecord ~= "") then
		draginfo.setType("shortcut");
		draginfo.setIcon(Interface.getLinkIcon(sClass));
		draginfo.setShortcutData(sClass, sRecord);
		draginfo.setDescription(DB.getValue(DB.findNode(sRecord), "name", ""));
		return true;
	end

	local sAsset = wBlock.image.getAsset();
	if (sAsset or "") ~= "" then
		draginfo.setType("image");
		draginfo.setTokenData(sAsset);
		return true;
	end
end
function onImagePressed(wBlock)
	if not wBlock or not wBlock.image then
		return;
	end

	local sClass, sRecord = DB.getValue(wBlock.getDatabaseNode(), "imagelink", "", "");
	if (sClass ~= "") and (sRecord ~= "") then
		Interface.openWindow(sClass, sRecord);
	else
		local sAsset = wBlock.image.getAsset();
		if (sAsset or "") ~= "" then
			local wPreview = Interface.openWindow("asset_preview", "");
			if wPreview then
				wPreview.setData(sAsset, "image");
			end
		end
	end
end

--
--	STORY (ADVANCED) - UI - COPY/PASTE
--

function registerCopyPasteToolbarButtons()
	ToolbarManager.registerButton("story_copy",
		{
			sType = "action",
			sIcon = "button_toolbar_copy",
			sTooltipRes = "record_toolbar_copy",
			fnActivate = StoryManager.onCopyButtonPressed,
			bHostOnly = true,
		});
	ToolbarManager.registerButton("story_paste",
		{
			sType = "action",
			sIcon = "button_toolbar_paste",
			sTooltipRes = "record_toolbar_paste",
			fnOnInit = StoryManager.onPasteButtonInit,
			fnActivate = StoryManager.onPasteButtonPressed,
			bHostOnly = true,
		});
end
function onCopyButtonPressed(c)
	StoryManager.performRecordCopy(c.window);
end
function onPasteButtonInit(c)
	c.onStateChanged();
end
function onPasteButtonPressed(c)
	StoryManager.performRecordPaste(c.window);
end

local _sPasteRecord = "";
function hasPasteRecord()
	return (_sPasteRecord ~= "");
end
function getPasteRecord()
	return _sPasteRecord;
end
function setPasteRecord(sRecord)
	if _sPasteRecord == sRecord then
		return;
	end
	_sPasteRecord = sRecord or "";
	StoryManager.onPasteRecordChangeEvent();
end
function onPasteRecordChangeEvent()
	local tManualWindows = Interface.getWindows("reference_manual");
	for _,w in ipairs(tManualWindows) do
		WindowManager.callInnerFunction(w, "onStoryPasteChanged");
	end

	local tStoryWindows = Interface.getWindows("referencemanualpage");
	for _,w in ipairs(tStoryWindows) do
		WindowManager.callInnerFunction(w, "onStoryPasteChanged");
	end
end

function performRecordCopy(wRecord)
	if not wRecord then
		return;
	end
	StoryManager.setPasteRecord(wRecord.getDatabasePath())
end
function performRecordPaste(wRecord)
	if not wRecord then
		return;
	end
	local sPasteRecord = StoryManager.getPasteRecord();
	if sPasteRecord == "" then
		return;
	end

	local nodeRecord = wRecord.getDatabaseNode();
	local tSrcBlockList = DB.getChildList(DB.getPath(sPasteRecord, "blocks"));
	if #tSrcBlockList > 0 then
		local nodeTargetBlocks = DB.createChild(nodeRecord, "blocks");
		if nodeTargetBlocks then
			for _,nodeSrcBlock in ipairs(tSrcBlockList) do
				DB.createChildAndCopy(nodeTargetBlocks, nodeSrcBlock);
			end
		end
	end
	StoryManager.onRecordNodeRebuild(nodeRecord);

	StoryManager.setPasteRecord("");
end

--
--	Backward compatibility
--

function initRecordLegacyText(wRecord)
	local node = wRecord.getDatabaseNode();
	local sOldText = DB.getValue(node, "text");
	if (sOldText or "") == "" then
		return;
	end

	if not wRecord.text_legacy then
		wRecord.createControl("ft_story_advanced_text_legacy", "text_legacy");
	end
end
function migrateRecordLegacyTextToBlock(wRecord)
	local node = wRecord.getDatabaseNode();
	local sOldText = DB.getValue(node, "text");
	if (sOldText or "") == "" then
		return;
	end

	local bStatic = DB.isStatic(node);
	if bStatic then
		DB.setStatic(node, false);
		DB.setStatic(wRecord.blocks.getDatabaseNode(), false);
		for _,wChild in ipairs(wRecord.blocks.getWindows()) do
			local nodeChild = wChild.getDatabaseNode();
			DB.setStatic(nodeChild, false);
		end
	end

	local tOrderedChildren = StoryManager.updateOrderValues(wRecord.blocks);
	for kChild,wChild in ipairs(tOrderedChildren) do
		StoryManager.setWindowOrderValue(wChild, kChild + 1);
	end

	local wNew = StoryManager.onBlockAddHelper(wRecord.blocks, 1);
	local nodeBlock = wNew.getDatabaseNode();
	DB.setValue(nodeBlock, "text", "formattedtext", sOldText);
	DB.deleteChild(node, "text");

	if bStatic then
		DB.setStatic(node, true);
		DB.setStatic(wRecord.blocks.getDatabaseNode(), true);
		for _,wChild in ipairs(wRecord.blocks.getWindows()) do
			local nodeChild = wChild.getDatabaseNode();
			DB.setStatic(nodeChild, true);
		end
	end

	if wRecord.text_legacy then
		wRecord.text_legacy.destroy();
	end

	-- Setting block type should come last, since it forces block rebuild
	DB.setValue(nodeBlock, "blocktype", "string", "singletext");
	StoryManager.onBlockNodeRebuild(wNew.getDatabaseNode());

	wRecord.blocks.applySort();
end
