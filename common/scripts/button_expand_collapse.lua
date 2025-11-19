--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

--luacheck: globals collapse expand target togglelevel

-- The target value is a series of consecutive window lists or sub windows
local bToggle = false;
local bVisibility = false;
local nLevel = 1;
local aTargetPath = {};

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	for sWord in string.gmatch(target[1], "([%w_]+)") do
		table.insert(aTargetPath, sWord);
	end
	if expand then
		bVisibility = true;
	elseif collapse then
		bVisibility = false;
	else
		bToggle = true;
	end
	if togglelevel then
		nLevel = tonumber(togglelevel[1]) or 0;
		if nLevel < 1 then
			nLevel = 1;
		end
	end
end

function onButtonPress()
	if not bToggle then
		self.applyTop();
	end
end

function onValueChanged()
	if bToggle then
		self.applyTop();
	end
end

function toggle()
	if not bToggle then
		return;
	end
	if getValue() == 0 then
		setValue(1);
	else
		setValue(0);
	end
end

function applyTop()
	self.applyTo(window[aTargetPath[1]], 1);
end
function applyTo(vTarget, nIndex)
	if nIndex > nLevel then
		if bToggle then
			if getValue() == 0 then
				vTarget.setVisible(true);
			else
				vTarget.setVisible(false);
			end
		else
			vTarget.setVisible(bVisibility);
		end
	end

	nIndex = nIndex + 1;
	if nIndex > #aTargetPath then
		return;
	end

	local sTargetType = type(vTarget);
	if sTargetType == "windowlist" then
		for _,wChild in pairs(vTarget.getWindows()) do
			self.applyTo(wChild[aTargetPath[nIndex]], nIndex);
		end
	elseif sTargetType == "subwindow" then
		if vTarget.subwindow then
			self.applyTo(vTarget.subwindow[aTargetPath[nIndex]], nIndex);
		end
	end
end
