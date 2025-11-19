--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function encodeActionText(rAction)
	return ActionCore.encodeActionText(rAction, "action_attack_tag");
end
function decodeRollData(rRoll)
	ActionCore.decodeRollData(rRoll, "action_attack_tag");
end
function decodeRangeText(s)
	return ActionCore.decodeRangeText(s, "action_attack_tag");
end
function decodeLabelText(s)
	return ActionCore.decodeLabelText(s, "action_attack_tag");
end
