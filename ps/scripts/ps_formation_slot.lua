--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function getSlotPos()
	local tSplit = StringManager.split(getName(), "_");
	return { x = tonumber(tSplit[2]) or 0, y = tonumber(tSplit[3]) or 0 };
end
function isCenterPos()
	return (getName() == "slot_0_0");
end

function setData(sToken, bCanEdit)
	if (sToken or "") ~= "" then
		if bCanEdit then
			registerMenuItem(Interface.getString("counter_menu_clear"), "erase", 4);
			self.destroyReadOnlyWidget();
		else
			resetMenuItems();
			self.createReadOnlyWidget();
		end

		if self.isCenterPos() then
			self.destroyCenterWidget();
		end
	else
		resetMenuItems();
		self.destroyReadOnlyWidget();

		if self.isCenterPos() then
			self.createCenterWidget();
		end
	end

	setAsset(sToken);
end

--
--	DECORATIONS
--

local widgetCenter = nil;
function createCenterWidget()
	if widgetCenter then
		return;
	end

	widgetCenter = addBitmapWidget("drag_targeting");
end
function destroyCenterWidget()
	if not widgetCenter then
		return;
	end

	widgetCenter.destroy();
	widgetCenter = nil;
end

local widgetReadOnly = nil;
function createReadOnlyWidget()
	if widgetReadOnly then
		return;
	end

	widgetReadOnly = addBitmapWidget({
		icon = "record_readonly", position="bottomright", w = 10, h = 10,
		frame = "token_ordinal", frameoffset="3,3,3,3",
	});
end
function destroyReadOnlyWidget()
	if not widgetReadOnly then
		return;
	end

	widgetReadOnly.destroy();
	widgetReadOnly = nil;
end

--
--	MOUSE EVENTS
--

function onMenuSelection(selection)
	if selection == 4 then
		PartyFormationManager.notifyPartyFormationSet(self.getSlotPos());
	end
end
function onDragStart(_, _, _, draginfo)
	return PartyFormationManager.onSlotDragStart(self.getSlotPos(), draginfo);
end
function onDrop(_, _, draginfo)
	return PartyFormationManager.onSlotDrop(self.getSlotPos(), draginfo);
end
