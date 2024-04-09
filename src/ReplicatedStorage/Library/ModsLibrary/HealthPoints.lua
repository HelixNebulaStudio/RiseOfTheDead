local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	local storageItem = packet.ModStorageItem;

	local layerInfo = modModsLibrary.GetLayer("HP", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local info = modModsLibrary.Get(storageItem.ItemId);
	if module:RegisterTypes(info, storageItem) then return end;
	
	module.ModHealthPoints = (module.BaseHealthPoints or 0) + value;
	
	--local storageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = modModsLibrary.Get(storageItem.ItemId);
	--if module:RegisterTypes(info, storageItem) then return end;
	
	--local values = storageItem.Values;
	--local add = modModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["HP"], info.Upgrades[1].MaxLevel);
	
	--module.ModHealthPoints = (module.BaseHealthPoints or 0) + add;
end

return Mod;