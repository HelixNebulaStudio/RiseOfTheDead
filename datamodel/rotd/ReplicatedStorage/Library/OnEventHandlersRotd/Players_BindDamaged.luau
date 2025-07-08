local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== When a player takes damage;
return function(event: EventPacket, damageData: DamageData, finalDamage: number)
    local playerClass: PlayerClass = (damageData.DamageTo :: PlayerClass);
    if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

    local damageBy = damageData.DamageBy;
    if damageBy == nil or damageBy.ClassName ~= "NpcClass" then return; end

    local cultistHoodData = playerClass.Properties.CultistHood;
    if damageBy.HumanoidType ~= "Zombie" or finalDamage <= 0 or cultistHoodData == nil then return end;

    local lastTick = cultistHoodData.Tick;
    if lastTick and tick()-cultistHoodData.Tick < 10 then return end

    cultistHoodData.Tick = tick();

    local spawnPoint = playerClass:GetCFrame();
    shared.modNpcs.spawn("Cultist", spawnPoint, function(npc, cultistNpcModule)
        cultistNpcModule.HoodSpawn = tick()+60;

        cultistNpcModule.Properties.TargetableDistance = 4096;
        cultistNpcModule.OnTarget(damageBy.Character);
    end);
end;
