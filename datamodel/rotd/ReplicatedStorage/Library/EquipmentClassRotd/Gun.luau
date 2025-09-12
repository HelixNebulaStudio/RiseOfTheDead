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

    local potentialModifier: ItemModifierInstance = configurations:GetModifier("Potential");
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

function Gun:RefillAmmo(equipmentClass: EquipmentClass, storageItem: StorageItem)
    local configurations = equipmentClass.Configurations;
    local properties = equipmentClass.Properties;

    properties.Ammo = configurations.MagazineSize;
    properties.MaxAmmo = configurations.AmmoCapacity;

    if storageItem then
        storageItem:SetValues("A", nil);
        storageItem:SetValues("MA", nil);

        storageItem:Sync({"A", "MA"});
    end
    -- local totalMags = (weaponModule.Configurations.MaxAmmoLimit + weaponModule.Configurations.AmmoLimit)/weaponModule.Configurations.AmmoLimit;
    -- if totalMags == mags then
    --     storageItem:SetValues("A", weaponModule.Configurations.AmmoLimit);
    --     storageItem:SetValues("MA", weaponModule.Configurations.MaxAmmoLimit);
    -- else
    --     local currentAmmo = storageItem.Values["A"] or weaponModule.Configurations.AmmoLimit;
    --     local currentMaxAmmo = storageItem.Values["MA"] or weaponModule.Configurations.MaxAmmoLimit;
    --     local remainingBullets = mags*weaponModule.Configurations.AmmoLimit;

    --     if weaponModule.Configurations.AmmoLimit > currentAmmo then
    --         remainingBullets = remainingBullets - (weaponModule.Configurations.AmmoLimit - currentAmmo);
    --         storageItem:SetValues("A", weaponModule.Configurations.AmmoLimit);
    --     end
    --     if weaponModule.Configurations.MaxAmmoLimit > currentMaxAmmo then
    --         if currentMaxAmmo+remainingBullets >= weaponModule.Configurations.MaxAmmoLimit then
    --             storageItem:SetValues("MA", weaponModule.Configurations.MaxAmmoLimit);
    --         else
    --             storageItem:SetValues("MA", currentMaxAmmo+remainingBullets);
    --         end
    --     end
    -- end
    
end

return Gun;