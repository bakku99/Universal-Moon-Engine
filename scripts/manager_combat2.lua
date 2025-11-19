--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncStandard);
	CombatManager.setCustomCombatReset(CombatManager.resetStandardInit);

	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", ActorCommonManager.getSpaceReachCore);
	ActorCommonManager.setRecordTypeSpaceReachCallback("vehicle", ActorCommonManager.getSpaceReachCore);
end
