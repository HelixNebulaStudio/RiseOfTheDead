local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
local statusPackage = {
    Id = "PacifistsAmulet";
    Icon = "rbxassetid://16049397225";
    Name = "Pacifist's Amulet";
    Description = "Armor over charges and increased armor rate from pacifism.";
    Buff = true;
    ExpiresOnDeath = true;
};

if RunService:IsServer() then
    function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
        if RunService:IsClient() then return end;
        if tickData.ms100 ~= true then return end;

        local characterClass: CharacterClass = statusClass.StatusOwner;
        if characterClass == nil then return end;

        local configurations = characterClass.Configurations;

        local shouldRemove = false;
        local sync = false;

        local mSiid = statusClass.Values.Siid;

        if statusClass.StatusComp:GetOrDefault("WarmongerScales") ~= nil then -- disable if warmonger present;
            statusClass.IsExpired = true;
            return;
        end

        local modifierInstance: ItemModifierInstance? = characterClass.WieldComp:GetOrDefaultItemModifier(mSiid);
        if modifierInstance == nil or not modifierInstance.Enabled then
            statusClass.IsExpired = true;
            return;
        end

        local maxAddAp = modifierInstance.Values.AddAp;
        local addAr = modifierInstance.Values.AddAr;

        statusClass.Values.MaxArmorOverCharge = (statusClass.Values.MaxArmorOverCharge or 0);

        if maxAddAp <= 0 then
            shouldRemove = true;

        else
            local equippedItemId = characterClass.WieldComp.ItemId;
            local isPacifist = (equippedItemId 
                                and (modItemsLibrary:HasTag(equippedItemId, "Heal") 
                                or modItemsLibrary:HasTag(equippedItemId, "Food")))

            local newArmorRate = (configurations.ArmorRate + addAr)/10;
            if isPacifist then
                if statusClass.Values.OverChargePool == nil then
                    statusClass.Values.OverChargePool = maxAddAp;
                end
                if statusClass.Values.OverChargePool > 0 then
                    local add = newArmorRate;

                    statusClass.Values.OverChargePool -= add;
                    statusClass.Values.MaxArmorOverCharge = math.clamp(statusClass.Values.MaxArmorOverCharge + add, 0, maxAddAp);

                    characterClass.HealthComp:SetArmor(characterClass.HealthComp.CurArmor + newArmorRate);
                end

            else
                statusClass.Values.MaxArmorOverCharge = math.clamp(statusClass.Values.MaxArmorOverCharge - 1, 0, maxAddAp); 

                if statusClass.Values.MaxArmorOverCharge <= 0 and statusClass.Expires == nil then
                    statusClass.Expires = workspace:GetServerTimeNow() + 60;
                    statusClass.Duration = 60;
                    sync = true;
                end
            end
        end

        if shouldRemove then
            statusClass.IsExpired = true;
        end

        if sync then
            statusClass:Sync();
        end
    end
end

return modStatusClass.new(statusPackage);