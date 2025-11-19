--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	if Session.IsHost and (getName() == "nonid_name") then
		setFont("reference-bi");
	end
end

function onLoseFocus()
	if super and super.onLoseFocus then
		super.onLoseFocus();
	end
	window.windowlist.updateContainers();
end
