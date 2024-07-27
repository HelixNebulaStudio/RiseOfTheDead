local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 48;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	barricadeFolder = script.Parent:WaitForChild("Barricades");
	for _, obj in pairs(barricadeFolder:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = "Structure";
		end
	end
	
	if modBranchConfigs.IsWorld("TheMall") then
		modOnGameEvents:ConnectEvent("OnDestructibleDestroy", function(destructible, player, storageItem)
			if destructible.MissionIdTag ~= missionId then return; end
			local player = destructible.NetworkOwners and destructible.NetworkOwners[1];
			
			if modMission:IsAvailable(player, missionId) then
				modMission:StartMission(player, missionId);
			end
			modMission:Progress(player, missionId, function(mission)
				if mission.ProgressionPoint < 2 then
					mission.ProgressionPoint = 2;
				end;
			end)
			
		end);
	end

else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheMall") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;

		if modMission:IsComplete(player, missionId) then return end;

		local spawns = {
			CFrame.new(941.376099, 96.6852112, -1091.6167, -1, 0, 0, 0, 1, 0, 0, 0, -1);
			CFrame.new(843.879944, 98.5493927, -659.979187, 1, 0, 0, 0, 1, 0, 0, 0, 1);
			CFrame.new(403.972046, 96.6407852, -887.961853, 0, 0, -1, 0, 1, 0, 1, 0, 0);
		}

		local missionDataSpawnId = (mission.SaveData.Id or 1);
		local chosenSpawn = spawns[missionDataSpawnId];
		local blockageName = "blockage"..missionDataSpawnId;
		
		CutsceneSequence:NextScene("loadCheck");
		
		local newBlockage = barricadeFolder:FindFirstChild(blockageName):Clone();
		local destructible = require(newBlockage:WaitForChild("Destructible"));
		destructible.NetworkOwners = {player};
		newBlockage.Parent = workspace.Environment;
		modReplicationManager.ReplicateOut(player, newBlockage);
		
		local strangerModule = modNpc.GetPlayerNpc(player, "Stranger", function(npcModule)
			return npcModule.MissionId == missionId;
		end);
		
		if strangerModule == nil then
			local npc = modNpc.Spawn("Stranger", chosenSpawn, function(npc, npcModule)
				npcModule.MissionId = missionId;
				npcModule.FollowingOwner = false;
				npcModule.Seed = (mission.SaveData.Seed or 1);
				npcModule.Owner = player;
				npcModule.Immortal = 1;
				strangerModule = npcModule;
			end);
			npc:SetAttribute("Player", player.Name);
			
			modReplicationManager.ReplicateOut(player, npc);
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					
				elseif mission.ProgressionPoint == 2 then
					if strangerModule then
						strangerModule.Immortal = 0;
						modReplicationManager.ReplicateDefault(strangerModule.Prefab, workspace.Entity);
						
						strangerModule.FollowingOwner = true;
						strangerModule.StopAnimation("Panic");
					end
				end
				
			elseif mission.Type == 3 then -- OnComplete
				delay(2, function()
					if strangerModule and strangerModule.Prefab then
						strangerModule.Prefab:Destroy();
						strangerModule = nil;
					end
				end)
				mission.Changed:Disconnect(OnChanged);
			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);

	end)
	
	CutsceneSequence:NewScene("loadCheck", function()
		Debugger:Log("Preload");
	end);

	return CutsceneSequence;
end;