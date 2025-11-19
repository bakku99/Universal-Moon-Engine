--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();

	self.onObserverUpdated();
	DB.addHandler(getDatabasePath(), "onObserverUpdate", self.onObserverUpdated);
end
function onClose()
	DB.removeHandler(getDatabasePath(), "onObserverUpdate", self.onObserverUpdated);
end

function onObserverUpdated()
	owner.setValue(DB.getOwner(getDatabaseNode()));
end
