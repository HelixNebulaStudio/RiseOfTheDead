local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
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
    local modifierId = statusPackage.Id;

    function statusPackage.OnExpire(statusClass: StatusClassInstance)
        local characterClass: CharacterClass = statusClass.StatusOwner;
        if characterClass == nil then return end;

        characterClass.Configurations:RemoveModifier(modifierId);
    end

    function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
        if tickData.ms100 ~= true then return end;

        local characterClass: CharacterClass = statusClass.StatusOwner;
        if characterClass == nil then return end;

        local configurations = characterClass.Configurations;

        local shouldRemove = false;
        local sync = false;

        local maxAddAp = statusClass.Values.AddAp;
        local addAr = statusClass.Values.AddAr;

        if statusClass.StatusComp:GetOrDefault("WarmongerScales") ~= nil then -- disable if warmonger present;
            maxAddAp = 0;
        end

        statusClass.Values.Ap = (statusClass.Values.Ap or 0);

        if maxAddAp <= 0 then
            shouldRemove = true;

        else
            local equippedItemId = characterClass.WieldComp.ItemId;
            local isPacifist = (equippedItemId 
                                and (modItemsLibrary:HasTag(equippedItemId, "Heal") 
                                or modItemsLibrary:HasTag(equippedItemId, "Food")))

            local armorRate = configurations.ArmorRate;
            if isPacifist then
                statusClass.Values.Ap = math.clamp(statusClass.Values.Ap + armorRate, 0, maxAddAp);
            else
                statusClass.Values.Ap = math.clamp(statusClass.Values.Ap - 0.2, 0, maxAddAp); -- 2 per sec
            end

            if statusClass.Values.Ap <= 0 then
                shouldRemove = true;

            else

                local statusModifier: ConfigModifier = configurations:GetModifier(modifierId);
                if statusModifier == nil then
                    statusModifier = configurations.newModifier(modifierId);
                    statusModifier.MaxValues.MaxArmorOverCharge = statusClass.Values.Ap;
                    statusModifier.SumValues.ArmorRate = addAr/10;
                    statusModifier.Tags.StatusMod = true;
                end
                configurations:AddModifier(statusModifier);

                if not statusClass.Visible then
                    statusClass.Visible = true;
                    sync = true;
                end
            end
        end

        if shouldRemove then
            configurations:RemoveModifier(modifierId);
            if statusClass.Visible then
                statusClass.Visible = false;
                sync = true;
            end
        end

        if sync then
            statusClass:Sync();
        end
    end
end

return modStatusClass.new(statusPackage);