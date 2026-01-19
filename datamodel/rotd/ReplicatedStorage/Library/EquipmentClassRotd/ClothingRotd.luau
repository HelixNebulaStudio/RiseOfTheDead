local Clothing = shared.require(game.ReplicatedStorage.Library.EquipmentClass.Clothing);
local ConfigOperators = Clothing.ConfigOperator;
--==

ConfigOperators["DamageReflection"] = function(configModifier: ConfigModifier, value)
    configModifier.MaxValues.DamageReflection = value;
end;
ConfigOperators["TickRepellent"] = function(configModifier: ConfigModifier, value)
    configModifier.MaxValues.TickRepellent = value;
end;
ConfigOperators["NekrosisHeal"] = function(configModifier: ConfigModifier, value)
    configModifier.SumValues.NekrosisHeal = value;
end;
ConfigOperators["SplashReflection"] = function(configModifier: ConfigModifier, value)
    configModifier.MaxValues.SplashReflection = value;
end;
--==

function Clothing:Update(equipmentClass: EquipmentClass)
    self:UpdateFlinch(equipmentClass);
end

function Clothing:UpdateFlinch(equipmentClass: EquipmentClass)
    local storageItem: StorageItem = equipmentClass.StorageItem;
    local itemValues = storageItem.Values;
	
	local seed = tonumber(itemValues.Seed);
	if seed == nil or seed == 0 then return end;
	
	local randomTemplate = Random.new(seed);
	
    local configurations = equipmentClass.Configurations;

	if configurations:GetBase("HasFlinchProtection") then
		local random = randomTemplate:Clone();
        local baseFlinchProtection = random:NextInteger(1, 99 * math.pow(random:NextNumber(), 3))/100;

        local baseFlinchModifier: ItemModifierInstance = configurations:GetModifier("SeedFlinchProtection");
        if baseFlinchModifier == nil then
            baseFlinchModifier = configurations.newModifier("SeedFlinchProtection", 0);
            configurations:AddModifier(baseFlinchModifier, false);
        end

        baseFlinchModifier.SumValues.FlinchProtection = baseFlinchProtection;
        baseFlinchModifier.Tags.Base = true;
	end
end

return Clothing;