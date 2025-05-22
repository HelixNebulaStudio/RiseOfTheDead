local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local MISSION_ID = 68;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if not modBranchConfigs.IsWorld("TheHarbor") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, packet)
		local triggerPlayer: Player? = eventPacket.Player;
		if triggerPlayer == nil then return end;
		
		if interactData.TriggerTag == "m68PickupSalvage" then
			if interactData.Object:GetAttribute("Triggered") then return end;
			interactData.Object:SetAttribute("Triggered", true);
			game.Debris:AddItem(interactData.Object.Parent, 0);
			
			modMission:Progress(triggerPlayer, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.SalvagesLeft = mission.SaveData.SalvagesLeft -1;
					modAudio.Play("StorageItemPickup", interactData.Object.Position); 
					
				end;
				if mission.SaveData.SalvagesLeft <= 0 then
					modMission:CompleteMission(triggerPlayer, MISSION_ID);

				end
			end)
		end
	end);

	cutsceneAssets = script.Parent:WaitForChild("CutsceneAssets");

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheHarbor") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	local salvagePrefab = cutsceneAssets:WaitForChild("LockedSalvage");
	cutsceneAssets:WaitForChild("Interactable"):Clone().Parent = salvagePrefab;
	
	local salvageSpawns = {};
	for _, obj in pairs(cutsceneAssets:WaitForChild("SalvageSpawns"):GetChildren()) do
		table.insert(salvageSpawns, obj:GetPivot());
	end

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local profile = shared.modProfile:Get(player);
		
		local availableSpawns = table.clone(salvageSpawns);
		local chosenSpawns = {};
		
		while #chosenSpawns < 3 do
			if #availableSpawns < 1 then break; end;
			table.insert(chosenSpawns, table.remove(availableSpawns, math.random(1, #availableSpawns)));
		end
		
		local salvageSpawned = {}
		local salvalgesSpawned = false;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					if salvalgesSpawned then return end;
					salvalgesSpawned = true;
					
					for a=1, #chosenSpawns do
						local spawnCframe = chosenSpawns[a];
						
						local newPrefab = salvagePrefab:Clone();
						newPrefab:PivotTo(spawnCframe);
						
						table.insert(salvageSpawned, newPrefab);
						modReplicationManager.ReplicateIn(player, newPrefab, workspace.Interactables);
						
						if profile.Cache.Mission77_OnSunkenSalvagesSpawn then
							profile.Cache.Mission77_OnSunkenSalvagesSpawn(spawnCframe);
						end
					end

				end
				
			elseif mission.Type == 3 then -- OnComplete
				for a=1, #salvageSpawned do
					game.Debris:AddItem(salvageSpawned[a], 0);
				end
				table.clear(salvageSpawned);

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;