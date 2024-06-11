local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 1;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	modOnGameEvents:ConnectEvent("OnToolEquipped", function(player, storageItem)
		if storageItem == nil then return end;
		if storageItem.ItemId ~= "p250" then return end;

		local mission1 = modMission:GetMission(player, missionId);
		if mission1 == nil or mission1.Type ~= 1 then return end;

		modMission:Progress(player, missionId, function(mission)
			if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
		end)
	end)
	
	modOnGameEvents:ConnectEvent("OnItemPickup", function(player, storageItem)
		if storageItem == nil then return end;
		if storageItem.ItemId ~= "p250" then return end;
		
		modMission:Progress(player, missionId, function(mission)
			if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
		end)
	end)

else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
local sceneDialogues = modConfigurations.SpecialEvent.AprilFools
 and {
	{Speaker="Mason"; Reply="Ski-ba-bop-ba-dop-bop.. Oh hey!"};
	{Speaker="Mason"; Reply="Ey yo, you alive bruh?"};
	{Speaker="Mason"; Reply="We have to skidaddle, the zombies are coming!"};
	{Speaker="Mason"; Reply="I don't know why there's a pistol here but take it and use it.";};
	{Speaker="Mason"; Reply="Here they come!!!!!!";};

	{Speaker="Mason"; Reply="Aight, I'mma head out.."};
	{Speaker="Mason"; Reply="Sheeeesh";};

} or {
	{Speaker="Mason"; Reply="Oh ####... Hey! Hey, wake up."};
	{Speaker="Mason"; Reply="Oh god, you're alive. Hurry, get up."};
	{Speaker="Mason"; Reply="We have to get out of here, zombies are coming."};
	{Speaker="Mason"; Reply="Here, take this pistol and help me fight them.";};
	{Speaker="Mason"; Reply="Here they come! Point your gun at them and pull the trigger.";};

	{Speaker="Mason"; Reply="Keep shooting, I will get the car ready."};
	{Speaker="Mason"; Reply="HOLY ####!";};

};

return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheBeginning") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;

	local modInterface;
	local studioLogo, titleLogo, blurEffect, bloomEffect, musicTrack, MasonNpcModule

	if modData then
		repeat
			modInterface = modData:GetInterfaceModule();
			Debugger:Warn("Waiting for interface..");
			if modInterface == nil then task.wait(); end
		until modInterface ~= nil;

		local cutsceneFrame = script:WaitForChild("Cutscene"):Clone();
		cutsceneFrame.Parent = modInterface.MainInterface;

		studioLogo = cutsceneFrame:WaitForChild("StudioLogo");
		titleLogo = cutsceneFrame:WaitForChild("TitleLogo");

		local camera = workspace.CurrentCamera;
		blurEffect = Instance.new("BlurEffect");
		blurEffect.Name = "CutsceneBlur";
		blurEffect.Size = 100;
		blurEffect.Parent = camera;

		bloomEffect = Instance.new("BloomEffect");
		bloomEffect.Intensity = 1;
		bloomEffect.Size = 56;
		bloomEffect.Threshold = 0.8;
		bloomEffect.Parent = camera;

		musicTrack = modAudio.Get("MainTheme");
		musicTrack.Volume = 0;
		musicTrack:Play();
		TweenService:Create(musicTrack, TweenInfo.new(30), {Volume = 0.45;}):Play();

		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableMapMenu", true);
		modConfigurations.Set("CanQuickEquip", false);
		modConfigurations.Set("ShowNameDisplays", false);
	end
	
	--== Server

	local sceneRunning = false;
	CutsceneSequence:Initialize(function()
		if sceneRunning then Debugger:Log("Scene already running..") return end;
		sceneRunning = true;

		game.Lighting:SetAttribute("FogEnd", 250);
		pcall(function() game.Players.RespawnTime = 60; end);
		
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		
		local item, storage = modStorage.FindItemIdFromStorages("p250", player);
		if item ~= nil then
			storage:DeleteValues(item.ID, {"A"; "MA"});
		end
		
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
		
		if mission.Type == 2 then
			modMission:StartMission(player, missionId);
		end

		local classPlayer = shared.modPlayers.Get(player);
		classPlayer:Spawn();

		shared.modAntiCheatService:Teleport(player, CFrame.new(3.6, 55.376, -188.5));
		while not classPlayer.IsAlive do
			task.wait();
			Debugger:Log("Waiting for player spawn");
		end
		
		Debugger:Log("Scene playerSpawns", debug.traceback());
		CutsceneSequence:NextScene("playerSpawns");
		
		Debugger:Log("Scene spawnFriend");
		CutsceneSequence:NextScene("spawnFriend");
		
		Debugger:Log("Scene studioLogo");
		CutsceneSequence:NextScene("studioLogo");
		
		Debugger:Log("Scene titleLogo");
		CutsceneSequence:NextScene("titleLogo");
		
		Debugger:Log("Scene MasonArrives");
		CutsceneSequence:NextScene("MasonArrives");
		
		Debugger:Log("Scene blowUpBridge");
		CutsceneSequence:NextScene("blowUpBridge");
		
		Debugger:Log("Scene end");
	end)
	
	local playerAnimTracks = {};
	CutsceneSequence:NewScene("playerSpawns", function()
		game.Lighting:SetAttribute("FogEnd", 250);
		
		modInterface:ToggleGameBlinds(false, 0);
		
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", false);
		modData.ToggleChat();

		local modCharacter = modData:GetModCharacter();
		repeat
			modCharacter = modData:GetModCharacter();
			Debugger:Log("Waiting for character module..");
			wait(0.1);
		until modCharacter ~= nil;

		local classPlayer = shared.modPlayers.Get(localPlayer);
		local rootPart = classPlayer.RootPart;
		local humanoid = classPlayer.Humanoid;
		local head = classPlayer.Head;
		modData.ToggleChat();
		if head:FindFirstChild("face") ~= nil then
			head.face.Parent = script;
		end
		
		local unconsciousFace = script:WaitForChild("unconsciousFace"):Clone();
		unconsciousFace.Parent = head;
		unconsciousFace.Texture = "rbxassetid://2255073000";
		
		rootPart.CFrame = CFrame.new(3.6, 55.376, -188.5 , 0.874621153, 0, -0.484807134, 0, 1, 0, 0.484807104, 0, 0.874621153);
		
		playerAnimTracks.Unconscious = humanoid:LoadAnimation(script:WaitForChild("Unconscious"));
		playerAnimTracks.UnconsciousWake = humanoid:LoadAnimation(script:WaitForChild("UnconsciousWake"));
		playerAnimTracks.CrouchPickUp = humanoid:LoadAnimation(script:WaitForChild("CrouchPickUp"));
		
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanInteract = false;
		modCharacter.CharacterProperties.FirstPersonCamCFrame = CFrame.new(2.75, 54.7760048, -187.500031, 0.99984777, 0.00950372685, 0.0146345021, 0.000608999864, 0.819155276, -0.573571563, -0.0174389966, 0.573493183, 0.819024682);
		modCharacter.MouseProperties.CameraSmoothing = 0.02;
		
		rootPart.Anchored = true;
		game.Lighting:SetAttribute("FogStart", 0);
		game.Lighting:SetAttribute("FogEnd", 0);
		
		playerAnimTracks.Unconscious:Play();
		task.wait(5);
		
		modInterface:ToggleGameBlinds(true, 10);
		
		TweenService:Create(blurEffect, TweenInfo.new(10), {Size = 15;}):Play();
		game.Lighting:SetAttribute("FogStart", 40);
		game.Lighting:SetAttribute("FogEnd", 250);

		task.wait(6);
		task.spawn(function()
			if CutsceneSequence.QualityLevel > 6 then
				repeat
					modCharacter.MouseProperties.CameraSmoothing = modCharacter.MouseProperties.CameraSmoothing +0.00066;
				until modCharacter.MouseProperties.CameraSmoothing > 0.2 or not task.wait(1/10);
			else
				task.wait(10);
			end
			
			modCharacter.MouseProperties.CameraSmoothing = 0;
			modInterface:ToggleGameBlinds(true, 0);
		end);

		local bloomTween = TweenService:Create(bloomEffect, TweenInfo.new(6), {Intensity = 0; Size=0;});
		bloomTween.Completed:Connect(function() bloomEffect.Enabled = false; end);
		bloomTween:Play();
		
		modData.ToggleChat();
	end);
	
	local playerDied = false;
	local masonPrefab, masonNpcModule;
	CutsceneSequence:NewServerScene("spawnFriend", function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		
		local classPlayer = shared.modPlayers.Get(player);
		classPlayer.Humanoid.Health = classPlayer.Humanoid.MaxHealth;
		classPlayer:OnNotIsAlive(function(character)
			if playerDied then return end;
			playerDied = true;
			modServerManager:Teleport(player, "TheBeginning");
		end)
		modMission:Progress(player, missionId, function(mission)
			mission.ProgressionPoint = 1;
		end)

		Debugger:Log("Spawn mason");
		
		
		masonPrefab = modNpc.Spawn("Mason", CFrame.new(-1.22, 55.46, -287.322), function(npc, npcModule)
			masonNpcModule = npcModule;

			npcModule.Owner = player;
			
			local actionIndex = 0;
			npcModule.CutsceneActions = {};

			table.insert(npcModule.CutsceneActions, function()
				Debugger:Log("Run to player.");

				npcModule.Move:SetMoveSpeed("set", "default", 18);
				npcModule:ToggleInteractable(false);
				
				npcModule.Move:MoveTo(Vector3.new(2.737, 55.387, -192.427));
				npcModule.Move.MoveToEnded:Wait(10);
				npcModule.Actions:Teleport(CFrame.new(2.737, 55.387, -192.427) * CFrame.Angles(0, math.rad(180), 0));

				Debugger:Warn("Play crouch look");
				npcModule.PlayAnimation("CrouchLook");
			end);

			table.insert(npcModule.CutsceneActions, function()
				Debugger:Log("Stand with player.");
				npcModule.PlayAnimation("CrouchPickUp");
			end);

			table.insert(npcModule.CutsceneActions, function()
				Debugger:Log("Handout")
				npcModule.Move:SetMoveSpeed("set", "default", 13);
				
				npcModule.Move:MoveTo(Vector3.new(-3.35487795, 55.2862129, -212.686417));
				npcModule.Move.MoveToEnded:Wait(4);
				
				npcModule.Actions:Teleport(CFrame.new(-3.35487795, 55.2862129, -212.686417));
				npcModule.Move:Face(classPlayer.RootPart);

				npcModule.PlayAnimation("Handout", 1.4);
			end);

			table.insert(npcModule.CutsceneActions, function()
				Debugger:Log("Guns out.");

				npcModule.StopAnimation("Handout", 0.5);

				npcModule.Wield.Equip("revolver454"); 
				pcall(function()
					npcModule.Wield.ToolModule.Configurations.MinBaseDamage = 25;
				end);

				npcModule.Move:Face(Vector3.new(4.431, 56.31, -166.753));
				npcModule.Move:SetMoveSpeed("set", "default", 0);

				npcModule.IsProtectingOwner = true;
				npcModule.Actions:ProtectOwner(function()
					return npcModule.IsProtectingOwner;
				end)
			end);

			table.insert(npcModule.CutsceneActions, function()
				Debugger:Log("Run to car");

				npcModule.Move:SetMoveSpeed("set", "default", 20);
				npcModule.Move:MoveTo(Vector3.new(-8.782, 55.3, -219.586));
			end);

			npcModule.NextAction = function(yield)
				local done = false;
				task.spawn(function()
					actionIndex = actionIndex +1;
					Debugger:Log("Next action : ", actionIndex);
					npcModule.CutsceneActions[actionIndex]();
					done = true;
				end)
				if yield == true then
					repeat 
						task.wait(0.5);
					until done == true;
				end
			end

		end, modNpc.NpcBaseModules.CutsceneHuman);

		masonNpcModule.SetAnimation("CrouchLook", {script.MasonAnimations.CrouchLookAnim});
		--masonNpcModule.SetAnimation("Running", {script.MasonAnimations.RunAnim});
		masonNpcModule.SetAnimation("Handout", {script.MasonAnimations.Handout});
		masonNpcModule.SetAnimation("CrouchPickUp", {script.MasonAnimations.CrouchPickUp});

		masonNpcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;

	end);
	
	CutsceneSequence:NewScene("studioLogo", function()
		TweenService:Create(studioLogo, TweenInfo.new(1), {ImageTransparency = 0;}):Play();
		task.wait(3.5);
		TweenService:Create(studioLogo, TweenInfo.new(1), {ImageTransparency = 1;}):Play();
		task.wait(1);
		modInterface:ToggleGameBlinds(true, 0);
	end);
	
	
	CutsceneSequence:NewScene("titleLogo", function()
		modInterface:ToggleGameBlinds(true, 0);
		
		TweenService:Create(titleLogo, TweenInfo.new(1), {ImageTransparency = 0;}):Play();
		task.wait(3.5);
		TweenService:Create(titleLogo, TweenInfo.new(1), {ImageTransparency = 1;}):Play();
		TweenService:Create(blurEffect, TweenInfo.new(3), {Size = 6;}):Play();
		TweenService:Create(musicTrack, TweenInfo.new(10), {Volume = 0.1;}):Play();
		
	end);

	local activeZombies, zombieNpcModule = {}, {};
	local disableSecondSpawner = true;
	
	CutsceneSequence:NewServerScene("MasonArrives", function()
		local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
		local missionLibrary = modMissionLibrary.Get(1);

		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local classPlayer = shared.modPlayers.Get(player);

		task.delay(3, function()
			masonNpcModule.Chat(player, sceneDialogues[1].Reply);
		end)

		masonNpcModule.NextAction(true);
		CutsceneSequence:Pause(18);
		
		masonNpcModule.Chat(player, sceneDialogues[2].Reply);
		CutsceneSequence:NextScene("UnconsciousWake");
		
		task.wait(1);
		CutsceneSequence:Pause(18);

		modMission:Progress(player, 1, function(mission)
			if mission.ProgressionPoint < 2 then mission.ProgressionPoint = 2; end;
		end)
		
		task.wait(1);
		masonNpcModule.NextAction();
		
		player.Character:SetAttribute("VisibleArms", true);
		CutsceneSequence:NextScene("playerWake");
		masonNpcModule.Chat(player, sceneDialogues[3].Reply);
		
		task.wait(2);
		CutsceneSequence:Pause(18);
		CutsceneSequence:NextScene("playerAllowMove");
		
		masonNpcModule.Chat(player, sceneDialogues[4].Reply);
		masonNpcModule.NextAction();

		task.wait(1.3);
		
		local item, storage = modStorage.FindItemIdFromStorages("p250", player);
		if item == nil then
			modMission:Progress(player, 1, function(mission)
				if mission.ProgressionPoint < 3 then mission.ProgressionPoint = 3; end;
			end)
			
			local rightHandAtt = masonPrefab:FindFirstChild("RightHandAttachment", true);
			local newPickup: BasePart = script:WaitForChild("Mission1Pickup"):Clone();
			local ridgidConst = newPickup:WaitForChild("RigidConstraint");
			newPickup.Parent = workspace.Interactables;
			ridgidConst.Attachment0 = rightHandAtt;
			ridgidConst.Parent = masonPrefab;
			
			local mission = modMission:GetMission(player, missionId);
			repeat
				task.wait(0.3);
				masonNpcModule.Move:Face(classPlayer.RootPart);
			until mission.ProgressionPoint == 4;

		else
			modMission:Progress(player, 1, function(mission)
				if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
			end)

		end
		
		local explosionSoundPart = workspace.Environment:WaitForChild("ExplosionSoundPart");
		modAudio.Play("HordeGrowl", explosionSoundPart);
		masonNpcModule.NextAction();

		masonNpcModule.Chat(players, sceneDialogues[5].Reply);
		
		task.wait(2);
		
		local endSpawnLoop = false;
		local zombieKilled = 0;

		local function loadZombies(zombiePrefab, npcModule)
			table.insert(activeZombies, zombiePrefab);
			table.insert(zombieNpcModule, npcModule);

			npcModule.SetAggression = 3;

			local moduleIndex = #zombieNpcModule;
			npcModule.Properties.TargetableDistance = 1024;
			npcModule.Configuration.Level = 0;
			
			npcModule.Move:SetMoveSpeed("set", "default", 16, 0);

			npcModule.Humanoid.Died:Connect(function()
				zombieKilled = zombieKilled +1;
				table.remove(zombieNpcModule, moduleIndex);
				if zombieKilled >= 5 then
					endSpawnLoop = true;
				end
				wait(2);
				Debugger.Expire(zombiePrefab, 0);
			end);

			task.spawn(function()
				npcModule.OnTarget(players);
				while wait(1) do
					if npcModule.Humanoid and npcModule.Humanoid.Health <= 0 then return end;
					npcModule.Properties.AttackDamage = math.random(2, 4);
					npcModule.OnTarget(players);

					if masonNpcModule.Target == nil then
						masonNpcModule.Target = zombiePrefab;
					end
				end
			end)
		end

		local function pickSpawn()
			return CFrame.new(math.random(0, 30), 63.273, -121.988);
		end

		CutsceneSequence:NextScene("onWeaponEquip");
		disableSecondSpawner = false;
		task.spawn(function()
			for a=1, 15 do
				if endSpawnLoop then break; else
					local zombiePrefab = modNpc.Spawn("Zombie", pickSpawn(), loadZombies);
					task.wait(4);
				end;
			end
			for a=1, 12 do
				if disableSecondSpawner then break; else
					local zombiePrefab = modNpc.Spawn("Zombie", pickSpawn(), loadZombies);
					task.wait(2);
				end;
			end
		end);
		for a=1, 60 do
			task.wait(1);
			if endSpawnLoop then break; end;
		end
	end);
	
	CutsceneSequence:NewScene("UnconsciousWake", function()
		playerAnimTracks.Unconscious:Stop();
		playerAnimTracks.UnconsciousWake:Play();

		local classPlayer = shared.modPlayers.Get(localPlayer);
		local head = classPlayer.Head;
		if head:FindFirstChild("unconsciousFace") then head.unconsciousFace:Destroy(); end
		if script:FindFirstChild("face") then script.face.Parent = head; end;
	end)
	
	CutsceneSequence:NewScene("playerWake", function()
		playerAnimTracks.UnconsciousWake:Stop();
		playerAnimTracks.CrouchPickUp:Play();
		
		TweenService:Create(blurEffect, TweenInfo.new(3), {Size = 3;}):Play();
		delay(3, function()
			blurEffect.Size = 2;
		end)
		
		local modCharacter = modData:GetModCharacter();
		local classPlayer = shared.modPlayers.Get(localPlayer);
		local rootPart = classPlayer.RootPart;
		modCharacter.CharacterProperties.FirstPersonCamCFrame = nil;
		
		rootPart.Anchored = false;
		rootPart.CFrame = CFrame.new(rootPart.CFrame.p); 
		--modCharacter.CharacterProperties.FirstPersonCamCFrame = CFrame.new(2.75, 58.1760025, -186.899994, 0.99984777, 4.69082266e-08, 0.0174524002, 0.00152099959, 0.996194899, -0.0871407166, -0.0173859969, 0.0871539935, 0.996043146);
		modConfigurations.Set("DisablePinnedMission", false);
	end);
	
	
	CutsceneSequence:NewScene("playerAllowMove", function()
		local modCharacter = modData:GetModCharacter();
		
		modCharacter.MouseProperties.CameraSmoothing = 0;
		modCharacter.CharacterProperties.CanSprint = true;
		modCharacter.CharacterProperties.DefaultWalkSpeed = 7;
		modCharacter.CharacterProperties.WalkingSpeed = 5;
		modCharacter.CharacterProperties.CrouchSpeed = 3;
		
		task.spawn(function()
			for a=0, 1, 0.5 do
				modCharacter.CharacterProperties.DefaultWalkSpeed = 7+(11*(a/1));
				modCharacter.CharacterProperties.WalkingSpeed = 5+(9*(a/1));
				modCharacter.CharacterProperties.CrouchSpeed = 3+(7*(a/1));
				wait(1);
			end
			modCharacter.CharacterProperties.DefaultWalkSpeed = 18;
			modCharacter.CharacterProperties.WalkingSpeed = 14;
			modCharacter.CharacterProperties.CrouchSpeed = 10;
		end)
		modCharacter.CharacterProperties.CanMove = true;
		modCharacter.CharacterProperties.CanInteract = true;
		modCharacter.CharacterProperties.FirstPersonCamCFrame = nil;
		modConfigurations.Set("DisablePinnedMission", false);
		modConfigurations.Set("DisableHotbar", false);
		modConfigurations.Set("CanQuickEquip", true);
	end);
	
	
	CutsceneSequence:NewScene("onWeaponEquip", function()
		modConfigurations.Set("DisableHealthbar", false);
	end);
	
	CutsceneSequence:NewServerScene("blowUpBridge", function()
		local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
		local missionLibrary = modMissionLibrary.Get(1);

		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		
		CutsceneSequence:NextScene("intensifyMusic");
		local explosionSoundPart = workspace.Environment:WaitForChild("ExplosionSoundPart");
		local originalBridge2 = workspace.Environment.Original;
		local newBridge2 = game.ServerStorage.DamagedBridge;
		local destructableA = workspace.Environment.Destrutable.A;
		local destructableB = workspace.Environment.Destrutable.B;
		local descA = destructableA:GetDescendants();
		destructableA.Delete:Destroy();
		local ExplosionPart = destructableA:FindFirstChild("ExplosionPart", true);
		local explosionEffect = Instance.new("Explosion");
		explosionEffect.BlastPressure = 600000;
		explosionEffect.BlastRadius = 48;
		explosionEffect.DestroyJointRadiusPercent = 0;
		local explosionLight = ExplosionPart:FindFirstChild("ExplosionLight", true);
		local OilPart1 = destructableA:FindFirstChild("OilPart1", true);
		local GasTankPart = destructableA:FindFirstChild("GasTankPart", true);
		local gasFire1 = GasTankPart:FindFirstChild("Fire1", true);
		local gasFire2 = GasTankPart:FindFirstChild("Fire2", true);
		explosionEffect.Position = GasTankPart.Position;
		modAudio.Play("Fire", OilPart1, true);
		gasFire1.Enabled = true;
		gasFire2.Enabled = true;
		modAudio.Play("Fire", GasTankPart, true);
		wait(3);
		masonNpcModule.Chat(players, sceneDialogues[6].Reply);
		masonNpcModule.IsProtectingOwner = false;
		masonNpcModule.NextAction();
		wait(1);
		workspace.Environment.CarSeat:Sit(masonNpcModule.Humanoid);
		wait(6);
		disableSecondSpawner = true;
		originalBridge2:Destroy();
		newBridge2.Parent = workspace.Environment;
		TweenService:Create(explosionLight, TweenInfo.new(0.2), {Range = 100;}):Play();
		modAudio.Play("VechicleExplosion", explosionSoundPart);
		modAudio.Play("Explosion4", explosionSoundPart);

		for a=#activeZombies, 1, -1 do
			if activeZombies[a] ~= nil and activeZombies[a]:IsDescendantOf(workspace.Entity) then
				local zombieHumanoid = activeZombies[a]:FindFirstChildWhichIsA("Humanoid");
				if zombieHumanoid and zombieHumanoid.Name == "Zombie" and zombieHumanoid.Health > 0 then
					zombieHumanoid.Health = 0;
				end
			end
		end
		
		explosionEffect.Hit:Connect(function(basePart)
			if (basePart:IsDescendantOf(destructableA) or basePart:IsDescendantOf(destructableB)) then
				local sizeMag = basePart.Size.Magnitude;
				if sizeMag > 10 then
					local f = Instance.new("Fire");
					f.Size = math.random(5, sizeMag);
					f.Heat = math.random(5, sizeMag);
					f.Parent = basePart;
				end
			end
		end)
		for _, c in pairs(descA) do
			if c:IsA("BasePart") then
				c.Anchored = false;
			end;
		end;
		masonNpcModule.Chat(players, sceneDialogues[7].Reply);
		explosionEffect.Parent = GasTankPart;
		task.spawn(function() CutsceneSequence.NextScene(CutsceneSequence, "camShake"); end)

		shared.EquipmentSystem.ToolHandler(player, "unequip");
		TweenService:Create(explosionLight, TweenInfo.new(3), {Range = 0;}):Play();
		wait(5);

		for _, player in pairs(game.Players:GetPlayers()) do
			local char = player.Character;
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.Health = 10;
			end
			if not playerDied then
				modMission:CompleteMission(player, 1);
				modMission:StartMission(player, 2);

				modServerManager:Travel(player, "TheWarehouse");
			else
				modServerManager:Teleport(player, "TheBeginning");
			end
		end
	end);

	CutsceneSequence:NewScene("intensifyMusic", function()
		musicTrack:Stop();
		musicTrack.TimePosition = 133;
		musicTrack:Resume()
		TweenService:Create(musicTrack, TweenInfo.new(3), {Volume = 1;}):Play();
		delay(13, function()
			TweenService:Create(musicTrack, TweenInfo.new(5), {Volume = 0.1;}):Play();
		end)
	end)

	CutsceneSequence:NewScene("camShake", function()
		local modCharacter = modData:GetModCharacter();
		
		playerAnimTracks.Unconscious:Play();
		
		modConfigurations.Set("DisablePinnedMission", true);
		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("CanQuickEquip", false);
		modCharacter.CameraShakeAndZoom(20, 5, 3, 0.01, true);
		
		bloomEffect.Enabled = true;
		TweenService:Create(blurEffect, TweenInfo.new(0.4), {Size = 20;}):Play();
		TweenService:Create(bloomEffect, TweenInfo.new(0.1), {Intensity = 1; Size=30;}):Play();

		modInterface:ToggleGameBlinds(false, 9);
		
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanInteract = false;
		modCharacter.MouseProperties.CameraSmoothing = 0.1;
	end);
	
	
	return CutsceneSequence;
end;