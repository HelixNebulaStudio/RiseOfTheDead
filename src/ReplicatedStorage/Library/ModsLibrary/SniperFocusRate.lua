local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("SF", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseFocusTime = module.Configurations.BaseFocusDuration or 1;
	local focusTimeReduction = baseFocusTime * value;
	local newFocusTime = baseFocusTime-focusTimeReduction;
	
	if newFocusTime < module.Configurations.FocusDuration then
		module.Configurations.FocusDuration = newFocusTime;
	end
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["SF"], info.Upgrades[1].MaxLevel);
	--local baseFocusTime = module.Configurations.BaseFocusDuration or 1;

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	muti = muti + addMulti;
	--end
	
	--local focusTimeReduction = baseFocusTime*muti;
	--local newFocusTime = baseFocusTime-focusTimeReduction;
	--if newFocusTime < module.Configurations.FocusDuration then
	--	module.Configurations.FocusDuration = newFocusTime;
	--end
end

return Mod;