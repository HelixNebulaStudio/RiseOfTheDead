local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "RegenerativeShield";
    Icon = shared.Const.PlaceholderIcon;
    Name = "RegenerativeShield";
    Description = "";
    Buff = true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 ~= true then return end;

    local healthComp: HealthComp = statusClass.StatusOwner.HealthComp;
    if healthComp.CurArmor >= healthComp.MaxArmor then return end;

    local curTime = workspace:GetServerTimeNow();
    if curTime-healthComp.LastArmorDamageTaken < 5 then return end;
    if curTime-healthComp.LastDamageTaken < 5 then return end;

    local rate = statusClass.Values.Rate or 1; -- armor per sec;
    local newArmor = healthComp.CurArmor + rate;

    healthComp:SetArmor(newArmor);
end

return modStatusClass.new(statusPackage);