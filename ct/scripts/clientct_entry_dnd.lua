--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	self.onHealthChanged();
end

function onFactionChanged()
	super.onFactionChanged();
	self.updateHealthDisplay();
end
function onHealthChanged()
	local rActor = ActorManager.resolveActor(getDatabaseNode());
	local sColor = ActorHealthManager.getHealthColor(rActor);

	if wounds then
		wounds.setColor(sColor);
	end
	if nonlethal then
		nonlethal.setColor(sColor);
	end
	status.setColor(sColor);
end

function updateHealthDisplay()
	local sOption;
	if friendfoe.getValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	local bShowDetail = (sOption == "detailed");
	local bShowStatus = (sOption == "status");

	status.setVisible(bShowStatus);
	if hp then
		hp.setVisible(bShowDetail);
	end
	if hptemp then
		hptemp.setVisible(bShowDetail);
	end
	if nonlethal then
		nonlethal.setVisible(bShowDetail);
	end
	if wounds then
		wounds.setVisible(bShowDetail);
	end

	local bShowHealthBase = not OptionsManager.isOption("SHPC", "off") or not OptionsManager.isOption("SHNPC", "off");
	healthbase.setVisible(bShowHealthBase);
end
