local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 35;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modGameModeManager.GameWorld ~= true then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	modOnGameEvents:ConnectEvent("OnGameModeStart", function(player, gameType, gameStage, room)
		modMission:Progress(player, missionId, function(mission)
			if mission.ProgressionPoint == 1 then
				mission.ProgressionPoint = 2;
				
				mission.StartTime = os.time();
				mission.Timer = 300;
			end
		end)
	end);
	
	modOnGameEvents:ConnectEvent("OnGameModeComplete", function(player, gameType, gameStage, room)
		modMission:Progress(player, missionId, function(mission)
			if mission.ProgressionPoint < 3 then
				mission.ProgressionPoint = 3;
			end
		end)
	end);
	
	modOnGameEvents:ConnectEvent("OnTrigger", function(triggerPlayer, interactData, packet)
		if interactData.TriggerTag == "mission35FoodScavenge" then
			for _, player in pairs(game.Players:GetPlayers()) do
				shared.Notify(player, triggerPlayer.Name .." has successfully extracted the food package.", "Reward");
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint == 3 then
						mission.SaveData.FactionData = {
							Timelapsed = os.time()-mission.StartTime;
						}
						modMission:CompleteMission(player, missionId);
					end
				end)
			end
			Debugger.Expire(interactData.Object.Parent, 0);
		end
	end)

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
			
		Debugger:Log("mission.SaveData", mission.SaveData);
		if not modBranchConfigs.IsWorld(mission.SaveData.Location) then Debugger:Log("Wrong world"); return end;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 3 then
					local newInteractable = script.Parent.FoodAirdropInteractable:Clone();
					
					local newCrate = game.ServerStorage.PrefabStorage.Objects.Crates.CratePallet:Clone();
					newCrate.Name = "FoodScavengePackage";
					newInteractable.Parent = newCrate;
					
					newCrate:PivotTo(workspace:FindFirstChild("RewardSpawn", true).CFrame * CFrame.new(0, 2, 0));
					
					if workspace.Interactables:FindFirstChild(newCrate.Name) == nil then
						newCrate.Parent = workspace.Interactables;
					end
					Debugger:Log("Spawn food package ", newCrate:GetPivot().Position);
					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;