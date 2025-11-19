--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local _sDie;

function setData(sDie)
	_sDie = sDie;
	button.setIcons(DiceManager.getDiceIcon(_sDie));
	button.setTooltipText(_sDie);
	self.updateDisplay();
end

function updateDisplay()
	if DiceManager.getDesktopDiceState(_sDie) then
		button.setColor("FFFFFFFF");
	else
		button.setColor("7FFFFFFF");
	end
end

function onButtonActivate()
	DiceManager.setDesktopDiceState(_sDie, not DiceManager.getDesktopDiceState(_sDie));
	self.updateDisplay();
end
