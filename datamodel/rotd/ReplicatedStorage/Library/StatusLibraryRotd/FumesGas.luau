local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id="FumesGas";
    Icon="rbxassetid://17203237389";
    Name="Fumes Gas";
    Description="Taking health damage from Fumes bypassing your gas protection.";
    Buff=false;
    ExpiresOnDeath=true;
};

function statusPackage.init()
    modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
    modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
    modStorageItem = shared.require(game.ReplicatedStorage.Library.StorageItem);
end


function statusPackage.BindApply()
end


function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 ~= true then return end;

    if statusClass.Values.LastRefresh == nil then
        statusClass.Values.LastRefresh = tick();
    end 


    local lapse = tick()-statusClass.Values.LastRefresh;
    if lapse > 0.65 then
        statusClass.Expires = workspace:GetServerTimeNow();
        statusClass:Sync();

        return;
    elseif lapse > 0.5 then
        return;
    end

    if tickData.ms500 ~= true then return end;

    local damage = statusClass.Values.Damage;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    local healthComp: HealthComp = characterClass.HealthComp;
    
    if healthComp then
        local dmgData = DamageData.new{
            Damage=damage;
            DamageType = "IgnoreArmor";
            DamageCate=DamageData.DamageCategory.FumesGas;
        };

        healthComp:TakeDamage(dmgData);
    end


    -- Damage items;
    if characterClass.ClassName ~= "PlayerClass" then return end;
    local playerClass: PlayerClass = (characterClass :: PlayerClass);
    local wieldComp: WieldComp = playerClass.WieldComp;

    local profile = shared.modProfile:Get(playerClass:GetInstance());
    local gameSave = profile:GetActiveSave();
    if gameSave.Clothing == nil then return end;

    local clothingList = gameSave.Clothing:ListByIndexOrder();

    local largestStorageItem, largestGasProtect = nil, 0;

    for a=1, #clothingList do
        local storageItem = clothingList[a];
        local siid = storageItem.ID;

        local equipmentClass: EquipmentClassRotd = wieldComp:GetEquipmentClass(siid);
        if equipmentClass == nil then continue end;
        
        local itemLib = modItemsLibrary:Find(storageItem.ItemId);
        if itemLib == nil then continue end;
        
        local configurations = equipmentClass.Configurations;
        if configurations.GasProtection == nil then continue end;

        local prevHealth = storageItem:GetValues("Health") or 100;
        if prevHealth <= 0 then
            modStorageItem.PopupItemStatus(storageItem);
            continue;
        end;

        if configurations.GasProtection > largestGasProtect then
            largestStorageItem = storageItem;
            largestGasProtect = configurations.GasProtection;
        end
    end

    if largestStorageItem then
        local storageItem = largestStorageItem;
        local prevHealth = storageItem:GetValues("Health") or 100;

        storageItem:TakeDamage(5);

        local newHealth = storageItem:GetValues("Health");
        if prevHealth ~= newHealth then
            if newHealth == 0 then
                modAudio.Play("GasMaskBroken", playerClass.Head);
                gameSave.AppearanceData:Update(gameSave.Clothing);

            elseif math.fmod(newHealth, 20) == 0 then
                modAudio.Play("GasMaskBreaking"..math.random(1,3), playerClass.Head).PlaybackSpeed = math.random(90,110)/100;

            end
        end

        modStorageItem.PopupItemStatus(storageItem);
    end
end

return modStatusClass.new(statusPackage);