--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals aRecords aListViews getCharListLink getStoryDisplayClass getSoundsetType

-- RECORD TYPE FORMAT
-- 		["recordtype"] = {
-- 			aDataMap = <table of strings>, (required)
--
--			bExport = <bool>, (optional)
--			nExport = <number>, (optional; overriden by bExport)
--			bExportNoReadOnly = <bool>, (optional; overrides bExport)
--			sExportPath = <string>, (optional)
--			bExportListSkip = <bool>, (optional)
--			sExportListDisplayClass = <string>, (optional)
--			sExportTag = <string>, (optional)
--			sGMExportTag = <string>, (optional)
--
-- 			sListDisplayClass = <string>, (optional)
-- 			sRecordDisplayClass = <string>, (optional)
--			aRecordDisplayCLasses = <table of strings>, (optional; overrides sRecordDisplayClass)
--			fRecordDisplayClass = <function>, (optional; overrides sRecordDisplayClass)
--			fGetLink = <function>, (optional)
--
--			aGMListButtons = <table of template names>, (optional)
--			aPlayerListButtons = <table of template names>, (optional)
--
--			aCustomFilters = <table of custom filter table records>, (optional)
--
--			tOptions = <table of string->boolean key-values>
-- 		},
--
-- RECORD TYPE LEGEND
--		aDataMap = Required. Table of strings. defining the valid data paths for records of this type
--			NOTE: For bExport/nExport, that number of data paths from the beginning of the data map list will be used as the source for exporting
--				and the target data paths will be the same in the module. (i.e. default campaign data paths, editable).
--				The next nExport data paths in the data map list will be used as the export target data paths for read-only data paths for the
--				matching source data path.
--			EX: { "item", "armor", "weapon", "reference.items", "reference.armors", "reference.weapons" } with a nExport of 3 would mean that
--				the "item", "armor" and "weapon" data paths would be exported to the matching "item", "armor" and "weapon" data paths in the module by default.
--				If the reference data path option is selected, then "item", "armor" and "weapon" data paths would be exported to
--				"reference.items", "reference.armors", and "reference.weapons", respectively.
--
--		sListDisplayClass = Optional. String.
--			Class to use when displaying this record in a list. If not defined, a default class will be used.
--		sRecordDisplayClass = Optional. String.
--			Class to use when displaying this record in detail. (Defaults to record type key string)
--		aRecordDisplayClasses = Optional. Table of strings.
--			List of valid display classes for records of this type. Use fRecordDisplayClass to specify which one to use for a given path.
--		fRecordDisplayClass = Optional. Function.
--			Function called when requesting to display this record in detail.
--		fGetLink = Optional. Function.
--			Function called to determine window class and data path to use when pressing or dragging sidebar button.
--
--		aGMListButtons = Optional. Table of template names.
--			A list of control templates created and added to the master list window for this record type in GM mode.
--		aPlayerListButtons = Optional. Table of template names.
--			A list of control templates created and added to the master list window for this record type in Player mode.
--
--		nExport = Optional. Overriden by bExport.
--			Number indicating number of data paths which are exportable in the library export window for the record type.
--			NOTE: See aDataMap for bExport/nExport are handled for target campaign data paths vs. reference data paths (editable vs. read-only)
--		sExportPath = Optional.
--			When exporting records to a module, use this alternate data path when storing into a module, instead of the base data path for this record.
--		sExportListDisplayClass = Optional. (Default = reference_list)
--			When exporting records, the list link created for records to be accessed from the library will use this display class.
--
--		sEditMode = Optional. Valid values are "play" or "none".
--			If "play" specified, then both players and GMs can add/remove records of this record type.
--				Note, players can only remove records they have created.
--			If "none" specified, then neither player nor GM can add/remove records.
--			If not specified, then only GM can add/remove records.
--			NOTE: The character selection dialog handles this in the custom character selection window class historically, so does not use this option.
--
--		tOptions = Optional. Table of boolean options. (Tables will be merged with existing table on overrideRecordType(s) calls)
--			bExport = Same as nExport = 1.
--				Indicates whether record should be exportable in the library export window for the record type.
--			bExportNoReadOnly = Similar to bExport.
--				Indicates whether record should be exportable in the library export window for the record type, but read only option in export is ignored.
--			bExportListSkip = When exporting records, a list link is normally created for the records to be accessed from the library.
--				This option skips creation of the list and link.
--			bHidden = Indicates whether record should be displayed in library, and sidebar options.
-- 			bID = Indicates whether record is identifiable or not (currently only items and images)
--			bNoCategories = Disables display and usage of category information in campaign lists.
--			bNoLock = Disables lock in standard window record menu. Lock button shown by default.
--			bNoShare = Disables share in standard window record menu. Share button shown by default.
--			bPicture = Enables picture field in record header (can define pictures tab for editing; or will pop-up fallback window)
--			bToken = Enables token field in record header (can define pictures tab for editing; or will pop-up fallback window)
--			bCurrency = Enables currency can be transferred to this record type.
--				(See ItemManager for default currency paths; or use custom data registration to set different one.)
--			bInventory = Enables items can be transferred to this record type.
--				(See ItemManager for default inventory paths; or use custom data registration to set different one.)
--
--		aCustom = Table of custom data registered. (Tables will be merged with existing table on overrideRecordType(s) calls)
--			Examples Used:
--				tWindowMenu = Use left and right sub-keys to add button templates to top-level window menu
--				tInventoryPaths = Optional. Specify alternate inventory paths from ItemManager default.
--				tEncumbranceFields = Optional. Specify alternate item encumbrance fields from ItemManager default.
--				tCurrencyPaths = Optional. Specify alternate currency paths from ItemManager default.
--				tCurrencyEncumbranceFields = Optional. Specify alternate currency encumbrance fields from ItemManager default.
--
--		aCustomFilters = Optional. Table of custom filter table records.
--			Key = Label string to display for filter;
--			Filter table record format is:
--				sField = Required. String. Child data node that contains data to use to build filter value list; and to apply filter to.
--				fGetValue = Optional. Function.
--					Returns string or table of strings containing filter value(s) for the record passed as parameter to the function.
--				sType = Optional. String. Valid values are: "boolean", "number".
--					NOTE: If no type specified, string is assumed.
--						If empty string value returned, then the string resource (library_recordtype_filter_empty) will be used for display if available.
--					NOTE 2: For boolean type, these string resources will be used for labels (library_recordtype_filter_yes, library_recordtype_filter_no).
--
-- FIELDS ADDED FROM STRING DATA
-- 		tDisplayText.sDisplayText = Interface.getString(library_recordtype_label_ .. sRecordType)
--		tDisplayText.sSingleDisplayText = Interface.getString(library_recordtype_single_ .. sRecordType)
-- 		tDisplayText.sEmptyNameText = Interface.getString(library_recordtype_empty_ .. sRecordType)
--		tDisplayText.sExportDisplayText = Interface.getString(library_recordtype_export_ .. sRecordType)
-- 		tDisplayText.sEmptyUnidentifiedNameText = Interface.getString(library_recordtype_empty_nonid_ .. sRecordType) (only when bID set)
--

function getCharListLink()
	if Session.IsHost then
		return "charselect_host", "charsheet";
	end
	return "charselect_client", "";
end

function getStoryDisplayClass(node)
	if node then
		local sRecord = DB.getPath(node);
		if StringManager.startsWith(sRecord, "reference.refmanualdata") then
			return "referencemanualpage";
		end
		-- Handle special legacy case of embedded reference manual page data
		for _,sPath in ipairs(StoryIndexManager.getBookPaths()) do
			if StringManager.startsWith(sRecord, sPath) then
				return "referencemanualpage";
			end
		end
	end
	return "encounter";
end

function getSoundsetType(node)
	local sType = DB.getValue(node, "type", "");
	if sType == "trigger" then
		return Interface.getString("soundset_label_type_trigger");
	elseif sType == "content" then
		return Interface.getString("soundset_label_type_content");
	end
	return "";
end

aRecords = {
	["effect"] = {
		aDataMap = { "effects" },
		tOptions = {
			bExport = true,
			bExportListSkip = true,
			bHidden = true,
		},
	},
	["modifier"] = {
		aDataMap = { "modifiers" },
		tOptions = {
			bExport = true,
			bExportListSkip = true,
			bHidden = true,
		},
	},
	["picture"] = {
		sSidebarCategory = "library",
		aDataMap = { "picture" },
		sDisplayIndex = "picturelist",
		tOptions = {
			bHidden = true,
			bNoCategories = true,
			bNoLock = true,
			bNoShare = true,
		},
	},

	["soundset"] = {
		sSidebarCategory = "library",
		aDataMap = { "soundset", "reference.soundsets" },
		aCustomFilters = {
			["Type"] = { sField = "type", fGetValue = getSoundsetType },
		},
		tOptions = {
			bHidden = true,
			bExportNoReadOnly = true,
		},
	},

	["charsheet"] = {
		aDataMap = { "charsheet" },
		fGetLink = getCharListLink,
		aCustom = {
			tWindowMenu = { ["left"] = { "chat_speak", "token_find", }, ["right"] = { "charsheet_size", }, },
		},
		sExportPath = "pregencharsheet",
		sExportListClass = "pregencharselect",
		sExportTag = "character",
		tOptions = {
			bNoDuplicate = true,
			bNoLock = true,
			bNoShare = true,
			bCurrency = true,
			bInventory = true,
			bToken = true,
		},
	},
	["note"] = {
		sEditMode = "play",
		aDataMap = { "notes" },
		sListDisplayClass = "masterindexitem_note",
		tOptions = {
			bNoCategories = true,
		},
	},

	["story"] = {
		nExport = 2,
		aDataMap = { "encounter", "reference.refmanualdata", "reference.encounters", },
		sSidebarCategory = "world",
		sListDisplayClass = "masterindexitem_story",
		fRecordDisplayClass = getStoryDisplayClass,
		aRecordDisplayClasses = { "encounter", "referencemanualpage", },
		aGMListButtons = { "button_storytemplate", },
		aGMEditButtons = { "button_story_add_advanced", },
		aExportAuxSource = { "reference.refmanualindex", },
		aExportAuxTarget = { "reference.refmanualindex", },
	},
	["storytemplate"] = {
		aDataMap = { "storytemplate", "reference.storytemplates" },
		tOptions = {
			bExport = true,
			bHidden = true,
		},
	},
	["location"] = {
		aDataMap = { "location", "reference.location" },
		sSidebarCategory = "world",
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
		aCustom = {
			tWindowMenu = { ["right"] = { "chat_output" } },
		},
		tOptions = {
			bExport = true,
			bPicture = true,
		},
	},
	["quest"] = {
		aDataMap = { "quest", "reference.quests" },
		sSidebarCategory = "world",
		tOptions = {
			bExport = true,
		},
	},
	["image"] = {
		aDataMap = { "image", "reference.images" },
		sListDisplayClass = "masterindexitem_id",
		sRecordDisplayClass = "imagewindow",
		aGMListButtons = { "button_store_image", "button_folder_import_image_assets" },
		aGMEditButtons = { "button_add_image_import" },
		tOptions = {
			bExportNoReadOnly = true,
			bID = true,
		},
	},
	["npc"] = {
		aDataMap = { "npc", "reference.npcs" },
		sListDisplayClass = "masterindexitem_id",
		aGMEditButtons = { "button_add_npc_import" },
		aCustom = {
			tWindowMenu = { ["left"] = { "chat_speak" } },
		},
		sGMExportTag = "npc",
		tOptions = {
			bExport = true,
			bID = true,
			bPicture = true,
			bToken = true,
			bCustomDie = true,
		},
	},
	["battle"] = {
		aDataMap = { "battle", "reference.battles" },
		aGMListButtons = { "button_battlerandom", "button_battle_quickmap" },
		aCustom = {
			tWindowMenu = { ["left"] = { "battle_addtoquickmap", "battle_addtotracker", } },
		},
		tOptions = {
			bExport = true,
		},
	},
	["battlerandom"] = {
		aDataMap = { "battlerandom", "reference.battlerandoms" },
		tOptions = {
			bExport = true,
			bHidden = true,
		},
	},
	["item"] = {
		aDataMap = { "item", "reference.items" },
		sListDisplayClass = "masterindexitem_id",
		tOptions = {
			bExport = true,
			bID = true,
			bPicture = true,
		},
	},
	["treasureparcel"] = {
		aDataMap = { "treasureparcels", "reference.treasureparcels" },
		aCustom = {
			tWindowMenu = { ["left"] = { "id_all", "parcel_addtotracker", } },
			tCurrencyPaths = { "coinlist" },
			tInventoryPaths = { "itemlist" },
			sCurrencyNameField = "description",
		},
		tOptions = {
			bExport = true,
			bCurrency = true,
			bInventory = true,
			bInvNoTransfer = true,
		},
	},
	["table"] = {
		aDataMap = { "tables", "reference.tables" },
		aGMEditButtons = { "button_add_table_guided", "button_add_table_import_text" },
		tOptions = {
			bExport = true,
		},
	},
	["vehicle"] = {
		aDataMap = { "vehicle", "reference.vehicles" },
		aGMListButtons = { "button_vehicle_type" },
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
		tOptions = {
			bExport = true,
			bID = true,
			bPicture = true,
			bToken = true,
		},
	},
};

aListViews = {
	["vehicle"] = {
		["bytype"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "vehicle_grouped_label_name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "vehicle_grouped_label_cost", nWidth=80, bCentered=true },
				{ sName = "speed", sType = "string", sHeadingRes = "vehicle_grouped_label_speed",
					sTooltipRes="vehicle_grouped_tooltip_speed", nWidth=200, bWrapped=true },
			},
			aFilters = {},
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = {},
		},
	},
};

function getRecordData()
	if not aRecords then
		aRecords = {};
	end
	return aRecords;
end
function getRecordViewData()
	if not aListViews then
		aListViews = {};
	end
	return aListViews;
end

--
--	MIGRATED TO RecordDataManager
--

function getRecordTypes()
	return RecordDataManager.getRecordTypes();
end
function isRecordType(sRecordType)
	return RecordDataManager.isRecordType(sRecordType);
end
function getRecordTypeInfo(sRecordType)
	return RecordDataManager.getRecordTypeData(sRecordType);
end
function setRecordTypeInfo(sRecordType, tRecordType)
	RecordDataManager.setRecordTypeData(sRecordType, tRecordType);
end
function overrideRecordTypes(tRecordTypes)
	RecordDataManager.overrideRecordData(tRecordTypes);
end
function overrideRecordTypeInfo(sRecordType, tOverrides)
	RecordDataManager.overrideRecordTypeData(sRecordType, tOverrides)
end

function getRootMapping(sRecordType)
	return RecordDataManager.getDataPathRoot(sRecordType);
end
function getMappings(sRecordType)
	return RecordDataManager.getDataPaths(sRecordType);
end

function getCustomData(sRecordType, sKey)
	return RecordDataManager.getCustomData(sRecordType, sKey);
end
function setCustomData(sRecordType, sKey, v)
	RecordDataManager.setCustomData(sRecordType, sKey, v);
end
function getRecordDisplayClass(sRecordType, sPath)
	return RecordDataManager.getRecordTypeDisplayClass(sRecordType, sPath);
end
function isRecordDisplayClass(sRecordType, sClass)
	return RecordDataManager.isRecordTypeDisplayClass(sRecordType, sClass);
end
function getRecordTypeFromDisplayClass(sClass)
	return RecordDataManager.getRecordTypeFromDisplayClass(sClass);
end
function getAllRecordTypesFromDisplayClass(sClass)
	return RecordDataManager.getAllRecordTypesFromDisplayClass(sClass);
end

function getRecordTypeFromWindow(w)
	return RecordDataManager.getRecordTypeFromWindow(w);
end
function getRecordTypeFromClassAndPath(sClass, sRecord)
	return RecordDataManager.getRecordTypeFromClassAndPath(sClass, sRecord);
end
function getRecordTypeFromPath(sPath)
	return RecordDataManager.getRecordTypeFromListPath(sPath);
end
function getRecordTypeFromRecordPath(sRecord)
	return RecordDataManager.getRecordTypeFromRecordPath(sRecord);
end

function getDisplayText(sRecordType)
	return RecordDataManager.getRecordTypeDisplayText(sRecordType);
end
function getSingleDisplayText(sRecordType)
	return RecordDataManager.getRecordTypeDisplayTextSingle(sRecordType);
end
function getEmptyNameText(sRecordType)
	return RecordDataManager.getRecordTypeDisplayTextEmpty(sRecordType);
end
function getEmptyUnidentifiedNameText(sRecordType)
	return RecordDataManager.getRecordTypeDisplayTextEmptyUnidentified(sRecordType);
end

function isHidden(sRecordType)
	return RecordDataManager.isHidden(sRecordType);
end
function setHidden(sRecordType, bHidden)
	RecordDataManager.setHidden(sRecordType, bHidden);
end

function getLockMode(sRecordType)
	return RecordDataManager.getLockMode(sRecordType);
end
function getShareMode(sRecordType)
	return RecordDataManager.getShareMode(sRecordType);
end

function getIDMode(sRecordType)
	return RecordDataManager.getIDMode(sRecordType);
end
function isIdentifiable(sRecordType, nodeRecord)
	return RecordDataManager.isIdentifiable(sRecordType, nodeRecord);
end
function getIDState(sRecordType, nodeRecord, bIgnoreHost)
	return RecordDataManager.getIDState(sRecordType, nodeRecord, bIgnoreHost);
end

--
--	MIGRATED TO RecordIndexManager
--

function getIndexDisplayClass(sRecordType)
	return RecordIndexManager.getItemDisplayClass(sRecordType);
end
function getIndexButtons(sRecordType)
	return RecordIndexManager.getButtons(sRecordType);
end
function addIndexButton(sRecordType, sTemplate)
	RecordIndexManager.addButton(sRecordType, sTemplate);
end
function removeIndexButton(sRecordType, sTemplate)
	RecordIndexManager.removeButton(sRecordType, sTemplate);
end
function getEditButtons(sRecordType)
	return RecordIndexManager.getEditButtons(sRecordType);
end
function getCustomFilters(sRecordType)
	return RecordIndexManager.getCustomFilters(sRecordType);
end

function getCategoryMode(sRecordType)
	return RecordIndexManager.getCategoryMode(sRecordType);
end
function allowEdit(sRecordType)
	return RecordIndexManager.getEditMode(sRecordType);
end

--
--	MIGRATED TO RecordViewManager
--

function initRecordView(sRecordType, sRecordView)
	RecordIndexViewManager.initRecordTypeView(sRecordType, sRecordView);
end

function getRecordViews(sRecordType)
	return RecordIndexViewManager.getRecordTypeViews(sRecordType);
end
function getRecordView(sRecordType, sRecordView)
	return RecordIndexViewManager.getRecordTypeView(sRecordType, sRecordView);
end
function setRecordViews(tRecordViews)
	RecordIndexViewManager.setRecordViews(tRecordViews);
end
function setRecordView(sRecordType, sRecordView, tRecordViewData)
	RecordIndexViewManager.setRecordTypeView(sRecordType, sRecordView, tRecordViewData);
end
function setListView(sRecordType, sRecordView, tRecordViewData)
	RecordIndexViewManager.setRecordTypeView(sRecordType, sRecordView, tRecordViewData);
end

function setCustomFilterHandler(sKey, fn)
	RecordIndexViewManager.setCustomFilterHandler(sKey, fn);
end
function getCustomFilterValue(sKey, nodeRecord, rFilter)
	return RecordIndexViewManager.getCustomFilterValue(sKey, nodeRecord, rFilter);
end

function setCustomColumnHandler(sKey, fn)
	RecordIndexViewManager.setCustomColumnHandler(sKey, fn);
end
function getCustomColumnValue(sKey, nodeRecord, vDefault)
	return RecordIndexViewManager.getCustomColumnValue(sKey, nodeRecord, vDefault);
end

function setCustomGroupOutputHandler(sKey, fn)
	RecordIndexViewManager.setCustomGroupOutputHandler(sKey, fn);
end
function getCustomGroupOutput(sKey, vGroupValue)
	return RecordIndexViewManager.getCustomGroupOutput(sKey, vGroupValue);
end
