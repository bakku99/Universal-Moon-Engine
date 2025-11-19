--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function setState(bCurrDay, bSelDay, bHoliday, nodeEvent)
	if bCurrDay then
		label_day.setColor(ColorManager.getUIColor("calendar_day"));
	else
		label_day.setColor(nil);
	end
	if bCurrDay or bHoliday then
		label_day.setFont("sheetlabel");
	else
		label_day.setFont("sheettext");
	end
	if bHoliday then
		label_day.setUnderline(true);
	else
		label_day.setUnderline(false);
	end
	if bSelDay then
		setFrame("calendarhighlight");
	else
		setFrame(nil);
	end

	if nodeEvent then
		local sText = DB.getText(nodeEvent, "logentry");
		local bText = (sText ~= "");
		local sGMText = DB.getText(nodeEvent, "gmlogentry");
		local bGMText = (sGMText ~= "");

		if Session.IsHost then
			icon_event.setVisible(bText);
			if bText then
				icon_gmevent.setVisible(bGMText);
			else
				icon_gmevent.setVisible(true);
			end
		else
			icon_event.setVisible(bText);
		end

		if Session.IsHost then
			resetMenuItems();
			registerMenuItem(Interface.getString("calendar_menu_eventdelete"), "delete", 6);
			registerMenuItem(Interface.getString("calendar_menu_eventdeleteconfirm"), "delete", 6, 7);
		end
	else
		icon_gmevent.setVisible(false);
		icon_event.setVisible(false);
		resetMenuItems();
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local nDay = day.getValue();
		if nDay > 0 then
			local nMonth = windowlist.window.month.getValue();
			windowlist.window.windowlist.window.removeLogEntry(nMonth, nDay);
		end
	end
end
