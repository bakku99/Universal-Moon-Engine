--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--
-- Specialized Record Helper Functions
--

function showRecord(sRecordType, node)
	local sDisplayClass = RecordDataManager.getRecordTypeDisplayClass(sRecordType);
	Interface.openWindow(sDisplayClass, node);
end

function setDefaultToken(node)
	local sToken = UtilityManager.resolveDisplayToken("", DB.getValue(node, "name", ""));
	DB.setValue(node, "token", "token", sToken);
end

--
-- Support import modes
--

local _tImportModes = {};

function registerImportMode(sRecordType, sMode, sLabel, fn)
	ImportUtilityManager.unregisterImportMode(sRecordType, sMode);
	if not _tImportModes[sRecordType] then
		_tImportModes[sRecordType] = {};
	end
	table.insert(_tImportModes[sRecordType], { sMode = sMode, sLabel = sLabel, fn = fn });
end
function unregisterImportMode(sRecordType, sMode)
	if _tImportModes[sRecordType] then
		for k,v in ipairs(_tImportModes[sRecordType]) do
			if v.sMode == sMode then
				table.remove(_tImportModes[sRecordType], k);
				return;
			end
		end
	end
end
function getImportMode(sRecordType, sMode)
	if _tImportModes[sRecordType] then
		for _,v in ipairs(_tImportModes[sRecordType]) do
			if v.sMode == sMode then
				return v;
			end
		end
	end
	return nil;
end
function populateImportModes(sRecordType, cCombo)
	if cCombo then
		cCombo.clear();
		if _tImportModes[sRecordType] then
			for _,v in ipairs(_tImportModes[sRecordType]) do
				cCombo.add(v.sMode, v.sLabel);
			end
			if _tImportModes[sRecordType][1] then
				cCombo.setListValue(_tImportModes[sRecordType][1].sLabel);
			end
		end
	end
end

--
-- Specialized String Helper Functions
--

function case_insensitive_pattern(pattern)
	-- find an optional '%' (group 1) followed by any character (group 2)
	local p = pattern:gsub("(%%?)(.)",
		function(percent, letter)
			if percent ~= "" or not letter:match("%a") then
				-- if the '%' matched, or `letter` is not a letter, return "as is"
				return percent .. letter
			else
				-- else, return a case-insensitive character class of the matched letter
				return string.format("[%s%s]", letter:lower(), letter:upper())
			end
		end
	);

	return p;
end

--
-- Specialized String Cleanup Functions
--

local _sOpenBracket = "&#60;";
local _sCloseBracket = "&#62;";

-- Call this to replace problematic UTF-8 characters that had encoding issues.
-- these are replaced with simple ASCII characters
function cleanUpText(s)
	if (s or "") == "" then
		return "";
	end

	local sResult = ImportUtilityManager.internalCleanUpCharacters(s);
	sResult = ImportUtilityManager.internalCleanUpCombineParagraphs(sResult);
	sResult = ImportUtilityManager.internalCleanUpHTML(sResult);
	sResult = ImportUtilityManager.internalCleanUpPar5EMarkup(sResult);
	return sResult;
end

-- Resolve and replace problematic escape characters
function internalCleanUpCharacters(s)
	-- replace non-breaking space with simple space ( )
	s = s:gsub("&#160;", " ");
	-- remove soft hyphen
	s = s:gsub("&#173;", "");

	-- &#10; line feed - replace with carriage-return instead
	s = s:gsub("&#10;", "&#13;");
	-- &#10; line feed (already escaped) - replace with carriage-return instead
	s = s:gsub("&#38;#10;", "&#13;");

	return s;
end

function internalCleanUpCombineParagraphs(s)
	-- Combine paragraphs whenever a new line starts with a lower case letter.
	return s:gsub("</p><p>(%l)", " %1");
end

function internalCleanUpHTML(s)
	s = ImportUtilityManager.unescapeHTML(s);

	-- first remove any attributes of p tags
	s = s:gsub("<p(.-)>","<p>");

	-- Remove empty paragraph tags
	s = s:gsub("<p%s?/>", "");

	-- handle replacement of literal html tags that we support
	-- handle already escaped italics <i> tags
	s = ImportUtilityManager.replaceHTMLTag(s, "strong", "<b>", "</b>", false);

	-- treat <h1> and <h2> tags as a header tag <h>
	--s = replaceHTMLTag(s, "h1", "<h>", "</h>", true);
	s = s:gsub("<h1>", "<h>");
	s = s:gsub("</h1>", "</h>");
	s = s:gsub("<h2>", "<h>");
	s = s:gsub("</h2>", "</h>");
	s = s:gsub("<h3>", "<p><b>");
	s = s:gsub("</h3>", "</b></p>");
	s = s:gsub("<h4>", "<p><b>");
	s = s:gsub("</h4>", "</b></p>");
	s = s:gsub("<h5>", "<p><b>");
	s = s:gsub("</h5>", "</b></p>");

	-- recognize table tags
	s = ImportUtilityManager.cleanTableHTML(s);

	-- recognize lists
	s = ImportUtilityManager.replaceHTMLTag(s, "ul", "<list>", "</list>",true);
	s = ImportUtilityManager.replaceHTMLTag(s, "ol", "<list>", "</list>",true);
	s = ImportUtilityManager.replaceHTMLTag(s, "li", "<li>", "</li>",true);

	-- Strip hyperlinks
	s = ImportUtilityManager.replaceHTMLTag(s, "a", "", "", false);

	s = ImportUtilityManager.removePTagsFromSpecificElements(s);

	return s;
end

function cleanTableHTML(s)
	-- Remove any paragraph tags from inside of tables
	s = s:gsub("<table>(.-)</table>", function(tableContent)
		local prevTableContent;
		repeat
			prevTableContent = tableContent
			tableContent = tableContent:gsub("<p>", "");
			tableContent = tableContent:gsub("</p>", "");
		until tableContent == prevTableContent
		return "<table>" .. tableContent .. "</table>"
	end)

	-- Remove thead and tbody elements
	s = s:gsub("%s*<thead>%s*","");
	s = s:gsub("%s*</thead>%s*","");
	s = s:gsub("%s*<tbody>%s*","");
	s = s:gsub("%s*</tbody>%s*","");

	return s
end

-- Helper function to remove <p> tags from specific parent elements
function removePTagsFromSpecificElements(html)
	-- first remove any attributes of p tags
	html = html:gsub("<p(.-)>","<p>");

	local previous_html

	-- Remove <p> tags wrapping allowed elements
	-- Matches the opening <p> and the surrounding allowed elements
	html = html:gsub("<p>%s*(<p>)","%1");
	html = html:gsub("</p>%s*(</p>)","%1");
	html = html:gsub("<p>%s*(<table>)","%1");
	html = html:gsub("<p>%s*(<h>)","%1");
	html = html:gsub("(</h>)</p>","%1");
	html = html:gsub("<p>%s*(<h1>)","%1");
	html = html:gsub("<p>%s*(<h2>)","%1");
	html = html:gsub("<p>%s*(<h3>)","%1");
	html = html:gsub("<p>%s*(<ol>)","%1");
	html = html:gsub("<p>%s*(<ul>)","%1");
	html = html:gsub("(<ol>)%s*</p>","%1");
	html = html:gsub("(<ul>)%s*</p>","%1");
	html = html:gsub("<p>%s*(<li>)","%1");
	html = html:gsub("<p>%s*(<list>)","%1");

	-- Also handle closing tags (for example, </tr> </p> becomes </tr>)
	html = html:gsub("(</table>)%s*</p>", "%1")
	html = html:gsub("(</h>)%s*</p>", "%1")
	html = html:gsub("(</h1>)%s*</p>", "%1")
	html = html:gsub("(</h2>)%s*</p>", "%1")
	html = html:gsub("(</h3>)%s*</p>", "%1")
	html = html:gsub("(</ol>)%s*</p>", "%1")
	html = html:gsub("(</ul>)%s*</p>", "%1")
	html = html:gsub("<p>%s*(</ol>)", "%1")
	html = html:gsub("<p>%s*(</ul>)", "%1")
	html = html:gsub("(</li>)%s*</p>", "%1")
	html = html:gsub("(</list>)%s*</p>", "%1")

	-- remove paragraph tags from inside of bold tags
	html = html:gsub("<b>(.-)</b>", function(BContent)
		local prevBContent;
		repeat
			prevBContent = BContent
			BContent = BContent:gsub("<p>", "");
			BContent = BContent:gsub("</p>", "");
		until BContent == prevBContent;
		return "<b>" .. BContent .. "</b>";
	end)

	-- Clean up any duplicated p tags from copying and pasting in raw HTML to FG
	repeat
		previous_html = html;
		html = html:gsub("<p><p>","<p>");
		html = html:gsub("</p></p>","</p>");
	until html == previous_html;

	-- one last call to remove extra paragraph tags
	html = html:gsub("<p>%s*(<h>)","%1");
	html = html:gsub("(</h>)</p>","%1");
	-- remove any open p tag at the end of the document
	html = html:gsub("<p>$","");

	-- Return cleaned-up HTML
	return html;
end

function internalCleanUpPar5EMarkup(s)
	s = ImportUtilityManager.convertPAR5ETables(s);
	s = ImportUtilityManager.convertPAR5ELists(s);
	s = ImportUtilityManager.convertPAR5EParagraphs(s);
	s = ImportUtilityManager.convertPAR5EHeaders(s);
	s = ImportUtilityManager.convertPAR5EParagraphLeadins(s);
	return s;
end

-- LUA does not support optional groups, so we have to look for every permutation of a preceding <p> tag,
-- a trailing </p> tag, the absence of those, or the combination of both.
-- Use a %1 within the Open Replacement to indicate where the optional tag parameters should be placed.
function replaceHTMLTag(s, inTag, inOpenReplacement, inCloseReplacement, bStripParagraph)
	local sResult = s;
	local sTag = ImportUtilityManager.case_insensitive_pattern(inTag:lower());

	-- Start with the most combinations of extraneous tags and replace each permutation of surrounding <p> tags
	if bStripParagraph then
		-- Replace opening tag with optional attributes (captured with (.-))
		local sPattern = "<p.-%s*>%s*" .. _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket .. "%s*</p>";
		sResult = sResult:gsub(sPattern, inOpenReplacement);
		-- Look for version not wrapped in paragraph tags, but also capturing optional attributes
		sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, inOpenReplacement);

		-- Replace closing tag
		sPattern = "<p>%s*" .. _sOpenBracket .. "/" .. sTag .. _sCloseBracket .. "%s*</p>";
		sResult = sResult:gsub(sPattern, inCloseReplacement);
		sPattern = _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, inCloseReplacement);

	else
		-- Replace opening tag with optional attributes
		local sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, inOpenReplacement);

		-- Replace closing tag
		sPattern = _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, inCloseReplacement);
	end

	return sResult;
end

function unescapeHTML(s)
	s = s:gsub("&#60;", "<")
	s = s:gsub("&#62;", ">")
	return s
end

-- Works the same way as replaceHTMLTag, except the open and close brackets are not escaped into XML
function replaceFGTag(s, inTag, inOpenReplacement, inCloseReplacement, bStripParagraph)
	local sResult = s;
	local sTag = ImportUtilityManager.case_insensitive_pattern(inTag:lower());
	local sCleanOpenReplacement = inOpenReplacement:gsub("[%][1]", "");

	-- Start with the most combinations of extraneous tags and replace each permutation of surrounding <p> tags
	if bStripParagraph then
		-- first replace the opening tag
		local sPattern = "<p>%s*<" .. sTag .. ">%s*</p>";
		sResult = sResult:gsub(sPattern, sCleanOpenReplacement);
		-- look for version not wrapped in paragraph tags
		sPattern = "<" .. sTag .. ">";
		sResult = sResult:gsub(sPattern, sCleanOpenReplacement);

		-- second pass: replace opening tags that include optional parameters
		sPattern = "<p>%s*<" .. sTag .. "(.-)>%s*</p>";
		sResult = sResult:gsub(sPattern, inOpenReplacement);
		-- look for version not wrapped in paragraph tags
		sPattern = "<" .. sTag .. "(.-)>";
		sResult = sResult:gsub(sPattern, inOpenReplacement);

		-- next replace the closing tag
		sPattern = "<p>%s*</" .. sTag .. ">%s*</p>";
		sResult = sResult:gsub(sPattern, inCloseReplacement);
		sPattern = "</"  .. sTag .. ">";
		sResult = sResult:gsub(sPattern, inCloseReplacement);

	-- Just do a simple case-insensitive replacement
	else
		-- first replace the opening tag
		local sPattern = "<" .. sTag .. "(.-)>";
		sResult = sResult:gsub(sPattern, inOpenReplacement);

		-- next replace the closing tag
		sPattern = "</" .. sTag .. ">";
		sResult = sResult:gsub(sPattern, inCloseReplacement);
	end

	return sResult;
end

-- This function removes everything between the open and close of the specified tag
-- LUA does not support optional groups, so we have to look for every permutation of a preceding <p> tag,
-- a trailing </p> tag, the absence of those, or the combination of both.
function stripHTMLTag(s, inTag, _, _, bStripParagraph)
	local sResult = s;
	local sTag = ImportUtilityManager.case_insensitive_pattern(inTag:lower());

	-- Start with the most combinations of extraneous tags and replace each permutation of surrounding <p> tags
	if bStripParagraph then
		-- remove anything within and including teh opening and closing tags
		local sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket .. "(.-)" .. _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		-- replace the entire contents with a simple search and replace string so we can look for surrounding
		-- paragraphs more easily after the middle content has been replaced
		sResult = sResult:gsub(sPattern, "XREMOVEX");

		-- now you can safely remove all instances where the paragraphs tags are next to these replaced values
		sPattern = "<p>XREMOVEX</p>";
		sResult = sResult:gsub(sPattern, "");
		sPattern = "<p>XREMOVEX";
		sResult = sResult:gsub(sPattern, "");
		sPattern = "XREMOVEX</p>";
		sResult = sResult:gsub(sPattern, "");
		sPattern = "XREMOVEX";
		sResult = sResult:gsub(sPattern, "");

	-- Just do a simple case-insensitive replacement
	else
		local sPattern = _sOpenBracket .. sTag .. "(.-)" .. _sCloseBracket .. "(.-)" .. _sOpenBracket .. "/" .. sTag .. _sCloseBracket;
		sResult = sResult:gsub(sPattern, "");
	end

	return sResult;
end

-- Calls the convertPAR5ETable function until there are no more tables found
function convertPAR5ETables(s)
	local sResult = s;
	local sLastSource = "-";

	-- keep looping as long as there are changes
	while sResult ~= sLastSource do
		sLastSource = sResult;
		sResult = ImportUtilityManager.convertPAR5ETable(sResult);
	end

	return sResult;
end

-- This translates PAR5E style tables into formatted text tables
-- Example:
-- #ts;
-- #th;Size;Space;Examples;
-- #tr;Tiny;2½ by 2½ ft.;Imp, sprite
-- #tr;Small;5 by 5 ft.;Giant rat, goblin
-- #tr;Medium;5 by 5 ft.;Orc, werewolf
-- #tr;Large;10 by 10 ft.;Hippogriff, ogre
-- #tr;Huge;15 by 15 ft.;Fire giant, treant
-- #tr;Gargantuan;20 by 20 ft. or larger;Kraken, purple worm
-- #te;
function convertPAR5ETable(s)
	-- patterns to use for searching
	local ts = "<p>#ts;</p>";
	local te = "<p>#te;</p>";

	-- look for the start and the immediate end of the table tags and grab the middle
	local iTableStart, iTableEnd = s:find(ts .. ".-" .. te, 1);
	if not iTableEnd then
		return s;
	end

	-- save the part before the table
	local tResult = {};
	table.insert(tResult, s:sub(1, iTableStart - 1));

	-- parse out the table
	table.insert(tResult, "<table>");

	local inTable = s:sub(iTableStart,iTableEnd);
	local sRowPattern = "<p>#t[hr];.-</p>";
	local iRowStart, iRowEnd = inTable:find(sRowPattern);
	while iRowEnd do
		local rowType = inTable:sub(iRowStart + 4, iRowStart + 5) or "";
		local sRow = inTable:sub(iRowStart + 7, iRowEnd - 4) or "";

		table.insert(tResult, "<tr>");

		local tSegments = StringManager.splitByPattern(sRow, ";", true);
		for _,cellValue in ipairs(tSegments) do
			-- Handle optional colspan values. These are prefixes
			-- Example: 2:Double cell;4:Quadruple cell;Single cell
			local colSpan;
			local iColSpanStart, iColSpanEnd = cellValue:find(":");
			if iColSpanEnd then
				colSpan = cellValue:sub(1, iColSpanStart - 1);
				cellValue = cellValue:sub(iColSpanStart + 1);
			else
				colSpan = "1";
			end

			if rowType == "th" then
			   cellValue = string.format("<b>%s</b>", cellValue);
			end

			if colSpan == "1" then
				table.insert(tResult, string.format("<td>%s</td>", cellValue));
			else
				table.insert(tResult, string.format("<td colspan='%s'>%s</td>", colSpan, cellValue));
			end
		end

		table.insert(tResult, "</tr>");

		iRowStart, iRowEnd = inTable:find(sRowPattern, iRowStart + 1);
	end

	table.insert(tResult, "</table>");

	-- save the remainder of the description after the table
	table.insert(tResult, s:sub(iTableEnd+1));

	return table.concat(tResult);
end

-- calls the convertPAR5EList function until there are no more lists
-- found to parse.
function convertPAR5ELists(s)
	local sResult = s;
	local sLastSource = "-";

	-- keep looping as long as there are changes
	while sResult ~= sLastSource do
		sLastSource = sResult;
		sResult = ImportUtilityManager.convertPAR5EList(sResult);
	end

	return sResult;
end

-- This translates PAR5E style lists into formatted text lists
-- Example:
--#ls;
--#li;An orange
--#li;An apple
--#li;A banana
--#le;
function convertPAR5EList(s)
	-- patterns to use for searching
	local ls = "<p>#ls;</p>";
	local le = "<p>#le;</p>";

	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iListStart, iListEnd = s:find(ls .. ".-" .. le, 1);
	if not iListEnd then
		return s;
	end

	-- save the part before the list
	local tResult = {};
	table.insert(tResult, s:sub(1, iListStart - 1));

	-- parse out the list
	table.insert(tResult, "<list>");

	local inList = s:sub(iListStart, iListEnd);
	local sListItemPattern = "<p>#li;.-</p>";
	local iListItemStart, iListItemEnd = inList:find(sListItemPattern);
	while iListItemEnd do
		local sListItem = inList:sub(iListItemStart + 7,iListItemEnd - 4);
		table.insert(tResult, string.format("<li>%s</li>", sListItem));

		iListItemStart, iListItemEnd = inList:find(sListItemPattern, iListItemStart + 1);
	end

	table.insert(tResult, "</list>");

	-- save the remainder of the description after the list
	table.insert(tResult, s:sub(iListEnd + 1));

	return table.concat(tResult);
end

-- This translates PAR5E style lead-ins for paragraphs
-- Examples:
--#bs;Apples: A healthy snack choice
--#bs;Apples. Still a healthy choice
--#is;Oranges. They can use period or colon to separate
--#bis;Mango: They are so special that they get bold and italic treatment.
function convertPAR5EParagraphLeadins(s)
	-- patterns to use for searching. 0 or more b or i characters, followed by an s
	-- within opening and closing paragraph <p> tags.
	local sPattern = "<p>#b?i?s;.-</p>";

	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iParagraphStart, iParagraphEnd = s:find(sPattern);
	if not iParagraphEnd then
		return s;
	end

	-- parse out the middle of the paragraph
	local tResult = {};
	local iLastParagraphEnd = 0;
	while iParagraphEnd do
		-- save the part before the list
		if (iParagraphStart - 1) > (iLastParagraphEnd + 1) then
			table.insert(tResult, s:sub(iLastParagraphEnd + 1, iParagraphStart - 1));
		end

		-- grab everything after the opening <p> tag and up to the closing </p> tag
		local inParagraph = s:sub(iParagraphStart + 3, iParagraphEnd - 4);

		-- split off the PAR5E tag
		local iSemicolonLocation = inParagraph:find(";");
		local iLeadinBreakLocation = inParagraph:find("[.:-]", iSemicolonLocation + 1);
		local paragraphType = inParagraph:sub(1, iSemicolonLocation);

		-- grab the leadin phrase, including the semicolon/period/dash.
		local sLeadin = inParagraph:sub(iSemicolonLocation + 1, iLeadinBreakLocation);
		local sParagraphEnd = inParagraph:sub(iLeadinBreakLocation + 1);

		local sLeadinBeginTag = "";
		local sLeadinEndTag = "";
		if paragraphType:match("b", 1) then
			sLeadinBeginTag = "<b>";
			sLeadinEndTag = "</b>";
		end
		if paragraphType:match("i", 1) then
			sLeadinBeginTag = sLeadinBeginTag .. "<i>";
			sLeadinEndTag = "</i>" .. sLeadinEndTag;
		end

		sLeadin = sLeadinBeginTag .. sLeadin .. sLeadinEndTag;
		table.insert(tResult, string.format("<p>%s%s</p>", sLeadin, sParagraphEnd));

		iLastParagraphEnd = iParagraphEnd;
		iParagraphStart, iParagraphEnd = s:find(sPattern, iParagraphEnd + 1);
	end

	-- save the final part of the formatted text, after all paragraph tags have been
	-- processed. First, compare the last postion of a paragraph with the length of the
	-- source string.
	if #s > iLastParagraphEnd then
		table.insert(tResult, s:sub(iLastParagraphEnd + 1));
	end

	return table.concat(tResult);
end

-- This translates PAR5E style lists into formatted text lists
-- Examples:
--#bp;Bold this entire paragraph
--#ip;Italicize this entire paragraph
function convertPAR5EParagraphs(s)
	-- patterns to use for searching
	local sPattern = "<p>#[bi]p;.-</p>";

	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iParagraphStart, iParagraphEnd = s:find(sPattern);
	if not iParagraphEnd then
		return s;
	end

	-- parse out the middle of the paragraph
	local tResult = {};
	local iLastParagraphEnd = 0;
	while iParagraphEnd do
		-- save the part before the list
		if (iParagraphStart - 1) > (iLastParagraphEnd + 1) then
			table.insert(tResult, s:sub(iLastParagraphEnd + 1, iParagraphStart - 1));
		end

		local inParagraph = s:sub(iParagraphStart + 7, iParagraphEnd - 4);
		local paragraphType = s:sub(iParagraphStart + 4, iParagraphStart + 4);
		table.insert(tResult, string.format("<p><%s>%s</%s></p>", paragraphType, inParagraph, paragraphType));

		iLastParagraphEnd = iParagraphEnd;
		iParagraphStart, iParagraphEnd = s:find(sPattern, iParagraphEnd + 1);
	end

	-- save the final part of the formatted text, after all paragraph tags have been
	-- processed. First, compare the last postion of a paragraph with the length of the
	-- source string.
	if #s > iLastParagraphEnd then
		table.insert(tResult, s:sub(iLastParagraphEnd + 1));
	end

	return table.concat(tResult);
end

-- This translates PAR5E style lists into formatted text lists
-- Examples:
--#h;Chapter 1: Building a Character
function convertPAR5EHeaders(s)
	-- patterns to use for searching
	local sPattern = "<p>#h;.-</p>";

	-- look for the start and immediate end of a list tags. Grab everything in the middle
	local iParagraphStart, iParagraphEnd = s:find(sPattern);
	if not iParagraphEnd then
		return s;
	end

	-- parse out the middle of the paragraph
	local tResult = {};
	local iLastParagraphEnd = 0;
	while iParagraphEnd do
		-- save the part before the list
		if (iParagraphStart - 1) > (iLastParagraphEnd + 1) then
			table.insert(tResult, s:sub(iLastParagraphEnd + 1, iParagraphStart - 1));
		end

		table.insert(tResult, string.format("<h>%s</h>", s:sub(iParagraphStart + 6, iParagraphEnd - 4)));

		iLastParagraphEnd = iParagraphEnd;
		iParagraphStart, iParagraphEnd = s:find(sPattern, iParagraphEnd + 1);
	end

	-- save the final part of the formatted text, after all paragraph tags have been
	-- processed. First, compare the last postion of a paragraph with the length of the
	-- source string.
	if #s > iLastParagraphEnd then
		table.insert(tResult, s:sub(iLastParagraphEnd + 1));
	end

	return table.concat(tResult);
end

--
-- Specialized String Parsing/Tokenizing Functions
--

-- read in the source and write out a single line to each row of a table. Look for
-- all end tags. If you find an end tag that represents the end of a section, save this as
-- a row in the table that you return. Examples of end tags we want to capture as a "line"
-- are headers <h> tags, paragraph <p> tags, list tags <list>, <frame> tags, or <table> tags
function parseFormattedTextToLines(s)
	-- Split into lines, based on ending tags for formatted text in FG
	local sSplitPattern = "</.->";
	local tEndTags = {"h", "p", "list", "linklist", "frame", "table"};

	local tResults = {};
	local sRow;
	local sLastRow = "";
	local iStart = 1;
	local iSplitStart, iSplitEnd = s:find(sSplitPattern);
	while iSplitStart do
		local sTag = s:sub(iSplitStart + 2, iSplitEnd - 1);

		-- see if this is a tag that we will ignore
		if not StringManager.contains(tEndTags, sTag) then
			-- this tag is not an end tag. Save the results and keep parsing
			sRow = sLastRow .. s:sub(iStart, iSplitEnd);
			sLastRow = sRow;
		else
			-- this is an end tag. Strip the tag and save the processed text as a new "line"
			sRow = s:sub(iStart, iSplitStart - 1);
			sRow = sLastRow .. sRow;

			-- remove the leading tag
			sRow = sRow:gsub("^<" .. sTag .. ">", "");
			sLastRow = "";

			for _,v in ipairs(StringManager.splitByPattern(sRow, "\r", true)) do
				table.insert(tResults, v);
			end
		end

		iStart = iSplitEnd + 1;
		iSplitStart, iSplitEnd = s:find(sSplitPattern, iStart);
	end

	-- After processing, save whatever is left in the string to the final row.
	sRow = sLastRow .. s:sub(iStart);
	for _,v in ipairs(StringManager.splitByPattern(sRow, "\r", true)) do
		table.insert(tResults, v);
	end

	return tResults;
end

function parseFormattedTextToLinesWithTags(s)
	-- Split into lines based on line-breaking tags only
	local sSplitPattern = "</.->"
	local tEndTags = {"h", "p", "list", "linklist", "frame", "table", "tr", "td", "th"}
	local tInlineTags = {"b", "i"}

	local tResults = {}
	local sRow = ""
	local iStart = 1
	local iSplitStart, iSplitEnd = s:find(sSplitPattern, iStart)

	while iSplitStart do
		local sTag = s:sub(iSplitStart + 2, iSplitEnd - 1)

		-- Extract the content between the previous tag and the current tag
		local content = s:sub(iStart, iSplitStart - 1)

		-- If this is an inline tag, append it to the current line without finalizing
		if StringManager.contains(tInlineTags, sTag) then
			sRow = sRow .. content .. s:sub(iSplitStart, iSplitEnd)

		-- If this is an end tag, finalize the current line
		elseif StringManager.contains(tEndTags, sTag) then
			sRow = sRow .. content .. s:sub(iSplitStart, iSplitEnd)
			table.insert(tResults, sRow)
			sRow = "" -- Reset the row for the next line

		-- Otherwise, continue accumulating content
		else
			sRow = sRow .. content .. s:sub(iSplitStart, iSplitEnd)
		end

		-- Advance start position and repeat
		iStart = iSplitEnd + 1
		iSplitStart, iSplitEnd = s:find(sSplitPattern, iStart)
	end

	-- Append any remaining content as a final line
	if iStart <= #s then
		sRow = sRow .. s:sub(iStart)
	end
	if sRow ~= "" then
		table.insert(tResults, sRow)
	end

	return tResults
end
