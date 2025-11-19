--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local RULESET_NAME = "CoreRPG";

function onInit()
	if Session.IsHost then
		VersionManager2.updateCampaign();
	end

	DB.addEventHandler("onAuxCharLoad", VersionManager2.onCharImport);
	DB.addEventHandler("onImport", VersionManager2.onImport);
end

function onCharImport(nodePC)
	local _, _, aMajor, _ = DB.getImportRulesetVersion();
	VersionManager2.updateChar(nodePC, aMajor[RULESET_NAME]);
end

function onImport(node)
	local aPath = StringManager.split(DB.getPath(node), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		local _, _, aMajor, _ = DB.getImportRulesetVersion();
		VersionManager2.updateChar(node, aMajor[RULESET_NAME]);
	end
end

function updateChar(nodePC, nVersion)
	if not nVersion then
		nVersion = 0;
	end

	if nVersion < 3 then
		if nVersion < 3 then
			VersionManager2.migrateChar3(nodePC);
		end
	end
end

function updateCampaign()
	local _, _, aMajor, _ = DB.getRulesetVersion();
	local major = aMajor[RULESET_NAME];
	if not major then
		return;
	end

	if major > 0 and major < 3 then
		ChatManager.SystemMessage("Migrating campaign database to latest data version. (" .. RULESET_NAME ..")");
		DB.backup();

		if major < 3 then
			VersionManager2.convertChars3();
		end
	end
end

function migrateChar3(nodeChar)
	if DB.getChildCount(nodeChar, "skilllist") > 0 then
		local nodeCategories = DB.createChild(nodeChar, "maincategorylist");
		local nodeCategory = DB.createChild(nodeCategories);
		local nodeAttributeList = DB.createChild(nodeCategory, "attributelist");
		if nodeAttributeList then
			for _,vSkill in ipairs(DB.getChildList(nodeChar, "skilllist")) do
				local vNewSkill = DB.createChild(nodeAttributeList);
				if vNewSkill then
					DB.copyNode(vSkill, vNewSkill);
					DB.deleteNode(vSkill);
				end
			end
		end
	end
	if DB.getChildCount(nodeChar, "skilllist") == 0 then
		DB.deleteChild(nodeChar, "skilllist");
	end
end

function convertChars3()
	for _,nodeChar in ipairs(DB.getChildList("charsheet")) do
		VersionManager2.migrateChar3(nodeChar);
	end
end
