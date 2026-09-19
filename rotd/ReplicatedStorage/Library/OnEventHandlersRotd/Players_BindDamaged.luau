local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== When a player takes damage;
return function(event: EventPacket, damageData: DamageData, finalDamage: number)
    local playerClass: PlayerClass = (damageData.DamageTo :: PlayerClass);
    if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

    local damageBy = damageData.DamageBy;
    if damageBy == nil or damageBy.ClassName ~= "NpcClass" then return; end
end;
