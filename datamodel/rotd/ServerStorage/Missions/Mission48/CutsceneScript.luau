local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

--== Variables;
local MISSION_ID = 48;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	barricadeFolder = script.Parent:WaitForChild("Barricades");
	for _, obj in pairs(barricadeFolder:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = "Structure";
		end
	end
	
	if modBranchConfigs.IsWorld("TheMall") then
		shared.modEventService:OnInvoked("Destructibles_BindDestroyed", function(event: EventPacket, ...) 
			local destructible: DestructibleInstance = ...;
			if destructible.Properties.MissionIdTag ~= MISSION_ID then return; end
			if destructible.NetworkOwners == nil then return end;

			for a=1, #destructible.NetworkOwners do
				local player = destructible.NetworkOwners[a];

				if modMission:IsAvailable(player, MISSION_ID) then
					modMission:StartMission(player, MISSION_ID);
				end
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 2 then
						mission.ProgressionPoint = 2;
					end;
				end)
			end
		end)
	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheMall") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;

		if modMission:IsComplete(player, MISSION_ID) then return end;

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

		local destructibleConfig = newBlockage:WaitForChild("Destructible");
		local destructibleInstance: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
		destructibleInstance.NetworkOwners = {player};
		destructibleInstance.Properties.MissionIdTag = MISSION_ID;

		newBlockage.Parent = workspace.Environment;
		modReplicationManager.ReplicateOut(player, newBlockage);
		
		local strangerNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Stranger", function(npcClass: NpcClass)
			return npcClass.Properties.MissionId == MISSION_ID;
		end);
		
		if strangerNpcClass == nil then
			strangerNpcClass = modNpcs.spawn2{
				Name = "Stranger";
				CFrame = chosenSpawn;
				Player = player;
				BindSetup = function(npcClass: NpcClass)
					npcClass.Properties.MissionId = MISSION_ID;
					npcClass.Properties.Seed = (mission.SaveData.Seed or 1);
					npcClass.Properties.Immortal = 1;
				end;
			};
			strangerNpcClass.Character:SetAttribute("Player", player.Name);
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					
				elseif mission.ProgressionPoint == 2 then
					if strangerNpcClass then
						strangerNpcClass.Properties.Immortal = 0;
						modReplicationManager.ReplicateDefault(strangerNpcClass.Character, workspace.Entity);

						strangerNpcClass:GetComponent("FollowPlayer")(nil, function() 
							return mission.ProgressionPoint == 2;
						end);
						strangerNpcClass.StopAnimation("Panic");
					end
				end
				
			elseif mission.Type == 3 then -- OnComplete
				delay(2, function()
					if strangerNpcClass and strangerNpcClass.Character then
						strangerNpcClass.Character:Destroy();
					end
				end)
				mission.OnChanged:Disconnect(OnChanged);
			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);

	end)
	
	CutsceneSequence:NewScene("loadCheck", function()
		Debugger:Log("Preload");
	end);

	return CutsceneSequence;
end;