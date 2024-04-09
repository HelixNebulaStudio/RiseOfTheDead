local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("S", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	local newSlots = (module.BaseHotEquipSlots or 0) + value;
	if (module.HotEquipSlots or 0) < newSlots then
		module.HotEquipSlots = newSlots;
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local add = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["S"], info.Upgrades[1].MaxLevel);
	
	--module.HotEquipSlots = (module.BaseHotEquipSlots or 0) + add;
end

return Mod;
