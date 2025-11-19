--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function encodeActionText(rAction)
	return ActionCore.encodeActionText(rAction, "action_heal_tag");
end
function decodeRollData(rRoll)
	ActionCore.decodeRollData(rRoll, "action_heal_tag");
end
function decodeLabelText(s)
	return ActionCore.decodeLabelText(s, "action_heal_tag");
end
