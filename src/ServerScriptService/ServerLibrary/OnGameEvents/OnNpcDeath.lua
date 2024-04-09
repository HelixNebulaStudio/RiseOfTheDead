local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);


local random = Random.new();

--== When a npc dies;
return function(players, npcModule)
	for _, player in pairs(players) do
		local profile = modProfile:Get(player);
		local activeSave = profile:GetActiveSave();
		local inventory = activeSave.Inventory;
		
		if npcModule.Name == "Cultist" and modMission:IsComplete(player, 40) then
			local mission = modMission:GetMission(player, 41);
			if mission.Type == 2 then
				modMission:StartMission(player, 41);
				
			elseif mission.Type == 1 and mission.ProgressionPoint <= 2 then
				local function spawnCultistNote()
					local new = modItemDrops.Spawn(
						{ItemId="cultistnote1"; OnceOnly=true;}, 
						CFrame.new(npcModule.DeathPosition), 
						player);
					modReplicationManager.ReplicateIn(player, new, workspace.Interactables);
				end
				
				modMission:Progress(player, 41, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.SaveData.Kills = mission.SaveData.Kills -1;
						if mission.SaveData.Kills <= 0 then
							mission.ProgressionPoint = 2;
							spawnCultistNote();	
						end
					elseif mission.ProgressionPoint == 2 then
						spawnCultistNote();	
					end;
				end)
				
			elseif mission.Type == 1 and (mission.ProgressionPoint == 4 or mission.ProgressionPoint == 5) then
				local function spawnCultistHood()
					local new = modItemDrops.Spawn(
						{ItemId="cultisthood"; OnceOnly=true;}, 
						CFrame.new(npcModule.DeathPosition), 
						player);
					modReplicationManager.ReplicateIn(player, new, workspace.Interactables);
				end
				
				modMission:Progress(player, 41, function(mission)
					if mission.ProgressionPoint == 4 then
						mission.ProgressionPoint = 5;
					end;
				end)
				spawnCultistHood();	
				
			end
		end

	end
end;
