local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);
--==
local statusPackage = {
    Id = "StatusResistance";
    Icon = "rbxassetid://6469142255";
    Name = "Status Resistance";
    Description = "Reduced negative effects duration by $Percent%.";
    Buff = true;
    Cleansable = true;
    ExpiresOnDeath = true;
};

function statusPackage.init()
    if RunService:IsClient() then return end;

    shared.modEventService:OnInvoked("Players_BindStatusApply", function(event: EventPacket, ...) 
        local player: Player? = event.Player;
        if player == nil then return end;

        local statusComp: StatusComp, statusId: string, statusApplyParam: StatusCompApplyParam = ...;

        local resistanceStatusClass = statusComp:GetOrDefault(statusPackage.Id);
        if resistanceStatusClass == nil then return end;
        if statusId == statusPackage.Id then return end;

        local statusLib = modStatusLibrary:Find(statusId);
        if statusLib == nil then return end;

        if statusLib.Buff ~= false 
        or statusApplyParam.Duration == nil 
        or statusApplyParam.Expires == nil 
        or statusLib.Tags == nil then 
            return;
        end;
        if modTables.ContainsList(statusLib.Tags, modStatusLibrary.DebuffTags) == false then 
            return;
        end;

        local resistValue = (1-(resistanceStatusClass.Values.Percent/100));
        local newDuration = statusApplyParam.Duration * resistValue;
        local durDiff = statusApplyParam.Duration - newDuration;

        statusApplyParam.Expires -= durDiff;
    end)
end

return modStatusClass.new(statusPackage);