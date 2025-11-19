--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals toggletarget

function onInit()
	local node = getDatabaseNode();

	local sDesc = DB.getValue(node, "description", "");
	if description then
		description.setValue(sDesc);
	elseif header then
		local sSubDesc = DB.getValue(node, "subdescription", "");
		if sSubDesc ~= "" then
			sDesc = string.format("%s - %s", sDesc, sSubDesc);
		end
		header.setValue(sDesc);
	end

	if myfooter then
		myfooter.setVisible(not myfooter.isEmpty());
	elseif footer then
		footer.setVisible(not footer.isEmpty());
	else
		local sPath = DB.getPath(node, "myfooter");
		if not DB.isEmpty(sPath) then
			createControl("ft_content_noscroll_static_top", "myfooter");
		else
			sPath = DB.getPath(node, "footer");
			if not DB.isEmpty(sPath) then
				createControl("ft_content_noscroll_static_top", "footer");
			end
		end
	end
end

function onToggle()
	local cList = toggletarget and self[toggletarget[1]] or self.list;
	cList.setVisible(not cList.isVisible());
end

function showFullHeaders(show_flag)
	if descframe then
		descframe.setVisible(show_flag);
	end
	if description then
		description.setVisible(show_flag);
	elseif header then
		header.setVisible(show_flag);
	end
	if subdescription then
		subdescription.setVisible(show_flag and subdescription.getValue ~= "");
	end
end
