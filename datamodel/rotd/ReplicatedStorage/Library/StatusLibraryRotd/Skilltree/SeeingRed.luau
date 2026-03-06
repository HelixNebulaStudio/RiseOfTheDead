local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "seered";
    Icon = "rbxassetid://105295368698384";
    Name = "Skill: Seeing Red";
    Description = "Dark areas are lit up by enhanced vision.";
    Buff = true;
};

function statusPackage.BindUpdate(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;

    statusClass.Expires = workspace:GetServerTimeNow() + statusClass.Values.SkillDuration;
    statusClass.Duration = statusClass.Values.SkillDuration;
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local duration = 3;
    if statusClass.Values.SkillData and statusClass.Values.SkillData.Stats.Time.Value then
        duration = statusClass.Values.SkillData.Stats.Time.Value;
    end
    statusClass.Values.SkillDuration = duration;

    if RunService:IsServer() then
        statusClass.Expires = workspace:GetServerTimeNow() + statusClass.Values.SkillDuration;
        statusClass.Duration = statusClass.Values.SkillDuration;

        return 
    end;

    game.Lighting:SetAttribute("DarkAmbient", Color3.fromRGB(255, 0, 0));
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsServer() then return end;

    game.Lighting:SetAttribute("DarkAmbient", nil);
end

return modStatusClass.new(statusPackage);