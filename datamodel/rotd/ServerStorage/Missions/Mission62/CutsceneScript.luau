local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modEntity = shared.require(game.ReplicatedStorage.Library.Entity);
local modRegion = shared.require(game.ReplicatedStorage.Library.Region);

local MISSION_ID = 62;
--== Variables;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	

	-- MARK: TheHarbor
	if modBranchConfigurations.IsWorld("TheHarbor") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			local revasNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Revas");
			if revasNpcClass == nil then
				modNpcs.spawn2{
					Name = "Revas";
					Player = player;
					ReplicateOut = true;
				};
				revasNpcClass:TeleportHide();

			end
			
			local function OnChanged(firstRun)
				if mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 or mission.ProgressionPoint == 2 then
						local revasDoor = modReplicationManager.getReplicated(player, "RevasDoorway")[1];

						local revasDoorInteractConfig = revasDoor:FindFirstChild("Interactable");
						local revasDoorInteractable: InteractableInstance = modInteractables.getOrNew(revasDoorInteractConfig);
						revasDoorInteractable:SetPermissions("CanInteract", true);
						
						revasNpcClass.PlayAnimation("foldbackhands");
						revasNpcClass:SetCFrame(CFrame.new(-299.5242, 105.296021, 296.464844, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						
					end
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	-- MARK: SectorE
	elseif modBranchConfigurations.IsWorld("SectorE") then
		

		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisableMissions", false);
			modConfigurations.Set("DisableMajorNotifications", false);
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
			
			--modConfigurations.Set("DisableInventory", false);
			modData.ToggleChat();
		end);
		
		
		local mechDoor1: ObjectEntity = modEntity.getOrNew(workspace.Environment.Game:WaitForChild("MechDoubleDoors1"));
		local mechDoor2: ObjectEntity = modEntity.getOrNew(workspace.Environment.Game:WaitForChild("MechDoubleDoors2"));
		local mechDoor3: ObjectEntity = modEntity.getOrNew(workspace.Environment.Game:WaitForChild("MechDoubleDoors3"));

		mechDoor1:GetInteractable():SetPermissions("CanInteract", false);
		mechDoor2:GetInteractable():SetPermissions("CanInteract", false);
		mechDoor3:GetInteractable():SetPermissions("CanInteract", false);
		
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
			
			local revasNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Revas");
			if revasNpcClass == nil then
				revasNpcClass = modNpcs.spawn2{
					Name = "Revas";
					Player = player;
					ReplicateOut = true;
				};
				revasNpcClass:TeleportHide();
			end

			local eugeneNpcClass: NpcClass = modNpcs.getByModel(workspace.Entity:FindFirstChild("Eugene"));
			local stanNpcClass: NpcClass = modNpcs.getByModel(workspace.Entity:FindFirstChild("Stan"));

			local ratGoons = shared.WorldCore.RatGoons; -- Set by SectorE WorldScript.
			
			shared.modEventService:OnInvoked("Generic_BindClientTrigger", function(eventPacket: EventPacket, ...)
				local triggerId: string, packet: anydict = ...;
				local player: Player? = eventPacket.Player;
				if player == nil then return end;
				
				local temp = packet.Temp or nil;

				if triggerId == "shutDownHeating" then
					if temp and temp < 80 then

						chamberParticles.Rate = 4;
						chamberMonitorLabel.Text = chamberMonitorText:gsub("$percent", temp);
						
						if temp == 40 then
							if modMission:Progress(player, MISSION_ID) then
								modMission:Progress(player, MISSION_ID, function(mission)
									mission.ProgressionPoint = 9;
								end)
							end
							stanNpcClass.Chat(player, "Much better..");
							
						else
							stanNpcClass.Chat(player, "Certainly better, but I don't think that's the right temperature..");
							
						end
					end
				end
			end)

			
			local mechDoor3Clip = script.Parent:WaitForChild("_playerClip");
			local terminalInteractable = script.Parent:WaitForChild("shutDownHeating");

			local function OnChanged(firstRun)
				local rat1NpcClass: NpcClass = ratGoons.Name1.NpcClass;

				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					Debugger:Log("progress", mission, firstRun);

					local playerClass: PlayerClass = shared.modPlayers.get(player);
					if mission.ProgressionPoint <= 2 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)
						
					elseif mission.ProgressionPoint == 3 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						revasNpcClass:SetCFrame(CFrame.new(12.7711039, -11.299139, -18.2030602, -0.615661502, 0, 0.788010776, 0, 1, 0, -0.788010776, 0, -0.615661502));
						revasNpcClass.Chat(player, "Here we are..");

					elseif mission.ProgressionPoint == 4 then
						revasNpcClass:ToggleInteractable(false);
						task.wait(4);
						
						revasNpcClass.Move:SetMoveSpeed("set", "default", 6);

						revasNpcClass.Character:SetAttribute("LookAtClient", false);
						revasNpcClass.Move:MoveTo(Vector3.new(28.638, -11.299, -12.154));
						revasNpcClass.Move.OnMoveToEnded:Once(function()
							revasNpcClass.Move:Face(Vector3.new(31.444, -10.267, -17.967));
							
							rat1NpcClass.Move:Face(Vector3.new(31.444, -10.267, -17.967));
							revasNpcClass.Move:HeadTrack(rat1NpcClass.Head, 1);
							
							task.wait(0.5);
							rat1NpcClass.StopAnimation("foldbackhands");
							rat1NpcClass.PlayAnimation("Press");
							
							task.wait(0.5);
							mechDoor1:GetDoor():Toggle(true);
							mechDoor2:GetDoor():Toggle(true);
							mechDoor3:GetDoor():Toggle(true);
							
							eugeneNpcClass.PlayAnimation("useterminal");
							stanNpcClass:GetComponent("AvatarFace"):Set("Unconscious");

							rat1NpcClass.Move:Face(revasNpcClass.RootPart.Position);
							revasNpcClass.Move:Face(Vector3.new(31.91, -8.913, -12.25));
							
							task.wait(1);
							
							revasNpcClass.Move:MoveTo(Vector3.new(113.896, -11.299, -79.031));
							revasNpcClass.Move.OnMoveToEnded:Once(function()
								modMission:Progress(player, MISSION_ID, function(mission)
									mission.ProgressionPoint = 5;
								end)
							end);
							
							task.wait(3);
							revasNpcClass.Chat(player, "Unlike Sector F, this sector was surprisingly well contained.");
						end);

					elseif mission.ProgressionPoint == 5 then
						eugeneNpcClass:ToggleInteractable(false);

						revasNpcClass.Move:HeadTrack(eugeneNpcClass.Head);
						eugeneNpcClass.Chat(player, "Hmmm.. Not responding, turning up the heat.");
						
						task.wait(4);
						revasNpcClass.Move:HeadTrack(playerClass.Head, 2);
						revasNpcClass.Chat(player, "Looks like Eugene is a bit busy..");
						task.wait(3);
						
						eugeneNpcClass.StopAnimation("useterminal");
						task.wait(0.5);
						eugeneNpcClass.Move:MoveTo(Vector3.new(137.072, -8.217, -81.746));
						eugeneNpcClass.Chat(player, "Oh greetings, Mr. Revas.");
						eugeneNpcClass.Move:HeadTrack(revasNpcClass.Head, 3);
						
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
							playerClass:SetCFrame(CFrame.new(113.366264, -11.299139, -82.7207794));
						end
						
						eugeneNpcClass.Move:SetMoveSpeed("set", "default", 6);
						eugeneNpcClass.Chat(player, "Progress are being made sir. But I have to discuss some matters with you in private.");
						eugeneNpcClass.Move:HeadTrack(revasNpcClass.Head, 5);
						task.wait(5);

						revasNpcClass.Chat(player, "Very well..");
						revasNpcClass.Move:HeadTrack(eugeneNpcClass.Head, 6);
						task.wait(5);

						eugeneNpcClass.Move:MoveTo(Vector3.new(85.143, -11.299, -75.072));
						eugeneNpcClass.Move.OnMoveToEnded:Once(function()
							mechDoor3:GetDoor():Toggle(false);
							
							modMission:Progress(player, MISSION_ID, function(mission)
								mission.ProgressionPoint = 6;
							end)
						end)

						revasNpcClass.Move:Face("Player");
						revasNpcClass.Move:HeadTrack();
						revasNpcClass.Character:SetAttribute("LookAtClient", nil);
						task.wait(0.5);

						revasNpcClass.Chat(player, `{player.Name}, please give us a moment..`);
						revasNpcClass.Move:HeadTrack(playerClass.Head, 2);
						task.wait(2);

						revasNpcClass.Move:MoveTo(Vector3.new(80.143, -11.299, -75.072));
						revasNpcClass.Move:HeadTrack(eugeneNpcClass.Head, 4);

					elseif mission.ProgressionPoint == 6 then
						
						local clockTick = tick();
						for a=40, 80, 0.3 do
							local percent = math.floor(a*10)/10;
							
							chamberMonitorLabel.Text = chamberMonitorText:gsub("$percent", percent);
							
							if tick()-clockTick >= 1 then
								modAudio.Play("ClockTick", chamberMonitorScreen);
								clockTick = tick();
							end
							
							chamberParticles.Rate = 4 + a;
							
							task.wait(0.1);
						end
						chamberMonitorLabel.Text = chamberMonitorText:gsub("$percent", 80);

						local stanHitbox = stanNpcClass.RootPart:Clone();
						stanHitbox.Name = "Hitbox";
						stanHitbox.Size = Vector3.new(3.527, 4.343, 3.543);
						stanHitbox.Parent = stanNpcClass.Character;
						
						local hurtSound = modAudio.Play("ZombieHurt2", stanHitbox);
						hurtSound.Volume = 0.5;
						hurtSound.PlaybackSpeed = 1.1;

						stanNpcClass:GetComponent("AvatarFace"):Set("Frustrated");
						stanNpcClass.Chat(player, "Ugghh.. My.. Head..");
						
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
						
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:GetComponent("AvatarFace"):Set("Unconscious");
						
						mechDoor3Clip.Parent = script;
						mechDoor3:GetDoor():Toggle(true);
						
						eugeneNpcClass.Move:MoveTo(Vector3.new(115.657, -11.299, -75.823));
						eugeneNpcClass.Move.OnMoveToEnded:Once(function()
							eugeneNpcClass.Move:Face(Vector3.new(118.124, -11.299, -79.48));
							
						end)
						revasNpcClass.Move:MoveTo(Vector3.new(109.39, -11.299, -80.801));
						revasNpcClass.Move.OnMoveToEnded:Once(function()
							revasNpcClass.Move:Face(Vector3.new(118.124, -11.299, -79.48));
						end)
						task.wait(3);

						revasNpcClass.Chat(player, "Alright.. I have the perfect scavenger for the job.");
						task.wait(3);

						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 11;
						end)

					elseif mission.ProgressionPoint == 11 then
						revasNpcClass:ToggleInteractable(true);

					elseif mission.ProgressionPoint == 12 then
						task.wait(4);
						
						eugeneNpcClass.Move:MoveTo(Vector3.new(141.05, -8.217, -80.159));
						eugeneNpcClass.Move.OnMoveToEnded:Once(function()
							eugeneNpcClass.Move:Face(Vector3.new(143.568, -8.194, -80.346));
							task.wait(1);

							eugeneNpcClass.PlayAnimation("useterminal");
							task.wait(math.random(5,10));

							eugeneNpcClass.Chat(player, "Hmmm, why is the heating disabled..");
						end)
						
						revasNpcClass:ToggleInteractable(false);
						revasNpcClass.Move:MoveTo(Vector3.new(4.766, -11.295, -4.694));
						revasNpcClass.Move.OnMoveToEnded:Once(function()
							task.wait(0.5);
							revasNpcClass:TeleportHide();
						end)
						
					elseif mission.ProgressionPoint == 15 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						Debugger:Log("Mission changed");
						if firstRun then
							eugeneNpcClass.PlayAnimation("useterminal");
							stanNpcClass:GetComponent("AvatarFace"):Set("Unconscious");
							
							local distFromPlayer = 128;
							repeat
								task.wait(1);
								distFromPlayer = rat1NpcClass:DistanceFromCharacter(playerClass:GetCFrame().Position);
								Debugger:Log("distFromPlayer", distFromPlayer);
							until distFromPlayer <= 8;

							rat1NpcClass.Move:Face(Vector3.new(31.444, -10.267, -17.967));
							
							task.wait(0.5);
							rat1NpcClass.StopAnimation("foldbackhands");
							rat1NpcClass.PlayAnimation("Press");

							task.wait(0.5);
							mechDoor1:GetDoor():Toggle(true);
							mechDoor2:GetDoor():Toggle(true);
							mechDoor3:GetDoor():Toggle(true);

							rat1NpcClass.Move:Face(Vector3.new(12.09, -10.2, -3.52));
						end
						
						
					end
				elseif mission.Type == 3 then -- OnComplete
					CutsceneSequence:NextScene("enableInterfaces");

				end
			end

			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	-- MARK: SectorF
	elseif modBranchConfigurations.IsWorld("SectorF") then
		
		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
			modConfigurations.Set("DisableInventory", false);
			modData.ToggleChat();
		end);

		CutsceneSequence:Initialize(function()
			Debugger:Warn(`RatsRecruitment SectorF`)
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
				

			local revasNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Revas");
			if revasNpcClass == nil then
				revasNpcClass = modNpcs.spawn2{
					Name = "Revas";
					Player = player;
					ReplicateOut = true;
				};

				revasNpcClass:TeleportHide();
			end

			shared.modEventService:OnInvoked("Generic_BindItemPickup", function(event: EventPacket, ...)
				local interactable: InteractableInstance = ...;
				local player: Player? = event.Player;
				if player == nil then return end;
				
				task.spawn(function()
					local itemId = interactable.Values.ItemId;
					if itemId ~= "researchpapers" then return end;

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 14;
					end)
				end);
			end);

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					Debugger:Log("progress", mission, firstRun);
					
					if mission.ProgressionPoint == 12 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 13;
						end)
						
					elseif mission.ProgressionPoint == 13 then
						CutsceneSequence:NextScene("enableInterfaces");
						
						revasNpcClass.PlayAnimation("foldbackhands");
						revasNpcClass:SetCFrame(CFrame.new(-3.47873974, 60.2009239, -9.81020737, -0.981627166, 0, -0.190808967, 0, 1, 0, 0.190808967, 0, -0.981627166));
						
						task.wait(10);
						revasNpcClass.Chat(player, "I will wait here while you search for the papers..");
						
					elseif mission.ProgressionPoint == 15 then
						
						task.wait(1);
						revasNpcClass.Chat(player, "Get back to Sector E once you have acquired the items.");
						task.wait(5);
						revasNpcClass:TeleportHide();
						
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