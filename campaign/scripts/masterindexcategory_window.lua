--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onEditModeChanged();
end

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(self, "button_category_iedit");

	local sCategory = category.getValue();
	if sCategory ~= "" and sCategory ~= "*" then
		category_label.setReadOnly(not bEditMode);
		idelete.setVisible(bEditMode);
	end
end

function delete()
	WindowManager.callOuterWindowFunction(self, "handleCategoryDelete", category.getValue());
end

function handleDrop(draginfo)
	if not Session.IsHost then
		return;
	end
	if draginfo.isType("shortcut") then
		local sCategory = category.getValue();
		if sCategory ~= "*" then
			local _,sRecord = draginfo.getShortcutData();
			DB.setCategory(sRecord, sCategory);
		end
		return true;
	end
end

function handleSelect()
	WindowManager.callOuterWindowFunction(self, "handleCategorySelect", category.getValue());
end

function handleNameChange(sOriginal, sNew)
	WindowManager.callOuterWindowFunction(self, "handleCategoryNameChange", sOriginal, sNew);
end

function getCategory()
	return category.getValue();
end

function setData(sCategoryKey, sCategoryText, bActive)
	category.setValue(sCategoryKey);
	category_label.initialize(sCategoryText);
	if sCategoryKey ~= "*" then
		category_label.setStateFrame("drophover", "fieldfocusplus", 7, 3, 7, 3);
		category_label.setStateFrame("drophilight", "fieldfocus", 7, 3, 7, 3);
	end
	if bActive then
		setFrame("rowshade");
	end
end

function setActiveByKey(sActiveKey)
	if category.getValue() == sActiveKey then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end
