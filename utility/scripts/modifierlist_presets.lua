--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	local bHasModifiers = false;
	local tModifiers = ModifierManager.getModWindowPresets();
	for _,tModCategory in ipairs(tModifiers) do
		if (#(tModCategory.tPresets) > 0) then
			local cHeader = createControl("header_modifier_preset", "header_" .. tModCategory.sCategory);
			cHeader.setValue(Interface.getString("modifier_category_" .. tModCategory.sCategory));

			local cList = createControl("list_modifier_preset", "list_" .. tModCategory.sCategory);
			for _,sPreset in ipairs(tModCategory.tPresets) do
				if sPreset ~= "" then
					local wPreset = cList.createWindow();
					wPreset.setData(sPreset);
				else
					cList.createWindowWithClass("modifier_preset_separator");
				end
			end

			bHasModifiers = true;
		end
	end
	if not bHasModifiers then
		local cHeader = createControl("header_modifier_preset", "header_presets");
		cHeader.setValue(Interface.getString("modifierwindow_label_presets"));
	end
end
