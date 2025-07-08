local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 35;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if modGameModeManager.GameWorld ~= true then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	modOnGameEvents:ConnectEvent("OnGameModeStart", function(player, gameType, gameStage, room)
		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 1 then
				mission.ProgressionPoint = 2;
				
				mission.StartTime = os.time();
				mission.Timer = 300;
			end
		end)
	end);
	
	modOnGameEvents:ConnectEvent("OnGameModeComplete", function(player, gameType, gameStage, room)
		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint < 3 then
				mission.ProgressionPoint = 3;
			end
		end)
	end);
	
	shared.modEventService:OnInvoked("Interactables_BindTrigger", function(event: EventPacket, interactData, ...)
		local triggerPlayer: Player? = event.Player;
		if triggerPlayer == nil then return end;

		if interactData.TriggerTag == "mission35FoodScavenge" then
			for _, player in pairs(game.Players:GetPlayers()) do
				shared.Notify(player, triggerPlayer.Name .." has successfully extracted the food package.", "Reward");
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 3 then
						mission.SaveData.FactionData = {
							Timelapsed = os.time()-mission.StartTime;
						}
						modMission:CompleteMission(player, MISSION_ID);
					end
				end)
			end
			Debugger.Expire(interactData.Object.Parent, 0);
		end
	end)

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		Debugger:Log("mission.SaveData", mission.SaveData);
		if not modBranchConfigs.IsWorld(mission.SaveData.Location) then Debugger:Log("Wrong world"); return end;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 3 then
					local newInteractable = script.Parent.FoodAirdropInteractable:Clone();
					
					local newCrate = game.ServerStorage.Prefabs.Objects.Crates.CratePallet:Clone();
					newCrate.Name = "FoodScavengePackage";
					newInteractable.Name = "Interactable";
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
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;