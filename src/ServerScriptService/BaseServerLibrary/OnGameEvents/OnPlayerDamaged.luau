local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== When a player takes damage;
return function(player, damageSource, finalDamage)
    local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
    --==

    local classPlayer = shared.modPlayers.Get(player);

    local dealer = damageSource.Dealer;
    if dealer == nil then
        return;
    end
    
    local dealerPlayer = game.Players:GetPlayerFromCharacter(dealer);
    if dealerPlayer then -- isPlayer
        return;
    end

	local npcModule = modNpc.GetNpcModule(dealer);
    if npcModule == nil then -- unknownDealer;
        return;
    end

	local humanoid = npcModule.Humanoid;
	
    local cultistHoodData = classPlayer.Properties.CultistHood;
	if humanoid and humanoid.Name == "Zombie" and finalDamage > 0 and cultistHoodData then
		local lastTick = cultistHoodData.Tick;

        if lastTick == nil or tick()-cultistHoodData.Tick >= 10 then
            cultistHoodData.Tick = tick();

            local spawnPoint = classPlayer:GetCFrame();
            modNpc.Spawn("Cultist", spawnPoint, function(npc, cultistNpcModule)
                cultistNpcModule.HoodSpawn = tick()+60;

                cultistNpcModule.Properties.TargetableDistance = 4096;
                cultistNpcModule.OnTarget(npcModule.Prefab);
            end);

        end
	end

end;
