local Gun = {};
Gun.__index = Gun;

function Gun.new(equipmentClass: EquipmentClass)
    local self = {};

    local configurations = equipmentClass.Configurations;
    local properties = equipmentClass.Properties;

	properties.Ammo = configurations.MagazineSize;
	properties.MaxAmmo = configurations.AmmoCapacity;

    setmetatable(self, Gun);
    return self;
end

function Gun:LoadWieldConfig(t)
    for k,v in pairs(t) do
        self[k] =v;
    end
end

function Gun:Update(equipmentClass: EquipmentClass, storageItem: StorageItem)
    self:UpdatePotential(equipmentClass, storageItem.Values.L);

    -- MARK: TODO CalculateDps()
    -- if class.CalculateDps then class:CalculateDps(); end
    -- if class.CalculateDpm then class:CalculateDpm(); end
    -- if class.CalculateMd then class:CalculateMd(); end
    -- if class.CalculateTad then class:CalculateTad(); end
    -- if class.CalculatePower then class:CalculatePower(); end
end

function Gun:UpdatePotential(equipmentClass: EquipmentClass, weaponLevel: number)
    weaponLevel = weaponLevel or 0;
	
    local configurations = equipmentClass.Configurations;
    local properties = equipmentClass.Properties;

    local baseDamage = configurations:GetBase("Damage");
    local potentialDamage = configurations:GetBase("PotentialDamage");

    local _, potentialModifier: ItemModifierInstance = configurations:GetModifier("Potential");
    if potentialModifier == nil then
        potentialModifier = configurations.newModifier("Potential", 0);
        configurations:AddModifier(potentialModifier, false);
    end

	local basePotential = configurations.BasePotential or (baseDamage/potentialDamage);
	
	local rate = 0.4;
	local maxRatio = potentialDamage/baseDamage;
	local intervals = maxRatio/21;
	
	local total = 0;
	
	for a=1, weaponLevel do
		local index = a -10;
		local levelWeight = intervals + (intervals * math.sign(index) * (math.abs(index)/10)^rate)
		
		total = total + levelWeight;
	end
	
	local masteryVal = baseDamage * math.min((1+total), maxRatio) / potentialDamage;
	
    local potential = math.clamp(masteryVal, basePotential, 1);
    if properties.Potential == potential then return end;

    properties.Potential = math.clamp(masteryVal, basePotential, 1);
    
    local preModDamage = math.clamp(potentialDamage * properties.Potential, baseDamage, math.huge);

    potentialModifier.SetValues.PreModDamage = preModDamage;
    potentialModifier.SetValues.Damage = preModDamage;
    potentialModifier.Tags.Base = true;

    configurations:Calculate();
end

return Gun;