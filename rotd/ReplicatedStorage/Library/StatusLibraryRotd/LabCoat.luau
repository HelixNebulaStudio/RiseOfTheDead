local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "LabCoat";
    Icon = "rbxassetid://4978200934";
    Name = "LabCoat";
    Description = "Gain 100 damage protection only for toxic gas damage. Recharge delay 10s, Recharge rate 5/s.";
    Buff = true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms100 ~= true then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local wieldComp: WieldComp = characterClass and characterClass.WieldComp;
    
    local modifierId = statusClass.Values.ModifierId;
    local modifier: ItemModifierInstance? = wieldComp:GetOrDefaultItemModifier(modifierId);
    if modifier == nil then return end;

    local curProtection = modifier.Properties.CurProtection;
    local maxProtection = modifier.Properties.MaxProtection;
        
    if curProtection < maxProtection then
        local lastDamageTick = modifier.Properties.LastDamageTick;
        local tl = workspace:GetServerTimeNow()-lastDamageTick;

        if tl > 10 then
            local rate = 5/10; -- ticks every 100ms
            curProtection = math.clamp(curProtection + rate, 0, maxProtection);
            modifier.Properties.CurProtection = curProtection;
        end
    end;

    statusClass.Alpha = math.clamp(curProtection/maxProtection, 0, 1);
    statusClass:Sync();
end

return modStatusClass.new(statusPackage);