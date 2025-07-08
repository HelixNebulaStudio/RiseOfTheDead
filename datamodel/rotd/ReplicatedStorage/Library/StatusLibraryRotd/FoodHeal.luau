local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "FoodHeal";
    Icon = "rbxassetid://4466529123";
    Name = "Healing From Food";
    Description = "+$HealRate Health regen per second.";
    DescProcess = {
        ["HealRate"]=function(v) 
            return math.round(v*100)/10;
        end
    };
    Buff = true;
    Cleansable = true;
    ExpiresOnDeath = true;
};

if RunService:IsServer() then
    function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
        local healthComp: HealthComp = statusClass.StatusOwner.HealthComp;
        if statusClass.Values.LastDamageTaken == healthComp.LastDamageTaken then return end; 
        
        statusClass.IsExpired = true;
        statusClass:Sync();
    end
end

return modStatusClass.new(statusPackage);