local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modEntity = require(game.ReplicatedStorage.Library.Entity);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	if not modBranchConfigs.IsWorld("TheHarbor") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	modOnGameEvents:ConnectEvent("OnTrigger", function(triggerPlayer, interactData, packet)
		
		if interactData.TriggerTag == "m68PickupSalvage" then
			if interactData.Object:GetAttribute("Triggered") then return end;
			interactData.Object:SetAttribute("Triggered", true);
			game.Debris:AddItem(interactData.Object.Parent, 0);
			
			modMission:Progress(triggerPlayer, 68, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.SaveData.SalvagesLeft = mission.SaveData.SalvagesLeft -1;
					modAudio.Play("StorageItemPickup", interactData.Object.Position); 
					
				end;
				if mission.SaveData.SalvagesLeft <= 0 then
					modMission:CompleteMission(triggerPlayer, 68);

				end
			end)
		end
	end)
	
end


local cache = {};
--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheHarbor") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	local salvagePrefab = script:WaitForChild("LockedSalvage");
	script:WaitForChild("Interactable"):Clone().Parent = salvagePrefab;
	
	local salvageSpawns = {};
	for _, obj in pairs(script:WaitForChild("SalvageSpawns"):GetChildren()) do
		table.insert(salvageSpawns, obj:GetPivot());
	end
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 68);
		if mission == nil then return end;

		local profile = shared.modProfile:Get(player);
		
		local availableSpawns = table.clone(salvageSpawns);
		local chosenSpawns = {};
		
		while #chosenSpawns < 3 do
			if #availableSpawns < 1 then break; end;
			table.insert(chosenSpawns, table.remove(availableSpawns, math.random(1, #availableSpawns)));
		end
		
		local salvageSpawned = {}
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
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
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end)
	
	return CutsceneSequence;
end;