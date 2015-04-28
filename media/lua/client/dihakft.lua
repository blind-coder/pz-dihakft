require 'ISUI/ISToolTipInv'

DIHAKFT = {};

DIHAKFT.ISToolTipInvRender = ISToolTipInv.render;
function ISToolTipInv:render()
	DIHAKFT.ISToolTipInvRender(self);

	if self.item:getFullType() ~= "Base.Doorknob" then return end;
	if self.item:getKeyId() == nil then return end;
	if ISContextMenu.instance and ISContextMenu.instance.visibleCheck then return end;

	local th = self.height;
	local r = 0;
	local g = 0;

	if getSpecificPlayer(0):getInventory():haveThisKeyId(self.item:getKeyId()) then
		g = 1;
		text = "You have a key for this knob.";
	else
		r = 1;
		text = "You don't have a key for this knob.";
	end

	local textHeight = getTextManager():MeasureStringY(UIFont.Small, text);
	local textWidth = getTextManager():MeasureStringX(UIFont.Small, text);
	self:drawText(text, 3, th+3, r, g, 0, 1, UIFont.Small);

	self:drawRect(0, th, math.max(self.width, 6+textWidth), 6+textHeight,
		self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	self:drawRectBorder(0, th, math.max(self.width, 6+textWidth), 6+textHeight,
		self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
end
