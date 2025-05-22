local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local RunService = game:GetService("RunService");
--==
local statusPackage = {
    Id="fiaitr";
    Icon="rbxassetid://4493354290";
    Name="Skill: First Aid Training";
    Description="Medkits use speed increased by $Percent%.";
    Buff=true;
    ExpiresOnDeath=true;
};

if RunService:IsServer() then
    local statusId = statusPackage.Id;

    function statusPackage.onRequire()
        shared.modEventService:OnInvoked("Players_OnWieldEvent", function(event: EventPacket, ...)
            local action: string, toolHandler: ToolHandlerInstance = ...;

            local playerClass: PlayerClass = toolHandler.CharacterClass :: PlayerClass;
            local statusComp: StatusComp = playerClass.StatusComp;

            local player: Player = (playerClass :: PlayerClass):GetInstance();
            local profile = shared.modProfile:Get(player);

            if action == "Equip" then
                if toolHandler.ToolPackage.HandlerType == "HealTool" then
                    -- Skill: First Aid Training;
                    local fiaitrSkillData = profile.SkillTree:GetSkill(player, statusId);

                    if fiaitrSkillData then
                        local _level, stats = profile.SkillTree:CalStats(fiaitrSkillData.Library, fiaitrSkillData.Points);
                        local fiaitrValue = stats.Percent.Value;
                        
                        statusComp:Apply(statusId, {
                            Values = {
                                Percent = fiaitrValue;
                            };
                        });
                    end
                end

            elseif action == "Unequip" then
                local fiaitrStatusClass = statusComp:GetOrDefault(statusId);
                if fiaitrStatusClass then
                    statusComp:Apply(statusId);
                end

            end
        end)
    end
end

return modStatusClass.new(statusPackage);