require 'ISUI/ISToolTipInv'

DIHAKFT = {};

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

DIHAKFT.ISToolTipInvRender = ISToolTipInv.render;
function ISToolTipInv:render()

	if self.item:getFullType() == "Base.Doorknob" then
		local text = nil;
		if self.item:getKeyId() ~= nil then
			if getSpecificPlayer(0):getInventory():haveThisKeyId(self.item:getKeyId()) then
				text = "You have a key for this knob.";
			else
				text = "You don't have a key for this knob.";
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
