local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "PointGuardBulwark";
    Icon = shared.Const.PlaceholderIcon;
    Name = "Point-Guard Bulwark";
    Description = "Temporarily gaining additional armor points while in focus.";
    Buff = true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 == false then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local isFocused = characterClass.Properties.IsFocused;
    local modifierId = statusClass.Values.ModifierId;

    local modifier: ItemModifierInstance? = characterClass.WieldComp:GetOrDefaultItemModifier(modifierId);
    if modifier == nil or modifier.Enabled == false then
        statusClass.IsExpired = true;
        return;
    end

    local value = characterClass.Configurations.PGBArmor or 0;
    
    if statusClass.Values.Amount == nil then
        statusClass.Values.Amount = 0;
    end

    if isFocused == false then
        statusClass.Values.StartChargeTick = nil;
        statusClass.Values.Amount = math.clamp(statusClass.Values.Amount -2, 0, value);
        statusClass.Values.MaxArmorOverCharge = statusClass.Values.Amount;

        if statusClass.Values.Amount <= 0 then
            statusClass.IsExpired = true;
        end
        return;
    end

    local tLapsed = tick() - (statusClass.Values.StartChargeTick or tick());
    if statusClass.Values.StartChargeTick == nil then
        statusClass.Values.StartChargeTick = tick();
    end

    if tLapsed <= 1 then
        statusClass.Alpha = tLapsed;
        statusClass:Sync();
        return;

    else
        if statusClass.Alpha ~= 1 then
            statusClass.Alpha = 1;
            statusClass:Sync();
        end
    end

    statusClass.Values.Amount = math.clamp(statusClass.Values.Amount + 1, 0, value);
    statusClass.Values.MaxArmorOverCharge = statusClass.Values.Amount;
end


return modStatusClass.new(statusPackage);