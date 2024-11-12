local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("S", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	local newSlots = (module.BaseHotEquipSlots or 0) + value;
	if (module.HotEquipSlots or 0) < newSlots then
		module.HotEquipSlots = newSlots;
	end
end

return itemMod;