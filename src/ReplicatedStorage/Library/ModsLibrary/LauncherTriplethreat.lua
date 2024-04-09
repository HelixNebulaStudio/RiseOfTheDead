local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("RT", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseReloadTime = module.Properties.BaseReloadSpeed;
	local reloadtimeReduction = baseReloadTime * value;
	local newReloadSpeed = math.clamp(baseReloadTime-reloadtimeReduction, 0.0333, 100);

	if newReloadSpeed < module.Properties.ReloadSpeed then
		module.Properties.ReloadSpeed = newReloadSpeed;
	end
	module.Configurations.Triplethreat = true;
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["RT"], info.Upgrades[1].MaxLevel);
	--local baseReloadTime = module.Properties.BaseReloadSpeed;

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	muti = muti + addMulti;
	--end
	
	--local reloadtimeReduction = baseReloadTime*muti;
	--local newReloadSpeed = math.clamp(baseReloadTime-reloadtimeReduction, 0.0333, 100);
	
	--if newReloadSpeed < module.Properties.ReloadSpeed then
	--	module.Properties.ReloadSpeed = newReloadSpeed;
	--end
	--module.Configurations.Triplethreat = true;
end

return Mod;
