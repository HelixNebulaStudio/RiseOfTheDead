local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
	modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
	modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
	modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	
	if modBranchConfigs.IsWorld("TheWarehouse") then
		local caveTpTouch = modTouchHandler.new("CaveTP", 1);
		
		function caveTpTouch:OnPlayerTouch(player, basePart, part)
			modMission:Progress(player, 40, function(mission)
				if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
				modGameModeManager:Assign(player, "Raid", "Tombs");
				
				local exitCf = CFrame.new(442.671, 69.39, 220.038);
				shared.modAntiCheatService:Teleport(player, exitCf);
				
				local profile = modProfile:Get(player);
				profile.BossDoorCFrame = exitCf;
			end)
		end
		caveTpTouch:AddObject(workspace.Environment:WaitForChild("SecPark"):WaitForChild("vtCaveEntrance"));
		
		local touchHandler = modTouchHandler.new("Lava", 0.5);
		function touchHandler:OnPlayerTouch(player, basePart, part)
			local targetModel = part.Parent;
			local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
			
			if player then
				humanoid:TakeDamage(5, self.Owner, self.StorageItem, part);
				remoteCameraShakeAndZoom:FireClient(player, 5, 0, 0.3, 2, false);
				if player then modStatusEffects.Burn(player, 94, 1); end;
			end
		end
		
		for _, part in pairs(workspace.Environment:WaitForChild("SecPark"):WaitForChild("Lava"):GetChildren()) do
			touchHandler:AddObject(part);
		end
	end
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule"));
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheWarehouse") then
	
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 40);
			if mission == nil then return end;
			
			if modMission:IsComplete(player, 42) then
				local tombsInteractable = script:WaitForChild("Raid_Tombs"):Clone();
				modReplicationManager.ReplicateIn(player, tombsInteractable, workspace.Interactables);
				return;
			end
			
			local victorModule = modNpc.GetPlayerNpc(player, "Victor");
			if victorModule == nil then
				local npc = modNpc.Spawn("Victor", nil, function(npc, npcModule)
					npcModule.Owner = player;
					victorModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			victorModule.PlayAnimation("Sit");
			
			local statuePrefab = script:WaitForChild("statue"):Clone();
			statuePrefab.Parent = workspace.Environment;
			modReplicationManager.ReplicateOut(player, statuePrefab);
			mission.Cache.Statue = statuePrefab;
			
			if not modMission:IsComplete(player, 40) then
				local function OnChanged(firstRun)
					if mission.Type == 2 then -- OnAvailable
						
					elseif mission.Type == 1 then -- OnActive
						if mission.ProgressionPoint >= 5 and modEvents:GetEvent(player, "takeNekronMask") then
							modMission:Progress(player, 40, function(mission)
								if mission.ProgressionPoint <= 7 then mission.ProgressionPoint = 7; end;
							end)
						end
					elseif mission.Type == 3 then -- OnComplete
	
						mission.Changed:Disconnect(OnChanged);
					end
				end
				mission.Changed:Connect(OnChanged);
				OnChanged(true, mission);
			else
				
			end
		end)
		
	elseif modBranchConfigs.IsWorld("Tombs") then
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 40);
			if mission == nil then return end;
			
			
			if modEvents:GetEvent(player, "takeNekronMask") == nil then
				local new = script:WaitForChild("TombRaidPickup"):Clone();
				new.Parent = workspace.Interactables;
				modReplicationManager.ReplicateOut(player, new);
			end
			
			if not modMission:IsComplete(player, 40) then
				local function OnChanged(firstRun)
					if mission.Type == 2 then -- OnAvailable
						
					elseif mission.Type == 1 then -- OnActive
						if mission.ProgressionPoint >= 5 and modEvents:GetEvent(player, "takeNekronMask") then
							modMission:Progress(player, 40, function(mission)
								if mission.ProgressionPoint <= 7 then mission.ProgressionPoint = 7; end;
							end)
						end
					elseif mission.Type == 3 then -- OnComplete
	
						mission.Changed:Disconnect(OnChanged);
					end
				end
				mission.Changed:Connect(OnChanged);
				OnChanged(true, mission);
			end
		end)
		
	end
		
	return CutsceneSequence;
end;
