--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sRecordType;
local _sClass;
local _sRecord;

--
--	Data
--

function setData(tButton)
	if tButton.sRecordType then
		self.setRecordType(tButton.sRecordType);
	else
		self.setDataLink(tButton.sLabelRes, tButton.sClass, tButton.sPath);
	end
	self.setCategory(tButton.sCategory);

	self.updateTheming();
	self.updateIcon(tButton.sIcon);
end

function setRecordType(v)
	_sRecordType = v;
	local sLabel = RecordDataManager.getRecordTypeDisplayText(_sRecordType);
	label.setValue(sLabel);
	setTooltipText(sLabel);
	iconbase.setTooltipText(sLabel);
end
function setDataLink(sLabelRes, sClass, sRecord)
	_sClass = sClass;
	_sRecord = sRecord;
	local sLabel = Interface.getString(sLabelRes or ("sidebar_tooltip_" .. _sClass));
	label.setValue(sLabel);
	setTooltipText(sLabel);
	iconbase.setTooltipText(sLabel);
end

local _sCategory;
function setCategory(sCategory)
	_sCategory = sCategory;
end
function getCategory()
	return _sCategory;
end

function updateTheming()
	local nSidebarVisState = DesktopManager.getSidebarVisibilityState();

	local szArea;
	if nSidebarVisState <= 0 then
		szArea = DesktopManager.getSidebarDockButtonSize();
	else
		szArea = DesktopManager.getSidebarDockButtonSize();
		szArea.w = DesktopManager.getSidebarDockIconWidth();
	end

	local rcOffset = DesktopManager.getSidebarDockButtonOffset();

	local szIconPadding = DesktopManager.getSidebarDockButtonIconPadding();
	local szTextPadding = DesktopManager.getSidebarDockButtonTextPadding();
	local sIconColor = ColorManager.getSidebarRecordIconColor();
	local sTextColor = ColorManager.getSidebarRecordTextColor();

	local nIconArea = math.min(szArea.w, szArea.h);

	spacer.setAnchoredWidth(szArea.w + (rcOffset.left + rcOffset.right));
	spacer.setAnchoredHeight(szArea.h + (rcOffset.top + rcOffset.bottom));

	iconbase.setAnchor("left", "", "left", "absolute", rcOffset.left);
	iconbase.setAnchor("top", "", "top", "absolute", rcOffset.top);
	iconbase.setAnchoredWidth(nIconArea);
	iconbase.setAnchoredHeight(nIconArea);
	icon.setAnchor("left", "", "left", "absolute", rcOffset.left + math.min(szIconPadding.w, szArea.w));
	icon.setAnchor("top", "", "top", "absolute", rcOffset.top + math.min(szIconPadding.h, szArea.h));
	icon.setAnchoredWidth(math.max(nIconArea - (szIconPadding.w * 2), 0));
	icon.setAnchoredHeight(math.max(nIconArea - (szIconPadding.h * 2), 0));
	base.setVisible(nSidebarVisState <= 0);
	base.setAnchor("left", "", "left", "absolute", rcOffset.left + nIconArea);
	base.setAnchor("top", "", "top", "absolute", rcOffset.top);
	base.setAnchoredWidth(math.max(szArea.w - nIconArea, 0));
	base.setAnchoredHeight(szArea.h);
	label.setVisible(nSidebarVisState <= 0);
	label.setAnchor("left", "", "left", "absolute", rcOffset.left + math.min(nIconArea + szTextPadding.w, szArea.w));
	label.setAnchor("top", "", "top", "absolute", rcOffset.top + math.min(szTextPadding.h, szArea.h));
	label.setAnchoredWidth(math.max(szArea.w - nIconArea - (szTextPadding.w * 2), 0));
	label.setAnchoredHeight(math.max(szArea.h - (szTextPadding.h * 2), 0));

	icon.setColor(sIconColor);
	label.setColor(sTextColor);
end

function updateIcon(sIcon)
	if not sIcon then
		if _sRecordType then
			sIcon = "sidebar_icon_recordtype_" .. _sRecordType;
		else
			sIcon = "sidebar_icon_link_" .. _sClass;
		end
	end
	if Interface.isIcon(sIcon) then
		icon.setIcon(sIcon);
	else
		icon.setIcon("sidebar_icon_default");
	end
	icon.setColor(ColorManager.getSidebarRecordIconColor());
end
function updateFrame(bPressed)
	if bPressed then
		if Interface.isFrame("sidebar_dock_entry_down") then
			base.setFrame("sidebar_dock_entry_down");
		end
		if Interface.isFrame("sidebar_dock_entry_icon_down") then
			iconbase.setFrame("sidebar_dock_entry_icon_down");
		elseif Interface.isFrame("sidebar_dock_entry_down") then
			iconbase.setFrame("sidebar_dock_entry_down");
		end
	else
		base.setFrame("sidebar_dock_entry");
		iconbase.setFrame("sidebar_dock_entry_icon");
	end
end

--
--  UI Events
--

function onClickDown()
	self.updateFrame(true);
	return true;
end
function onClickRelease()
	if _sRecordType then
		DesktopManager.toggleIndex(_sRecordType);
	elseif _sClass then
		Interface.toggleWindow(_sClass, _sRecord);
	end
	self.updateFrame(false);
	return true;
end
function onDragStart(_, _, _, draginfo)
	draginfo.setType("shortcut");
	if _sRecordType then
		local sClass, sRecord = DesktopManager.getListLink(_sRecordType);
		draginfo.setShortcutData(sClass, sRecord);
		draginfo.setIcon(Interface.getLinkIcon(sClass));
	elseif _sClass then
		draginfo.setShortcutData(_sClass, _sRecord or "");
		draginfo.setIcon(Interface.getLinkIcon(_sClass));
	else
		draginfo.setIcon(Interface.getLinkIcon(""));
	end
	draginfo.setDescription(iconbase.getTooltipText());
	draginfo.setStringData(iconbase.getTooltipText());
	return true;
end
function onDragEnd()
	self.updateFrame(false);
end
