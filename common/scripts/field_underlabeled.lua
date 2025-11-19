--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals labelres label

function onInit()
	local labelwidget = nil;
	if labelres then
		labelwidget = addTextWidget({
			font = "sheetlabelinline",
			text = Interface.getString(labelres[1]):upper(),
		});
	elseif label then
		labelwidget = addTextWidget({
			font = "sheetlabelinline",
			text = label[1]:upper(),
		});
	end
	if labelwidget then
		local w,h = labelwidget.getSize();
		labelwidget.setPosition("bottomleft", w/2, h/2-5);
	end
end
