local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);


--== When something happens;
return function(player, interactData)
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local inventory = activeSave and activeSave.Inventory;
	
	if interactData.Type == modInteractables.Types.Pickup then 
		local itemId = interactData.ItemId;
		
		if itemId == "sewerskey1" then
			if modMission:Progress(player, 22) then
				modMission:Progress(player, 22, function(mission)
					if mission.ProgressionPoint == 1 then
						mission.ProgressionPoint = 2;
					end;
				end)
			end
			
		elseif itemId == "cultistnote1" then
			modMission:Progress(player, 41, function(mission)
				if mission.ProgressionPoint < 3 then
					mission.ProgressionPoint = 3;
				end;
			end)
			
		elseif itemId == "cultisthood" then
			modMission:CompleteMission(player, 41);
			
		elseif itemId == "tacticalbowbp" then
			modMission:CompleteMission(player, 42);
			modEvents:NewEvent(player, {Id="mission42Bp2"});
			
		end
		
	elseif interactData.Type == modInteractables.Types.Collectible then
		local id = interactData.Id;
		
		if id == "mlc" then
			modMission:Progress(player, 45, function(mission)
				if mission.ProgressionPoint <= 4 then
					mission.ProgressionPoint = 4;
				end;
			end)

		elseif id == "vrm" then
			modMission:Progress(player, 49, function(mission)
				if mission.ProgressionPoint <= 4 then
					mission.ProgressionPoint = 5;
				end;
			end)
			
		end
	end
end;
