local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("P", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseDamage = module.Configurations.BaseDamage;
	local baseInaccuracy = module.Configurations.BaseInaccuracy;
	local baseMultishot = module.Properties.BaseMultishot;
	local maxShots = baseMultishot and baseMultishot.Max or 1;

	if module.Configurations.SlugRounds == nil then
		module.Configurations.SlugRounds = true;

		module.Configurations.Damage = (module.Configurations.Damage * maxShots)/3;
		module.Properties.Multishot = 3;
		module.Configurations.ModInaccuracy = baseInaccuracy*0.2;
	end

	local basePiercing = module.Configurations.BasePiercing;
	local newPiercing = basePiercing + math.floor(value);

	if module.Properties.Piercing == nil or newPiercing > module.Properties.Piercing then
		module.Properties.Piercing = newPiercing;
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local addPiercing = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["P"], info.Upgrades[1].MaxLevel);
	
	--local baseDamage = module.Configurations.BaseDamage;
	--local baseInaccuracy = module.Configurations.BaseInaccuracy;
	--local baseMultishot = module.Properties.BaseMultishot;
	--local maxShots = baseMultishot and baseMultishot.Max or 1;
	
	--if module.Configurations.SlugRounds == nil then
	--	module.Configurations.SlugRounds = true;
		
	--	module.Configurations.Damage = (module.Configurations.Damage * maxShots)/3;
	--	module.Properties.Multishot = 3;
	--	module.Configurations.ModInaccuracy = baseInaccuracy*0.2;
	--end

	--local basePiercing = module.Configurations.BasePiercing;
	--local newPiercing = basePiercing + math.floor(addPiercing);
	
	--if module.Properties.Piercing == nil or newPiercing > module.Properties.Piercing then
	--	module.Properties.Piercing = newPiercing;
	--end
end

return Mod;
