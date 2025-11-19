--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	WindowManager.onColumnControlInit(self);
end

function setLockMode(bReadOnly)
	WindowManager.onColumnControlSetLockMode(self, bReadOnly);
	local sName = getName();
	local cButtonEdit = window[sName .. "_iedit"];
	if cButtonEdit then
		cButtonEdit.setVisible(isVisible() and not bReadOnly);
	end
	local cButtonAdd = window[sName .. "_iadd"];
	if cButtonAdd then
		cButtonAdd.setVisible(isVisible() and not bReadOnly);
	end
end
function getLockMode()
	return WindowManager.onColumnControlGetLockMode(self);
end

function onVisibilityChanged()
	WindowManager.onColumnControlVisibilityChanged(self);
end

function update(bReadOnly, bForceHide)
	local bShow = WindowManager.onColumnControlUpdateLegacy(self, bReadOnly, bForceHide);
	local bEditMode = false;
	local sName = getName();
	local cButtonEdit = window[sName .. "_iedit"];
	if cButtonEdit then
		cButtonEdit.setVisible(isVisible() and not bReadOnly);
		bEditMode = (cButtonEdit.getValue() ~= 0);
	end
	local cButtonAdd = window[sName .. "_iadd"];
	if cButtonAdd then
		cButtonAdd.setVisible(isVisible() and not bReadOnly);
	end
	for _,w in ipairs(getWindows()) do
		if w.update then
			w.update(bReadOnly);
		elseif w.name then
			w.name.setReadOnly(bReadOnly);
		end
		if cButtonEdit and w.idelete then
			w.idelete.setVisible(bEditMode);
		end
	end
	return bShow;
end

function onListChanged()
	self.updateDisplay();
end
function updateDisplay()
	local cButtonEdit = window[getName() .. "_iedit"];
	if cButtonEdit then
		local bEdit = (cButtonEdit.getValue() == 1);
		for _,w in ipairs(getWindows()) do
			if w.idelete then
				w.idelete.setVisible(bEdit);
			end
		end
	end
end
