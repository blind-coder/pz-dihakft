require 'ISUI/ISToolTipInv'

local function BitAND(a,b)--Bitwise and
	local p,c=1,0
	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end
	return c
end

DIHAKFT = {};
DIHAKFT.aan = function(text)
	if string.sub(text, 1, 1) == "a" then return "an"; end
	if string.sub(text, 1, 1) == "e" then return "an"; end
	if string.sub(text, 1, 1) == "i" then return "an"; end
	if string.sub(text, 1, 1) == "o" then return "an"; end
	if string.sub(text, 1, 1) == "u" then return "an"; end
	return "a";
end

DIHAKFT.low = {"long", "short", "wide", "broad", "lean", "worn", "ornate", "cheap", "black", "red", "white", "old", "modern", "classic", "slim", "narrow"};
DIHAKFT.high = {"one notch and one tooth", "one notch and _2_ teeth", "_1_ notches and one tooth", "_1_ notches and _2_ teeth", "_1_ notches and _2_ teeth"}


DIHAKFT.dump = function(o, lvl) -- {{{ Small function to dump an object.
  if lvl == nil then lvl = 5 end
  if lvl < 0 then return "SO ("..tostring(o)..")" end

  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if k == "prev" or k == "next" then
        s = s .. '['..k..'] = '..tostring(v);
      else
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. DIHAKFT.dump(v, lvl - 1) .. ',\n'
      end
    end
    return s .. '}\n'
  else
    return tostring(o)
  end
end
-- }}}
DIHAKFT.pline = function (text) -- {{{ Print text to logfile
  print(tostring(text));
end
-- }}}

DIHAKFT.ID2Text = function(id)
	if id == -1 then
		return "simple key"
	end

	local highbits = BitAND(id, 65280);
	local lowbits = BitAND(id, 255);
	local text = DIHAKFT.low[lowbits % 16 + 1] .. " key with " .. DIHAKFT.high[highbits % 5 + 1];
	text = string.gsub(text, "_1_", tostring(highbits % 4 + 2));
	text = string.gsub(text, "_2_", tostring(highbits % 4 + 2));

	return text;
end

DIHAKFT.ISToolTipInvRender = ISToolTipInv.render;
function ISToolTipInv:render()

	if instanceof(self.item, "Key") then
		local text = nil;
		if self.item:getKeyId() ~= nil then
			text = DIHAKFT.ID2Text(self.item:getKeyId());
			text = "This is " .. DIHAKFT.aan(text) .. " " .. text;
		end
		if text ~= nil then
			self.item:setTooltip(text);
		end
	end
	if self.item:getFullType() == "Base.Doorknob" then
		local text = nil;
		if self.item:getKeyId() ~= nil then
			text = DIHAKFT.ID2Text(self.item:getKeyId());
			if getSpecificPlayer(0):getInventory():haveThisKeyId(self.item:getKeyId()) then
				text = "You have a key for this knob. It's " .. DIHAKFT.aan(text) .. " " .. text;
			else
				text = "You don't have a key for this knob. It needs " .. DIHAKFT.aan(text) .. " " .. text;
			end
		end
		if text ~= nil then
			self.item:setTooltip(text);
		end
	end

	DIHAKFT.ISToolTipInvRender(self);
end

function DIHAKFT.findKeysWithId(_inventory, _keyId)
	local retVal = {};
	local items = _inventory:getItems();
	for i=0,items:size()-1 do
		local item = items:get(i);
		if instanceof(item, "Key") then
			if item:getKeyId() == _keyId then
				table.insert(retVal, item);
			end
		elseif item:getType() == "KeyRing" then
			local r = DIHAKFT.findKeysWithId(item:getInventory(), _keyId);
			for _,it in pairs(r) do
				table.insert(retVal, it);
			end
		end
	end
	return retVal;
end

function DIHAKFT.dropAKeyForThisDoor(_worldObjects, _door, _player)
	local inventory = _player:getInventory();
	local keys = DIHAKFT.findKeysWithId(inventory, _door:getKeyId());
	local key = table.remove(keys, 1);
	if key:getContainer() ~= inventory then
		ISTimedActionQueue.add(ISInventoryTransferAction:new(_player, key, key:getContainer(), inventory, 100));
	end
	ISTimedActionQueue.add(ISDropItemAction:new(_player, key, 0));
end

function DIHAKFT.createWorldMenu(_player, _context, _worldObjects)
	local door = nil;
	local modData = nil;

	-- Search through the table of clicked items.
	for _, object in ipairs(_worldObjects) do
		if instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object:isDoor()) then
			door = object;
			break;
		end
	end

	if not door then return end;

	local player = getSpecificPlayer(_player);
	local inventory = player:getInventory();
	local context = _context;

	if inventory:haveThisKeyId(door:getKeyId()) then
		local keys = DIHAKFT.findKeysWithId(inventory, door:getKeyId());

		local count = 0;
		for _,i in pairs(keys) do
			count = count + 1;
		end
		context:addOption("Drop a key for this door (have: "..count..")", _worldObjects, DIHAKFT.dropAKeyForThisDoor, door, player);
	end
end

Events.OnFillWorldObjectContextMenu.Add(DIHAKFT.createWorldMenu);
