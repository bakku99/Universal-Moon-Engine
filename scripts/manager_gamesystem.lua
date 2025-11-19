--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = "true" },
	["table"] = { },
	["effect"] = { sIcon = "action_effect", sTargeting = "all" },
};

targetactions = {
	"effect",
};

languages = { };

currencies = { };
currencyDefault = nil;

-- Several rulesets inherit from this one: AFF2, Fate Core, ICONS
function onInit()
	CharEncumbranceManager.addStandardCalc();
	CombatListManager.registerStandardInitSupport();
end

function getCharSelectDetailHost(_)
	return "";
end

function requestCharSelectDetailClient()
	return "name";
end

function receiveCharSelectDetailClient(vDetails)
	return vDetails, "";
end

function getDistanceUnitsPerGrid()
	return 1;
end
