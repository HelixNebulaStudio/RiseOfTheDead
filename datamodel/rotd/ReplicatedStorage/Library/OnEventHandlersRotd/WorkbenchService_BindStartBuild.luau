local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);

return function(event: EventPacket, ...)
    local player = event.Player;
    if player == nil then return end;

    local userWorkbench, processPacket, buildDuration = ...;

    local profile = shared.modProfile:Get(player);
    
    local skillData = profile.SkillTree:GetSkill(player, "engdeg");
    if skillData and skillData.Points > 0 then
        local level, skillStats = profile.SkillTree:CalStats(skillData.Library, skillData.Points);
        if level > 0 then
            buildDuration = buildDuration * (100-skillStats.Percent.Value)/100;
            processPacket.BT = modSyncTime.GetTime()+buildDuration;
        end
    end
end