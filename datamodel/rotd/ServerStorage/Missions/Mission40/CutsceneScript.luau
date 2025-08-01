local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modEventService = shared.require(game.ReplicatedStorage.Library.EventService);

--== Variables;
local MISSION_ID = 40;

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;


if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);
	modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
	modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
	modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
	modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	statuePrefab = script.Parent:WaitForChild("statue");
	tombsInteractable = script.Parent:WaitForChild("Raid_Tombs");
	tombRaidPickup = script.Parent:WaitForChild("TombRaidPickup");

	if modBranchConfigs.IsWorld("TheWarehouse") then
		local caveTpTouch = modTouchHandler.new("CaveTP", 1);
		
		function caveTpTouch:OnPlayerTouch(player, basePart, part)
			modMission:Progress(player, MISSION_ID, function(mission)
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
				humanoid:TakeDamage(5, self.Player, self.StorageItem, part);
				remoteCameraShakeAndZoom:FireClient(player, 5, 0, 0.3, 2, false);
				if player then modStatusEffects.Burn(player, 94, 1); end;
			end
		end
		
		for _, part in pairs(workspace.Environment:WaitForChild("SecPark"):WaitForChild("Lava"):GetChildren()) do
			touchHandler:AddObject(part);
		end
		

		modOnGameEvents:ConnectEvent("OnBossDefeated", function(players, npcModule)
			if npcModule.Name ~= "Zricera" then return end;

			for _, player in pairs(players) do
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint > 2 then return end;
					mission.ProgressionPoint = 2;
				end)
				
			end
		end)

		modEventService:OnInvoked("GameModeManager_BindDisconnectPlayer", function(event, packet)
			local player = event.Player;
			local menuRoom = packet.MenuRoom;
			if menuRoom == nil or menuRoom.Type ~= "Boss" or menuRoom.Stage ~= "Zricera" then return end;

			local destination;
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.Pinned and mission.ProgressionPoint >= 2 and mission.ProgressionPoint <= 4 then
					mission.ProgressionPoint = 3;
					destination = CFrame.new(352.464, -30.64, 1885.59);
				end;
			end)

			if destination then
				packet.SetTeleportCfFunc(destination);
			end
		end)
		
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
			local triggerId: string = ...;
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			if triggerId ~= "Push Statue" then return end;

			modMission:Progress(player, 40, function(mission)
				local statueObject = mission.Cache.Statue;
				
				if statueObject then
					TweenService:Create(statueObject, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
						CFrame = CFrame.new(352.495, -30.669, 1923.279);
					}):Play();
					
					delay(30, function()
						TweenService:Create(statueObject, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
							CFrame = CFrame.new(352.49469, -30.6694565, 1912.8186, 1, 0, 0, 0, 1, 0, 0, 0, 1);
						}):Play();
					end)
				else
					Debugger:Warn("Statue does not exist.");
				end
				
				if mission.ProgressionPoint == 3 then mission.ProgressionPoint = 4; end;
			end)

		end)
		
	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)

	if modBranchConfigs.IsWorld("TheWarehouse") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modMission:IsComplete(player, 42) then
				local newTombsInteractable = tombsInteractable:Clone();
				modReplicationManager.ReplicateIn(player, newTombsInteractable, workspace.Interactables);
				return;
			end
			
			local victorModule = modNpcs.getPlayerNpc(player, "Victor");
			if victorModule == nil then
				local npc = modNpcs.spawn("Victor", nil, function(npc, npcModule)
					npcModule.Player = player;
					victorModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			victorModule.PlayAnimation("Sit");

			local newstatuePrefab = statuePrefab:Clone();
			newstatuePrefab.Parent = workspace.Environment;
			modReplicationManager.ReplicateOut(player, newstatuePrefab);
			mission.Cache.Statue = newstatuePrefab;
			
			if modMission:IsComplete(player, MISSION_ID) then
				return;
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint >= 5 and modEvents:GetEvent(player, "takeNekronMask") then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 7 then mission.ProgressionPoint = 7; end;
						end)
					end
				elseif mission.Type == 3 then -- OnComplete

					mission.OnChanged:Disconnect(OnChanged);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
				
		end)
		

	elseif modBranchConfigs.IsWorld("Tombs") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			if modEvents:GetEvent(player, "takeNekronMask") == nil then
				local new = tombRaidPickup:Clone();
				new.Parent = workspace.Interactables;
				modReplicationManager.ReplicateOut(player, new);
			end
			
			if modMission:IsComplete(player, MISSION_ID) then
				return;
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint >= 5 and modEvents:GetEvent(player, "takeNekronMask") then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 7 then mission.ProgressionPoint = 7; end;
						end)
					end
				elseif mission.Type == 3 then -- OnComplete

					mission.OnChanged:Disconnect(OnChanged);
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
			
		end)
	
		
	end


	return CutsceneSequence;
end;