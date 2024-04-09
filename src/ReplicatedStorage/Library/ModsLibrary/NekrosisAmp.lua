local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("A", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	module.NekrosisAmpMulti = value;

	if module.BaseNekrosisHeal == nil then return end

	local new = module.BaseNekrosisHeal + (module.BaseNekrosisHeal * value);
	if new < module.ModNekrosisHeal then return end;

	module.ModNekrosisHeal = new;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["A"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);
	
	--module.NekrosisAmpMulti = muti;
	
	--if module.BaseNekrosisHeal == nil then return end
	
	--local new = module.BaseNekrosisHeal + (module.BaseNekrosisHeal * muti);
	--if new < module.ModNekrosisHeal then return end;
	
	--module.ModNekrosisHeal = new;
end

return Mod;
