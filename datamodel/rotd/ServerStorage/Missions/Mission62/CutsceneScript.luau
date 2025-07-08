local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modEntity = shared.require(game.ReplicatedStorage.Library.Entity);
local modRegion = shared.require(game.ReplicatedStorage.Library.Region);

--== Variables;
local MISSION_ID = 62;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
	
else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	
	if modBranchConfigs.IsWorld("TheHarbor") then
		-- MARK: TheHarbor
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			local revasModule = modNpcs.getByOwner(player, "Revas");
			if revasModule == nil then
				local npc = modNpcs.spawn("Revas", nil, function(npc, npcModule)
					npcModule.Owner = player;
					revasModule = npcModule;

				end);
				modReplicationManager.ReplicateOut(player, npc);
				
				revasModule:TeleportHide();
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 or mission.ProgressionPoint == 2 then
						local revasDoor = modReplicationManager.getReplicated(player, "RevasDoorway")[1];

						local doorData = shared.require(revasDoor.Door);
						doorData:SetAccess(player, true);
						
						revasModule.PlayAnimation("foldbackhands");
						revasModule.Actions:Teleport(CFrame.new(-299.5242, 105.296021, 296.464844, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						
					end
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	elseif modBranchConfigs.IsWorld("SectorE") then
		-- MARK: SectorE

		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisableMissions", false);
			modConfigurations.Set("DisableMajorNotifications", false);
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
			
			--modConfigurations.Set("DisableInventory", false);
			modData.ToggleChat();
		end);
		
		
		local mechDoor1 = modEntity:GetEntity(workspace.Environment.Game:WaitForChild("mechDoor1"));
		local mechDoor2 = modEntity:GetEntity(workspace.Environment.Game:WaitForChild("mechDoor2"));
		local mechDoor3 = modEntity:GetEntity(workspace.Environment.Game:WaitForChild("mechDoor3"));
		
		local chamberParticles = workspace.Environment.Game.Chamber.Glass.ParticleEmitter;
		local chamberMonitorScreen = workspace.Environment.Game.hangingMonitor._screen;
		local chamberMonitorLabel = chamberMonitorScreen.SurfaceGui.Frame.TextLabel;
		local chamberMonitorText = [[Nekron Chamber #02

		Running Mode: Manual

		Chamber Temperature: Heating ($percent°)]];

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			local sound = modAudio.Play("GreyAmbience", workspace);
			sound.Volume = 0.03;
			
			local revasModule = modNpcs.getByOwner(player, "Revas");
			if revasModule == nil then
				local npc = modNpcs.spawn("Revas", nil, function(npc, npcModule)
					npcModule.Owner = player;
					revasModule = npcModule;

				end);
				modReplicationManager.ReplicateOut(player, npc);

				revasModule:TeleportHide();
			end

			local eugeneModule = modNpcs.getByModel(workspace.Entity:FindFirstChild("Eugene"));
			local stanModule = modNpcs.getByModel(workspace.Entity:FindFirstChild("Stan"));

			local RatGoons = modNpcs.RatGoons; -- Set by SectorE WorldScript.
			
			shared.modEventService:OnInvoked("Interactables_BindTrigger", function(eventPacket: EventPacket, interactData, packet)
				local player: Player? = eventPacket.Player;
				if player == nil then return end;

				local temp = packet.Temp or nil;
				local triggerId = interactData.TriggerTag;

				if triggerId == "RatRecruit1" then
					if temp and temp < 80 then

						chamberParticles.Rate = 4;
						chamberMonitorLabel.Text = chamberMonitorText:gsub("$percent", temp);
						
						if temp == 40 then
							if modMission:Progress(player, 62) then
								modMission:Progress(player, 62, function(mission)
									mission.ProgressionPoint = 9;
								end)
							end
							stanModule.Chat(player, "Much better..");
							
						else
							stanModule.Chat(player, "Certainly better, but I don't think that's the right temperature..");
							
						end
					end


				end
			end);
			
			local mechDoor3Clip = script.Parent:WaitForChild("_playerClip");
			local terminalInteractable = script.Parent:WaitForChild("shutDownHeating");

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					Debugger:Log("progress", mission, firstRun);

					if mission.ProgressionPoint <= 2 then
						modMission:Progress(player, 62, function(mission)
							mission.ProgressionPoint = 3;
						end)
						
					elseif mission.ProgressionPoint == 3 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						revasModule.Actions:Teleport(CFrame.new(12.7711039, -11.299139, -18.2030602, -0.615661502, 0, 0.788010776, 0, 1, 0, -0.788010776, 0, -0.615661502));
						revasModule.Chat(player, "Here we are..");

					elseif mission.ProgressionPoint == 4 then
						revasModule:ToggleInteractable(false);
						task.wait(4);
						
						revasModule.Movement:SetWalkSpeed("default", 6);
						
						revasModule.Prefab:SetAttribute("LookAtClient", false);
						revasModule.Movement:Move(Vector3.new(28.638, -11.299, -12.154)):OnComplete(function()
							revasModule.Movement:Face(Vector3.new(31.444, -10.267, -17.967));
							
							RatGoons.Name1.NpcModule.Movement:Face(Vector3.new(31.444, -10.267, -17.967));
							revasModule.Move:HeadTrack(RatGoons.Name1.NpcModule.Head);
							
							task.wait(0.5);
							RatGoons.Name1.NpcModule.StopAnimation("foldbackhands");
							RatGoons.Name1.NpcModule.PlayAnimation("Press");
							
							task.wait(0.5);
							mechDoor1.Door:Toggle(true);
							mechDoor2.Door:Toggle(true);
							mechDoor3.Door:Toggle(true);
							
							eugeneModule.PlayAnimation("useterminal");
							stanModule.AvatarFace:Set("Unconscious");

							RatGoons.Name1.NpcModule.Movement:Face(revasModule.RootPart.Position);
							revasModule.Movement:Face(Vector3.new(31.91, -8.913, -12.25));
							
							task.wait(1);
							
							revasModule.Movement:Move(Vector3.new(113.896, -11.299, -79.031)):OnComplete(function()
								modMission:Progress(player, 62, function(mission)
									mission.ProgressionPoint = 5;
								end)
							end);
							
							task.wait(3);
							revasModule.Chat(player, "Unlike Sector F, this sector was surprisingly well contained.");
						end);

					elseif mission.ProgressionPoint == 5 then
						eugeneModule:ToggleInteractable(false);
						eugeneModule.Chat(player, "Hmmm.. Not responding, turning up the heat.");
						
						task.wait(4);
						revasModule.Chat(player, "Looks like Eugene is a bit busy..");
						task.wait(3);
						
						eugeneModule.StopAnimation("useterminal");
						task.wait(0.5);
						eugeneModule.Movement:Move(Vector3.new(137.072, -8.217, -81.746));
						eugeneModule.Chat(player, "Oh greetings, Mr. Revas.");
						
						task.wait(2);
						mechDoor3Clip.Parent = workspace.Clips;
						
						local playersInRegion = modRegion:GetPlayersWithin(script.Parent.ChamberRegion);
						local playerIsInRegion = false;
						for a=1, #playersInRegion do
							if playersInRegion[a] == player then
								playerIsInRegion = true;
								break;
							end
						end
						
						if not playerIsInRegion then
							local playerClass = shared.modPlayers.get(player);
							playerClass:SetCFrame(CFrame.new(113.366264, -11.299139, -82.7207794));
						end
						
						eugeneModule.Movement:SetWalkSpeed("default", 6);
						eugeneModule.Chat(player, "Progress are being made sir. But I have to discuss some matters with you in private.");
						
						task.wait(5);
						revasModule.Chat(player, "Very well..");
						
						task.wait(5);
						eugeneModule.Movement:Move(Vector3.new(85.143, -11.299, -75.072)):OnComplete(function()
							mechDoor3.Door:Toggle(false);
							
							modMission:Progress(player, 62, function(mission)
								mission.ProgressionPoint = 6;
							end)
						end)

						revasModule.Actions:FaceOwner()
						revasModule.Move:HeadTrack();
						revasModule.Prefab:SetAttribute("LookAtClient", nil);
						task.wait(0.5);
						revasModule.Chat(player, player.Name..", please give us a moment..");
						task.wait(2);
						revasModule.Movement:Move(Vector3.new(80.143, -11.299, -75.072));
						

					elseif mission.ProgressionPoint == 6 then
						
						local clockTick = tick();
						for a=40, 80, 0.3 do
							local percent = math.floor(a*10)/10;
							
							Debugger:Log("Chamber ",percent,"%");
							chamberMonitorLabel.Text = chamberMonitorText:gsub("$percent", percent);
							
							if tick()-clockTick >= 1 then
								modAudio.Play("ClockTick", chamberMonitorScreen);
								clockTick = tick();
							end
							
							chamberParticles.Rate = 4 + a;
							
							task.wait(0.1);
						end
						chamberMonitorLabel.Text = chamberMonitorText:gsub("$percent", 80);

						local stanHitbox = stanModule.RootPart:Clone();
						stanHitbox.Name = "Hitbox";
						stanHitbox.Size = Vector3.new(3.527, 4.343, 3.543);
						stanHitbox.Parent = stanModule.Prefab;
						
						local hurtSound = modAudio.Play("ZombieHurt", stanHitbox);
						hurtSound.Volume = 0.5;
						hurtSound.PlaybackSpeed = 1.1;
						stanModule.AvatarFace:Set("Frustrated");
						stanModule.Chat(player, "Ugghh.. My.. Head..");
						
						modMission:Progress(player, 62, function(mission)
							mission.ProgressionPoint = 7;
						end)

					elseif mission.ProgressionPoint == 7 then
						
					elseif mission.ProgressionPoint == 8 then
						
						terminalInteractable.Parent = workspace.Interactables;

					elseif mission.ProgressionPoint == 9 then
						terminalInteractable.Parent = script;

					elseif mission.ProgressionPoint == 10 then
						task.wait(4);
						
						stanModule:ToggleInteractable(false);
						stanModule.AvatarFace:Set("Unconscious");
						
						mechDoor3Clip.Parent = script;
						mechDoor3.Door:Toggle(true);
						
						eugeneModule.Movement:Move(Vector3.new(115.657, -11.299, -75.823)):OnComplete(function()
							eugeneModule.Movement:Face(Vector3.new(118.124, -11.299, -79.48));
							
						end)
						revasModule.Movement:Move(Vector3.new(109.39, -11.299, -80.801)):OnComplete(function()
							revasModule.Movement:Face(Vector3.new(118.124, -11.299, -79.48));
						end)
						
						task.wait(3);
						revasModule.Chat(player, "Alright.. I have the perfect scavenger for the job.");
						
						task.wait(3);

						modMission:Progress(player, 62, function(mission)
							mission.ProgressionPoint = 11;
						end)

					elseif mission.ProgressionPoint == 11 then
						revasModule:ToggleInteractable(true);

					elseif mission.ProgressionPoint == 12 then
						task.wait(4);
						
						eugeneModule.Movement:Move(Vector3.new(141.05, -8.217, -80.159)):OnComplete(function()
							eugeneModule.Movement:Face(Vector3.new(143.568, -8.194, -80.346));
							task.wait(1);
							eugeneModule.PlayAnimation("useterminal");
							
							task.wait(math.random(5,10));
							eugeneModule.Chat(player, "Hmmm, why is the heating disabled..");
						end)
						
						revasModule:ToggleInteractable(false);
						revasModule.Movement:Move(Vector3.new(4.766, -11.295, -4.694)):OnComplete(function()
							task.wait(0.5);
							revasModule:TeleportHide();
						end)
						
					elseif mission.ProgressionPoint == 15 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						Debugger:Log("Mission changed");
						if firstRun then
							eugeneModule.PlayAnimation("useterminal");
							stanModule.AvatarFace:Set("Unconscious");
							
							local classPlayer = shared.modPlayers.get(player);
							
							local distFromPlayer = 128;
							repeat
								task.wait(1);
								distFromPlayer = RatGoons.Name1.NpcModule.Actions:DistanceFrom(classPlayer.RootPart.Position);
								Debugger:Log("distFromPlayer", distFromPlayer);
							until distFromPlayer <= 8;

							RatGoons.Name1.NpcModule.Movement:Face(Vector3.new(31.444, -10.267, -17.967));
							
							task.wait(0.5);
							RatGoons.Name1.NpcModule.StopAnimation("foldbackhands");
							RatGoons.Name1.NpcModule.PlayAnimation("Press");

							task.wait(0.5);
							mechDoor1.Door:Toggle(true);
							mechDoor2.Door:Toggle(true);
							mechDoor3.Door:Toggle(true);

							RatGoons.Name1.NpcModule.Movement:Face(Vector3.new(12.09, -10.2, -3.52));
						end
						
						
					end
				elseif mission.Type == 3 then -- OnComplete
					CutsceneSequence:NextScene("enableInterfaces");

				end
			end

			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	elseif modBranchConfigs.IsWorld("SectorF") then
		-- MARK: SectorF
		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
			modConfigurations.Set("DisableInventory", false);
			modData.ToggleChat();
		end);

		CutsceneSequence:Initialize(function()
			while modGameModeManager.IsGameWorld == nil do
				task.wait(0.5);
				Debugger:Warn("Waiting for IsGameWorld to set")
			end;
			if modGameModeManager.IsGameWorld then Debugger:Warn("Cancel cutscene in gamemode"); return end
			game.Players:SetAttribute("AutoRespawn", true);

			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				

			local revasModule = modNpcs.getByOwner(player, "Revas");
			if revasModule == nil then
				local npc = modNpcs.spawn("Revas", nil, function(npc, npcModule)
					npcModule.Owner = player;
					revasModule = npcModule;

				end);
				modReplicationManager.ReplicateOut(player, npc);

				revasModule:TeleportHide();
			end

			shared.modEventService:OnInvoked("Generic_BindItemPickup", function(
				event: EventPacket, 
				interactData, 
				storageItem: StorageItem
			)
				local player: Player? = event.Player;
				if player == nil then return end;
				
				task.spawn(function()
					if interactData.Type ~= modInteractables.Types.Pickup then return end;

					local itemId = interactData.ItemId;
					if itemId ~= "researchpapers" then return end;

					modMission:Progress(player, 62, function(mission)
						mission.ProgressionPoint = 14;
					end)
				end);
			end);

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					Debugger:Log("progress", mission, firstRun);
					
					if mission.ProgressionPoint == 12 then
						modMission:Progress(player, 62, function(mission)
							mission.ProgressionPoint = 13;
						end)
						
					elseif mission.ProgressionPoint == 13 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						revasModule.PlayAnimation("foldbackhands");
						revasModule.Actions:Teleport(CFrame.new(-3.47873974, 60.2009239, -9.81020737, -0.981627166, 0, -0.190808967, 0, 1, 0, 0.190808967, 0, -0.981627166));
						
						task.wait(10);
						revasModule.Chat(player, "I will wait here while you search for the papers..");
						
					elseif mission.ProgressionPoint == 15 then
						
						task.wait(1);
						revasModule.Chat(player, "Get back to Sector E once you have acquired the items.");
						task.wait(5);
						revasModule:TeleportHide();
						
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end

			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

	end

	
	return CutsceneSequence;
end;