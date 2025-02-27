local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("P", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseDamage = module.Configurations.BaseDamage;
	local baseInaccuracy = module.Configurations.StandInaccuracy;
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
	
end

return itemMod;