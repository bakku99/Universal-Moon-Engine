--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local DICE_TRAY_SCALE_MIN = 80;
local DICE_TRAY_SCALE_MAX = 120;
local DICE_TRAY_SCALE_INC = 10;
local DICE_ROLL_SCALE_MIN = 80;
local DICE_ROLL_SCALE_MAX = 240;
local DICE_ROLL_SCALE_INC = 20;

function onInit()
	DiceManager.populateDiceSelectWindow(self);
	DiceSkinManager.populateDiceSelectWindow(self);
	self.updateDiceDesktopDisplay();
	self.updateDiceSkinDisplay();

	UserManager.registerColorCallback(self.updateDiceSkinDisplay);
end
function onClose()
	UserManager.unregisterColorCallback(self.updateDiceSkinDisplay);
end

--
--	UI - SIZE CHANGE
--

function updateDiceDesktopDisplay()
	local nTrayScale = Interface.getDiceTrayScale();
	self.helperUpdateButton(sub_desktop.subwindow.button_desktop_tray_scaledown, (nTrayScale > DICE_TRAY_SCALE_MIN));
	self.helperUpdateButton(sub_desktop.subwindow.button_desktop_tray_scaleup, (nTrayScale < DICE_TRAY_SCALE_MAX));
	sub_desktop.subwindow.label_desktop_tray_scale_value.setValue(nTrayScale .. "%");
	local nRollScale = Interface.getDiceRollScale();
	self.helperUpdateButton(sub_desktop.subwindow.button_desktop_roll_scaledown, (nRollScale > DICE_ROLL_SCALE_MIN));
	self.helperUpdateButton(sub_desktop.subwindow.button_desktop_roll_scaleup, (nRollScale < DICE_ROLL_SCALE_MAX));
	sub_desktop.subwindow.label_desktop_roll_scale_value.setValue(nRollScale .. "%");
end
function helperUpdateButton(c, bEnable)
	c.setEnabled(bEnable);
end

function roundScale(nScale, nIncr)
	return (math.floor(nScale / nIncr) * nIncr);
end
function onDiceTrayScaleDown()
	local nScale = Interface.getDiceTrayScale();
	if nScale > DICE_TRAY_SCALE_MIN then
		local nRound = self.roundScale(nScale, DICE_TRAY_SCALE_INC); 
		Interface.setDiceTrayScale(math.max(nRound - DICE_TRAY_SCALE_INC, DICE_TRAY_SCALE_MIN));
	end
	self.updateDiceDesktopDisplay();
end
function onDiceTrayScaleUp()
	local nScale = Interface.getDiceTrayScale();
	if nScale < DICE_TRAY_SCALE_MAX then
		local nRound = self.roundScale(nScale, DICE_TRAY_SCALE_INC); 
		Interface.setDiceTrayScale(math.min(nRound + DICE_TRAY_SCALE_INC, DICE_TRAY_SCALE_MAX));
	end
	self.updateDiceDesktopDisplay();
end
function onDiceRollScaleDown()
	local nScale = Interface.getDiceRollScale();
	if nScale > DICE_ROLL_SCALE_MIN then
		local nRound = self.roundScale(nScale, DICE_ROLL_SCALE_INC); 
		Interface.setDiceRollScale(math.max(nRound - DICE_ROLL_SCALE_INC, DICE_ROLL_SCALE_MIN));
	end
	self.updateDiceDesktopDisplay();
end
function onDiceRollScaleUp()
	local nScale = Interface.getDiceRollScale();
	if nScale < DICE_ROLL_SCALE_MAX then
		local nRound = self.roundScale(nScale, DICE_ROLL_SCALE_INC); 
		Interface.setDiceRollScale(math.min(nRound + DICE_ROLL_SCALE_INC, DICE_ROLL_SCALE_MAX));
	end
	self.updateDiceDesktopDisplay();
end

--
--	UI - COLOR SELECTORS
--

function updateDiceSkinDisplay()
	local tUserColor = UserManager.getColor();

	local cActive = sub_active.subwindow.button;
	DiceSkinManager.setupDiceSelectButton(cActive, tUserColor.diceskin);
	local sLabel = DiceSkinManager.getDiceSkinNameByID(tUserColor.diceskin);
	cActive.setTooltipText(sLabel);
	sub_active.subwindow.label.setValue(sLabel);

	sub_color.subwindow.color_body.setValue(tUserColor.dicebodycolor);
	sub_color.subwindow.color_text.setValue(tUserColor.dicetextcolor);

	local bTintable = DiceSkinManager.isDiceSkinTintable(tUserColor);
	sub_color.subwindow.label_color_body.setVisible(bTintable);
	sub_color.subwindow.label_color_text.setVisible(bTintable);
	sub_color.subwindow.color_body.setVisible(bTintable);
	sub_color.subwindow.color_text.setVisible(bTintable);
	sub_color.subwindow.button_random.setVisible(bTintable);
	sub_color.subwindow.label_empty.setVisible(not bTintable);

	local cList = sub_selection.subwindow.list;
	for _,wDiceSkin in ipairs(cList.getWindows()) do
		local bActive = (wDiceSkin.getID() == tUserColor.diceskin);
		wDiceSkin.setActive(bActive);
	end
end

function onDiceBodyColorChanged(sColor)
	UserManager.setDiceBodyColor(sColor);
end
function onDiceTextColorChanged(sColor)
	UserManager.setDiceTextColor(sColor);
end
