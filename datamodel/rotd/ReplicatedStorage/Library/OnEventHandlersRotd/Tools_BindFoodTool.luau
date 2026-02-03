local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
return function(event: EventPacket, action: string, toolHandler: ToolHandlerInstance, changeRef: anydict)
    local statusComp: StatusComp = toolHandler.CharacterClass.StatusComp;

    if action == "Consume" then
        local effectDuration = changeRef.EffectDuration;

        -- MARK: Skill: Efficient Metabolism;
        local effmetStatus: StatusClassInstance = statusComp:GetOrDefault("effmet");
        if effmetStatus and effectDuration then
            local skillStats = effmetStatus.Values.SkillData.Stats;
            effectDuration = effectDuration * ((skillStats.Percent.Value/100)+1);
        end

        Debugger:Warn(`EffectDuration {effectDuration}`);
        changeRef.EffectDuration = effectDuration;
    end
end;