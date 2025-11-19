--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	self.onEffectsUpdated();
	local node = window.getDatabaseNode();
	DB.addHandler(DB.getPath(node, "effects"), "onChildUpdate", self.onEffectsUpdated);
	DB.addHandler(DB.getPath(node, "effects.*"), "onObserverUpdate", self.onEffectsUpdated);
end
function onClose()
	local node = window.getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "effects"), "onChildUpdate", self.onEffectsUpdated);
	DB.removeHandler(DB.getPath(node, "effects.*"), "onObserverUpdate", self.onEffectsUpdated);
end

function onEffectsUpdated()
	applyFilter();
end

function onFilter(w)
	return EffectManager.onEffectFilter(w);
end

function deleteChild(wChild)
	WindowManager.safeDelete(wChild);
end
