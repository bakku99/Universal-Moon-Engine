--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	font.add("", "");
	if GameSystem.languagefonts then
		for _,s in pairs(GameSystem.languagefonts) do
			font.add(s);
		end
	end
end

function onHover(bState)
	if bState then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end
function onDragStart(_, _, _, draginfo)
	local sLang = name.getValue();
	if sLang ~= "" then
		draginfo.setType("language");
		draginfo.setIcon("button_speak");
		draginfo.setStringData(sLang);
		return true;
	end
end
