local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "PointGuardBulwark";
    Icon = "rbxassetid://120030019844899";
    Name = "Point-Guard Bulwark";
    Description = "Temporarily gaining additional armor points while in focus.";
    Buff = true;
};

local CHARGE_TIME = 2;
local DECHARGE_TIME = 5;

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 == false then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
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

    local charge = statusClass.Values.Charge or 0;
    if isFocused then
        statusClass.Values.LastFocusTick = tick();
        charge += 1/CHARGE_TIME/10;
    else
        charge -= 1/DECHARGE_TIME/10;
    end
    charge = math.clamp(charge, 0, 1);
    statusClass.Values.Charge = charge;

    if charge >= 1 then
        statusClass.Values.Amount = math.clamp(statusClass.Values.Amount +2, 0, value);
    elseif charge <= 0 then
        statusClass.Values.Amount = math.clamp(statusClass.Values.Amount -2, 0, value);
    end

    statusClass.Values.MaxArmorOverCharge = statusClass.Values.Amount;

    if statusClass.Alpha ~= charge then
        statusClass.Alpha = charge;
        statusClass:Sync();
    end
end


return modStatusClass.new(statusPackage);