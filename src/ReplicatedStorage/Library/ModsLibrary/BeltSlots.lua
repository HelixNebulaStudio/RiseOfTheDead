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
end

return Mod;