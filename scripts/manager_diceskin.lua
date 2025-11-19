--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

WIDGET_PADDING = 2;
WIDGET_SIZE = 16;
WIDGET_HALF_SIZE = 8;

CONTROL_WIDGET_PADDING = 2;
CONTROL_WIDGET_SIZE = 10;
CONTROL_WIDGET_HALF_SIZE = 5;

function onInit()
	DiceSkinManager.buildDiceSkinInfo();
end

local _tDiceSkinInfo = {};
function buildDiceSkinInfo()
	local tDiceSkins = Interface.getDiceSkins();
	for _,v in pairs(tDiceSkins) do
		local tData = DiceSkinData.getDiceSkinAttributeInfo(v);
		if not tData or not tData.bDisabled then
			local tInfo = Interface.getDiceSkinInfo(v);
			if tData then
				for k,v in pairs(tData) do
					tInfo[k] = v;
				end
			end
			_tDiceSkinInfo[v] = tInfo;
		end
	end
	DiceSkinManager.buildOrderedDiceSkinList();
end
function getAllDiceSkins()
	return _tDiceSkinInfo;
end
function getDiceSkinInfo(tColor)
	if not tColor or not tColor.diceskin then
		return nil;
	end
	return _tDiceSkinInfo[tColor.diceskin];
end
function getDiceSkinInfoByID(nID)
	return _tDiceSkinInfo[nID];
end
function getOwnedDiceSkinIDs()
	local tResults = {};
	for nID, tInfo in pairs(DiceSkinManager.getAllDiceSkins()) do
		if tInfo.owned then
			table.insert(tResults, nID);
		end
	end
	return tResults;
end

function isDiceSkinOwned(tColor)
	if tColor and tColor.diceskin then
		return DiceSkinManager.isDiceSkinOwnedByID(tColor.diceskin);
	end
	return false;
end
function isDiceSkinOwnedByID(nID)
	if not nID then
		return false;
	end
	if nID == 0 then
		return true;
	end
	local tInfo = DiceSkinManager.getDiceSkinInfoByID(nID);
	if tInfo then
		return tInfo.owned or false;
	end
	return false;
end
function isDiceSkinTintable(tColor)
	if tColor and tColor.diceskin then
		return DiceSkinManager.isDiceSkinTintableByID(tColor.diceskin);
	end
	return false;
end
function isDiceSkinTintableByID(nID)
	if not nID then
		return false;
	end
	if nID == 0 then
		return true;
	end
	local tInfo = DiceSkinManager.getDiceSkinInfoByID(nID);
	if tInfo then
		return tInfo.bTintable or false;
	end
	return true;
end

function getDiceSkinGroupName(nID)
	return Interface.getString("diceskin_group_" .. DiceSkinData.getDiceSkinGroup(nID));
end
function getDiceSkinName(tColor)
	if tColor and tColor.diceskin then
		return DiceSkinManager.getDiceSkinNameByID(tColor.diceskin);
	end
	return "";
end
function getDiceSkinNameByID(nID)
	return Interface.getString("diceskin_" .. nID);
end

function getDiceSkinIcon(tColor)
	if tColor and tColor.diceskin then
		return DiceSkinManager.getDiceSkinIconByID(tColor.diceskin);
	end
	return "diceskin_icon_default";
end
function getDiceSkinIconByID(nID)
	if nID and (nID > 0) then
		local sIDIcon = string.format("diceskin_icon_%d", nID);
		if Interface.isIcon(sIDIcon) then
			return sIDIcon;
		end
	end
	return "diceskin_icon_default";
end

local _tOrderedDice = {};
function getOrderedDiceSkinList()
	return _tOrderedDice;
end
function buildOrderedDiceSkinList()
	local tByGroup = {};
	for _,sGroupID in ipairs(DiceSkinData.getDiceSkinGroups()) do
		table.insert(tByGroup, { sGroupID = sGroupID, tDiceIDs = {}});
	end
	for nID, _ in pairs(DiceSkinManager.getAllDiceSkins()) do
		local sDiceSkinGroup = DiceSkinData.getDiceSkinGroup(nID);
		if not StringManager.contains(DiceSkinData.getDiceSkinGroups(), sDiceSkinGroup) then
			sDiceSkinGroup = DiceSkinData.DEFAULT_DICESKIN_GROUP;
		end
		for _,tGroup in ipairs(tByGroup) do
			if tGroup.sGroupID == sDiceSkinGroup then
				table.insert(tGroup.tDiceIDs, nID);
				break;
			end
		end
	end

	_tOrderedDice = {};
	for _,tGroup in ipairs(tByGroup) do
		table.sort(tGroup.tDiceIDs);
		for _, nID in ipairs(tGroup.tDiceIDs) do
			table.insert(_tOrderedDice, { nID = nID, sGroupID = tGroup.sGroupID, } )
		end
	end
end

--
-- CONVERSIONS
--		diceskin | diceboydcolor | dicetextcolor
--

function convertStringToTable(sDiceSkin)
	local tSplit = StringManager.split(sDiceSkin, "|", true);
	if #tSplit <= 1 and (tSplit[1] or "") == "" then
		return nil;
	end

	local tDiceSkin = {
		diceskin = tonumber(tSplit[1]) or 0,
		dicebodycolor = tSplit[2],
		dicetextcolor = tSplit[3],
	};
	return tDiceSkin;
end
function convertTableToString(tDiceSkin)
	if not tDiceSkin then
		return "";
	end

	local tOutput = {};
	if tDiceSkin.dicebodycolor or tDiceSkin.dicetextcolor then
		table.insert(tOutput, tDiceSkin.dicebodycolor or "");
		table.insert(tOutput, tDiceSkin.dicetextcolor or "");
	end
	if (#tOutput > 0) or ((tDiceSkin.diceskin or 0) ~= 0) then
		table.insert(tOutput, 1, tostring(tDiceSkin.diceskin or 0));
	end

	return table.concat(tOutput, "|");
end

--
--	COLOR WINDOW HANDLING
--

function populateDiceSelectWindow(w)
	local cCombo = DiceSkinManager.getDiceSelectGroupControl(w);
	local tOptions = {};
	table.insert(tOptions, { sText = Interface.getString("diceselect_label_group_all"), sValue = "", })
	for _,sGroupID in ipairs(DiceSkinData.getDiceSkinGroups()) do
		table.insert(tOptions, { sText = Interface.getString("diceskin_group_" .. sGroupID), sValue = sGroupID, });
	end
	cCombo.setItems(tOptions);

	-- NOTE: If starting value is empty string (i.e. All), then make this call instead
	--DiceSkinManager.onDiceSelectGroupChanged(w);
	cCombo.setValue(DiceSkinData.DEFAULT_DICESKIN_GROUP);
end

function setupDiceSelectButton(cButton, nID)
	cButton.setIcons(DiceSkinManager.getDiceSkinIconByID(nID));
	cButton.setTooltipText(DiceSkinManager.getDiceSkinNameByID(nID));

	DiceSkinManager.setupButtonTintableWidget(cButton, nID);
	DiceSkinManager.setupButtonGeneralWidgets(cButton, nID)
end
function setupButtonTintableWidget(cButton, nID)
	cButton.deleteWidget("attributetintable");

	local tInfo = _tDiceSkinInfo[nID];

	-- Tintable
	if tInfo and tInfo.bTintable then
		cButton.addBitmapWidget({
			name = "attributetintable",
			icon = "diceskin_attribute_tintable",
			position = "topright",
			x = -(DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE),
			y = (DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE),
			w = DiceSkinManager.WIDGET_SIZE,
			h = DiceSkinManager.WIDGET_SIZE,
		});
	end
end
function setupButtonGeneralWidgets(cButton, nID)
	cButton.deleteWidget("attributefx");
	cButton.deleteWidget("attributeimpact");
	cButton.deleteWidget("attributetrail");

	local tInfo = _tDiceSkinInfo[nID];

	-- Attributes
	if tInfo then
		local tWidget = {
			position = "topleft",
			x = DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE,
			y = DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE,
			w = DiceSkinManager.WIDGET_SIZE,
			h = DiceSkinManager.WIDGET_SIZE,
		};

		if tInfo.bFX then
			tWidget.name = "attributefx";
			tWidget.icon = "diceskin_attribute_fx";
			cButton.addBitmapWidget(tWidget);
			tWidget.y = tWidget.y + DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_SIZE;
		end
		if tInfo.bImpact then
			tWidget.name = "attributeimpact";
			tWidget.icon = "diceskin_attribute_impact";
			cButton.addBitmapWidget(tWidget);
			tWidget.y = tWidget.y + DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_SIZE;
		end
		if tInfo.bTrail then
			tWidget.name = "attributetrail";
			tWidget.icon = "diceskin_attribute_trail";
			cButton.addBitmapWidget(tWidget);
			tWidget.y = tWidget.y + DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_SIZE;
		end
	end
end

function setupCustomControl(c, tColor, bDisabled)
	DiceSkinManager.setupControlBaseWidget(c, tColor, bDisabled);
	DiceSkinManager.setupControlColorWidgets(c, tColor, bDisabled);
	DiceSkinManager.setupControlGeneralWidgets(c, tColor, bDisabled)

	c.setTooltipText(DiceSkinManager.getDiceSkinName(tColor));
end
function setupControlBaseWidget(c, tColor, bDisabled)
	if tColor then
		local wgt = c.findWidget("icon");
		if not wgt then
			local tWidget = {
				name = "icon",
				w = c.getAnchoredWidth(),
				h = c.getAnchoredHeight(),
			};
			wgt = c.addBitmapWidget(tWidget);
		end
		wgt.setBitmap(DiceSkinManager.getDiceSkinIcon(tColor));
		if bDisabled then
			wgt.setColor("E62B2B2B");
		else
			wgt.setColor(nil);
		end
	else
		c.deleteWidget("icon");
	end
end
function setupControlColorWidgets(c, tColor, bDisabled)
	local tInfo = DiceSkinManager.getDiceSkinInfo(tColor);

	-- Tintable
	local wgt;
	if not bDisabled and tInfo and tInfo.bTintable then
		local bLarge = (c.getAnchoredWidth() >= 60);

		local tWidget;
		if bLarge then
			tWidget = {
				position = "topright",
				x = -(DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE),
				y = (DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE),
				w = DiceSkinManager.WIDGET_SIZE,
				h = DiceSkinManager.WIDGET_SIZE,
			};
		else
			tWidget = {
				position = "topright",
				x = -(DiceSkinManager.CONTROL_WIDGET_PADDING + DiceSkinManager.CONTROL_WIDGET_HALF_SIZE),
				y = (DiceSkinManager.CONTROL_WIDGET_PADDING + DiceSkinManager.CONTROL_WIDGET_HALF_SIZE),
				w = DiceSkinManager.CONTROL_WIDGET_SIZE,
				h = DiceSkinManager.CONTROL_WIDGET_SIZE,
			};
		end

		wgt = c.findWidget("bodycolorbase");
		if not wgt then
			tWidget.name = "bodycolorbase";
			tWidget.icon = "colorgizmo_bigbtn_base";
			c.addBitmapWidget(tWidget);
		end

		wgt = c.findWidget("bodycolor");
		if not wgt then
			tWidget.name = "bodycolor";
			tWidget.icon = "colorgizmo_bigbtn_color";
			wgt = c.addBitmapWidget(tWidget);
		end
		wgt.setColor(tColor and tColor.dicebodycolor or "000000");

		wgt = c.findWidget("bodycolorfx");
		if not wgt then
			tWidget.name = "bodycolorfx";
			tWidget.icon = "colorgizmo_bigbtn_effects";
			c.addBitmapWidget(tWidget);
		end

		if bLarge then
			tWidget.y = (DiceSkinManager.WIDGET_SIZE + DiceSkinManager.WIDGET_HALF_SIZE);
		else
			tWidget.y = (DiceSkinManager.CONTROL_WIDGET_SIZE + DiceSkinManager.CONTROL_WIDGET_HALF_SIZE);
		end

		wgt = c.findWidget("textcolorbase");
		if not wgt then
			tWidget.name = "textcolorbase";
			tWidget.icon = "colorgizmo_bigbtn_base";
			c.addBitmapWidget(tWidget);
		end

		wgt = c.findWidget("textcolor");
		if not wgt then
			tWidget.name = "textcolor";
			tWidget.icon = "colorgizmo_bigbtn_color";
			wgt = c.addBitmapWidget(tWidget);
		end
		wgt.setColor(tColor and tColor.dicetextcolor or "000000");

		wgt = c.findWidget("textcolorfx");
		if not wgt then
			tWidget.name = "textcolorfx";
			tWidget.icon = "colorgizmo_bigbtn_effects";
			c.addBitmapWidget(tWidget);
		end
	else
		c.deleteWidget("bodycolorbase");
		c.deleteWidget("bodycolor");
		c.deleteWidget("bodycolorfx");

		c.deleteWidget("textcolorbase");
		c.deleteWidget("textcolor");
		c.deleteWidget("textcolorfx");
	end
end
function setupControlGeneralWidgets(c, tColor, bDisabled)
	local tInfo = DiceSkinManager.getDiceSkinInfo(tColor);

	-- Attributes
	if not bDisabled and tInfo then
		local bLarge = (c.getAnchoredWidth() > 20);

		local tWidget;
		if bLarge then
			tWidget = {
				position = "topleft",
				x = DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE,
				y = DiceSkinManager.WIDGET_PADDING + DiceSkinManager.WIDGET_HALF_SIZE,
				w = DiceSkinManager.WIDGET_SIZE,
				h = DiceSkinManager.WIDGET_SIZE,
			};
		else
			tWidget = {
				position = "topleft",
				x = DiceSkinManager.CONTROL_WIDGET_PADDING + DiceSkinManager.CONTROL_WIDGET_HALF_SIZE,
				y = DiceSkinManager.CONTROL_WIDGET_PADDING + DiceSkinManager.CONTROL_WIDGET_HALF_SIZE,
				w = DiceSkinManager.CONTROL_WIDGET_SIZE,
				h = DiceSkinManager.CONTROL_WIDGET_SIZE,
			};
		end

		local wgt = c.findWidget("attributefx");
		if tInfo.bFX then
			if not wgt then
				tWidget.name = "attributefx";
				tWidget.icon = "diceskin_attribute_fx";
				c.addBitmapWidget(tWidget);
			else
				wgt.setPosition(tWidget.position, tWidget.x, tWidget.y);
			end
			if bLarge then
				tWidget.y = tWidget.y + DiceSkinManager.WIDGET_SIZE;
			else
				tWidget.y = tWidget.y + DiceSkinManager.CONTROL_WIDGET_SIZE;
			end
		end
		wgt = c.findWidget("attributeimpact");
		if tInfo.bImpact then
			if not wgt then
				tWidget.name = "attributeimpact";
				tWidget.icon = "diceskin_attribute_impact";
				c.addBitmapWidget(tWidget);
			else
				wgt.setPosition(tWidget.position, tWidget.x, tWidget.y);
			end
			if bLarge then
				tWidget.y = tWidget.y + DiceSkinManager.WIDGET_SIZE;
			else
				tWidget.y = tWidget.y + DiceSkinManager.CONTROL_WIDGET_SIZE;
			end
		end
		wgt = c.findWidget("attributetrail");
		if tInfo.bTrail then
			if not wgt then
				tWidget.name = "attributetrail";
				tWidget.icon = "diceskin_attribute_trail";
				c.addBitmapWidget(tWidget);
			else
				wgt.setPosition(tWidget.position, tWidget.x, tWidget.y);
			end
			if bLarge then
				tWidget.y = tWidget.y + DiceSkinManager.WIDGET_SIZE;
			else
				tWidget.y = tWidget.y + DiceSkinManager.CONTROL_WIDGET_SIZE;
			end
		end
	else
		c.deleteWidget("attributefx");
		c.deleteWidget("attributeimpact");
		c.deleteWidget("attributetrail");
	end
end

function onDiceSkinRandomize()
	local tDiceSkinIDs = DiceSkinManager.getOwnedDiceSkinIDs();
	local tUserColor = UserManager.getColor();
	for k,nID in ipairs(tDiceSkinIDs) do
		if nID == tUserColor.diceskin then
			table.remove(tDiceSkinIDs, k);
			break;
		end
	end
	if #tDiceSkinIDs == 0 then
		return;
	end

	UserManager.setDiceSkin(tDiceSkinIDs[math.random(#tDiceSkinIDs)]);
end
function onDiceColorRandomize()
	local sBodyColor = ColorManager.generateRandomSolidColorString();
	local sTextColor = ColorManager.generateContrastingColorString(sBodyColor);
	UserManager.setDiceBodyColor(sBodyColor);
	UserManager.setDiceTextColor(sTextColor);
end

function getDiceSelectGroupControl(w)
	return w.sub_selection.subwindow.sub_groups.subwindow.group;
end
function getDiceSelectGroup(w)
	return DiceSkinManager.getDiceSelectGroupControl(w).getValue();
end
function setDiceSelectGroup(w, sGroupID)
	DiceSkinManager.getDiceSelectGroupControl(w).setValue(sGroupID);
end
function onDiceSelectGroupChanged(w)
	local sCurrentGroup = DiceSkinManager.getDiceSelectGroup(w);

	local cList = w.sub_selection.subwindow.list;
	cList.closeAll();

	local nOrder = 1;
	for _,tOrderedDiceSkin in ipairs(DiceSkinManager.getOrderedDiceSkinList()) do
		if ((sCurrentGroup or "") == "") or (sCurrentGroup == tOrderedDiceSkin.sGroupID) then
			local wDiceSkin = cList.createWindow();
			wDiceSkin.setData(nOrder, tOrderedDiceSkin.nID, DiceSkinManager.getDiceSkinInfoByID(tOrderedDiceSkin.nID));
			nOrder = nOrder + 1;
		end
	end
end
function onDiceSelectGroupPrev(w)
	local sCurrentGroup = DiceSkinManager.getDiceSelectGroup(w);
	local tGroups = DiceSkinData.getDiceSkinGroups();
	local nNewIndex = 0;
	for k,sGroup in ipairs(tGroups) do
		if sGroup == sCurrentGroup then
			if k == 1 then
				nNewIndex = #tGroups;
			else
				nNewIndex = k - 1;
			end
			break;
		end
	end
	DiceSkinManager.setDiceSelectGroup(w, tGroups[nNewIndex] or tGroups[#tGroups] or DiceSkinData.DEFAULT_DICESKIN_GROUP);
end
function onDiceSelectGroupNext(w)
	local sCurrentGroup = DiceSkinManager.getDiceSelectGroup(w);
	local tGroups = DiceSkinData.getDiceSkinGroups();
	local nNewIndex = 0;
	for k,sGroup in ipairs(tGroups) do
		if sGroup == sCurrentGroup then
			if k == #tGroups then
				nNewIndex = 1;
			else
				nNewIndex = k + 1;
			end
			break;
		end
	end
	DiceSkinManager.setDiceSelectGroup(w, tGroups[nNewIndex] or DiceSkinData.DEFAULT_DICESKIN_GROUP);
end

function onDiceSelectButtonActivate(nID)
	if DiceSkinManager.isDiceSkinOwnedByID(nID) then
		UserManager.setDiceSkin(nID);
	else
		local sStoreID = DiceSkinData.getDiceSkinIDStoreID(nID);
		if (sStoreID or "") ~= "" then
			UtilityManager.sendToStoreDLC(sStoreID);
		end
	end
end
function onDiceSelectButtonDrag(draginfo, nID)
	draginfo.setType("diceskin");
	draginfo.setIcon(DiceSkinManager.getDiceSkinIconByID(nID));
	draginfo.setDescription(DiceSkinManager.getDiceSkinNameByID(nID));

	local tDiceSkinData = { nID, UserManager.getDiceBodyColor(), UserManager.getDiceTextColor() };
	draginfo.setStringData(table.concat(tDiceSkinData, "|"));

	return true;
end
function onDiceSelectButtonHover(bHover, nID)
	if bHover then
		local tTempColor = UtilityManager.copyDeep(UserManager.getColor());
		tTempColor.diceskin = nID;
		UserManager.setColorsToCurrentID(tTempColor);
	else
		UserManager.setColorsToCurrentID(UserManager.getColor());
	end
end
