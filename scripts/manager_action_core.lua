--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function isActionText(s, sTextRes)
	if not s or not sTextRes then
		return false;
	end
	local sTag = Interface.getString(sTextRes);
	if sTag == "" then
		return false;
	end
	local sPattern = string.format("%%[%s[^]]*%%]", sTag);
	return (s:match(sPattern) and true or false);
end
function encodeActionText(rAction, sTextRes)
	local tOutput = {};
	table.insert(tOutput, Interface.getString(sTextRes));
	if (rAction.order or 1) > 1 then
		table.insert(tOutput, string.format("#%d", rAction.order));
	end
	if (rAction.range or "") ~= "" then
		table.insert(tOutput, string.format("(%s)", rAction.range));
	end
	return string.format("[%s] %s", table.concat(tOutput, " "), StringManager.capitalizeAll(rAction.label or ""));
end
function decodeRollData(rRoll, sTextRes)
	if not rRoll or not sTextRes then
		return;
	end
	if not rRoll.sDesc then
		return;
	end
	local sTag = Interface.getString(sTextRes);
	if not rRoll.nOrder then
		local sPattern = string.format("%%[%s.-#(%%d+)", sTag);
		rRoll.nOrder = tonumber(rRoll.sDesc:match(sPattern)) or nil;
	end
	if not rRoll.sRange then
		local sPattern = string.format("%%[%s.-%%((%%w+)%%)%%]", sTag);
		rRoll.sRange = rRoll.sDesc:match(sPattern);
	end
	if not rRoll.sLabel then
		local sPattern = string.format("%%[%s.-%%]([^%%[]+)", sTag);
		rRoll.sLabel = StringManager.trim(rRoll.sDesc:match(sPattern));
	end
end

function decodeLabelText(s, sTextRes)
	if not s or not sTextRes then
		return "";
	end
	local sTag = Interface.getString(sTextRes);
	if sTag == "" then
		return "";
	end
	local sPattern = string.format("%%[%s[^]]*%%] ([^[]+)", sTag);
	return StringManager.trim(s:match(sPattern) or "");
end
function decodeRangeText(s, sTextRes)
	if not s or not sTextRes then
		return "";
	end
	local sTag = Interface.getString(sTextRes);
	if sTag == "" then
		return "";
	end
	local sPattern = string.format("%%[%s.*%%((%%w+)%%)%%]", sTag);
	return s:match(sPattern) or "";
end
