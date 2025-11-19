--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals acceptdrop counters

local _tSlots = {};
function resetCounters()
	for _,v in ipairs(_tSlots) do
		v.destroy();
	end
	_tSlots = {};
end
function addCounter()
	local widget = addBitmapWidget({
		icon = counters[1].icon[1], position="topleft",
		x = counters[1].offset[1].x[1] + counters[1].spacing[1] * #_tSlots,
		y = counters[1].offset[1].y[1],
	});
	table.insert(_tSlots, widget);
end
function getCounterAt(x, _)
	for i = 1, #_tSlots do
		local slotcenterx = counters[1].offset[1].x[1] + counters[1].spacing[1] * (i-1);
		local size = tonumber(counters[1].hoversize[1]);
		if math.abs(slotcenterx - x) <= size and math.abs(slotcenterx - x) <= size then
			return i;
		end
	end

	return 0;
end

function onHover(bOnControl)
	if not bOnControl then
		ModifierStack.hoverDisplay(0);
	end
end
function onHoverUpdate(x, y)
	ModifierStack.hoverDisplay(self.getCounterAt(x, y));
end
function onClickDown()
	return true;
end
function onClickRelease(_, x, y)
	local n = self.getCounterAt(x, y);
	if n ~= 0 then
		ModifierStack.removeSlot(n);
	end
	return true;
end
function onDrop(_, _, draginfo)
	local sDragType = draginfo.getType();

	-- Special handling for numbers, since they may come from chat window
	if sDragType == "number" then
		-- Strip any names that were added
		local sDragText = draginfo.getDescription();

		-- Then, add to the modifier stack
		ModifierStack.addSlot(sDragText, draginfo.getNumberData());
		return true;

	elseif acceptdrop and acceptdrop[1] and acceptdrop[1].type then
		-- See which other potential drop types we want to accept (ignoring dice)
		for _,v in pairs(acceptdrop[1].type) do
			if v == sDragType then
				draginfo.setSlot(1);
				ModifierStack.addSlot(draginfo.getStringData(), draginfo.getNumberData());
				return true;
			end
		end
	end

	return false;
end
