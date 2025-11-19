--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	Desktop.registerPublicNodes();
end
function onTabletopInit()
	DB.addEventHandler("onDataLoaded", Desktop.onDataLoaded);
	Desktop.registerModuleSets();
end
function onDataLoaded()
	WindowSaveManager.loadWindowState();
	Desktop.handleMOTDOnStartup();
	UserManager.loadIdentityState();
	Desktop.handleUserSetupOnStartup();
end

function registerPublicNodes()
	if Session.IsHost then
		DB.setPublic(DB.createNode("charsheet"), true);
		DB.setPublic(DB.createNode("motd"), true);
		DB.setPublic(DB.createNode("options"), true);
		DB.setPublic(DB.createNode("partysheet"), true);
		DB.setPublic(DB.createNode("calendar"), true);
		DB.setPublic(DB.createNode("combattracker"), true);
		DB.setPublic(DB.createNode("modifiers"), true);
		DB.setPublic(DB.createNode("effects"), true);
		DB.setPublic(DB.createNode("picture"), true);
	end
end

function handleMOTDOnStartup()
	if Session.IsHost then
		return;
	end
	local sMOTD = StringManager.trim(DB.getText("motd.text", ""));
	if sMOTD ~= "" then
		Interface.openWindow("motd", "motd");
	end
end
function handleUserSetupOnStartup()
	if CampaignRegistry and CampaignRegistry.setup then
		return;
	end

	Interface.openWindow("setup", "");
end

aDataModuleSet =
{
	["host"] =
	{
	},
	["client"] =
	{
	},
};
function registerModuleSets()
	if Session.IsHost then
		DesktopManager.addDataModuleSets(Desktop.aDataModuleSet["host"]);
	else
		DesktopManager.addDataModuleSets(Desktop.aDataModuleSet["client"]);
	end
end
function addDataModuleSet(sMode, tData)
	if not Desktop.aDataModuleSet[sMode] then
		return;
	end
	table.insert(Desktop.aDataModuleSet[sMode], tData);
end

aCoreDesktopStack =
{
	["host"] =
	{
		{
			sIcon = "sidebar_icon_link_ct",
			tooltipres="sidebar_tooltip_ct",
			class="combattracker_host",
			path="combattracker",
		},
		{
			sIcon = "sidebar_icon_link_ps",
			tooltipres="sidebar_tooltip_ps",
			class="partysheet_host",
			path="partysheet",
		},
		{
			class="calendar",
			path="calendar",
		},
		{
			class="diceselect",
		},
		{
			class="modifiers",
			path="modifiers",
		},
		{
			class="effectlist",
			path="effects",
		},
		{
			class="options",
		},
	},
	["client"] =
	{
		{
			sIcon = "sidebar_icon_link_ct",
			tooltipres="sidebar_tooltip_ct",
			class="combattracker_client",
			path="combattracker",
		},
		{
			sIcon = "sidebar_icon_link_ps",
			tooltipres="sidebar_tooltip_ps",
			class="partysheet_client",
			path="partysheet",
		},
		{
			class="calendar",
			path="calendar",
		},
		{
			class="diceselect",
		},
		{
			class="modifiers",
			path="modifiers",
		},
		{
			class="effectlist",
			path="effects",
		},
		{
			class="options",
		},
	},
};
aCoreDesktopDockV4 =
{
	["live"] =
	{
		{
			tooltipres="sidebar_tooltip_assets",
			class="tokenbag",
		},
		{
			class="library",
		},
		{
			sIcon = "sidebar_icon_link_story_book",
			tooltipres="sidebar_tooltip_story_book",
			class="story_book_list",
		},
	},
};
