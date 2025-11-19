--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _bActive = false;
local _nID;

function setData(nOrder, nID, tInfo)
	order.setValue(nOrder);
	_nID = nID;
	DiceSkinManager.setupDiceSelectButton(button, _nID);

	-- Sorting / Display
	name.setValue(DiceSkinManager.getDiceSkinNameByID(_nID));
	if tInfo and tInfo.bTintable then
		tintable.setValue(1);
	end
	if tInfo and tInfo.owned then
		owned.setValue(1);
	else
		button.setColor("7FFFFFFF");
	end
	id.setValue(nID);
end

function getID()
	return _nID;
end
function isOwned()
	return (owned.getValue() ~= 0);
end
function setActive(bActive)
	if bActive == _bActive then
		return;
	end
	_bActive = bActive;
	if bActive then
		setFrame("calendarhighlight");
	else
		setFrame(nil);
	end
end
