local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--== Variables;
local MISSION_ID = 1;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
	modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	shared.modEventService:OnInvoked("Players_BindWieldEvent", function(event: EventPacket, ...)
		local action: string, toolHandler: ToolHandlerInstance = ...;

		local playerClass: PlayerClass = toolHandler.CharacterClass :: PlayerClass;
		local player: Player = (playerClass :: PlayerClass):GetInstance();

		if action == "Equip" then
			local mission1 = modMission:GetMission(player, MISSION_ID);
			if mission1 == nil or mission1.Type ~= 1 then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 5 then 
					mission.ProgressionPoint = 5; 
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission1_EquipPistol;
					};
				end;
			end)
		end
	end)
	
	shared.modEventService:OnInvoked("Generic_BindItemPickup", function(
		event: EventPacket, 
		interactData, 
		storageItem: StorageItem
	)
		local player: Player? = event.Player;
		if player == nil then return end;
		
		task.spawn(function()
			if storageItem == nil then return end;
			if storageItem.ItemId ~= "p250" then return end;
			
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint >= 4 then return end;
				
				mission.ProgressionPoint = 4; 
				modAnalyticsService:LogOnBoarding{
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission1_TakePistol;
				};
			end)
		end)
	end)

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
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

	
	local studioLogo, titleLogo, blurEffect, bloomEffect, musicTrack;

	if modData then
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

		modAudio.Preload("MainTheme", 5);
		musicTrack = modAudio.Get("MainTheme");
		if musicTrack then
			musicTrack.Volume = 0;
			musicTrack:Play();
			TweenService:Create(musicTrack, TweenInfo.new(30), {Volume = 0.45;}):Play();
		end

		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableMapMenu", true);
		modConfigurations.Set("CanQuickEquip", false);
		modConfigurations.Set("ShowNameDisplays", false);
	end
	
	--== Server

	local sceneRunning = false;
	CutsceneSequence:Initialize(function()
		if sceneRunning then Debugger:Log("Scene already running.."); return end;
		sceneRunning = true;

		game.Lighting:SetAttribute("FogEnd", 250);
		pcall(function() game.Players.RespawnTime = 60; end);
		
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		
		local item, storage = modStorage.FindItemIdFromStorages("p250", player);
		if item ~= nil then
			storage:DeleteValues(item.ID, {"A"; "MA"});
		end
		
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		if mission.Type == 2 then
			modMission:StartMission(player, MISSION_ID);
		end

		local playerClass = shared.modPlayers.get(player);
		playerClass:Spawn();
		playerClass:SetCFrame(CFrame.new(3.6, 55.376, -188.5))
		
		Debugger:Log("Scene playerSpawns", debug.traceback());
		CutsceneSequence:NextScene("playerSpawns");
		task.wait(5);
		
		Debugger:Log("Scene spawnFriend");
		CutsceneSequence:NextScene("spawnFriend");
		
		Debugger:Log("Scene studioLogo");
		CutsceneSequence:NextScene("studioLogo");
		
		task.wait(5);
		
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
		
		modClientGuis.toggleGameBlinds(false, 0);
		
		game:GetService("StarterGui"):SetCore("ResetButtonCallback", false);
		modData.ToggleChat();

		local modCharacter = modData:GetModCharacter();
		repeat
			modCharacter = modData:GetModCharacter();
			Debugger:Log("Waiting for character module..");
			wait(0.1);
		until modCharacter ~= nil;

		local playerClass = shared.modPlayers.get(localPlayer);
		local rootPart = playerClass.RootPart;
		local humanoid = playerClass.Humanoid;
		local head = playerClass.Head;
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
		
		playerAnimTracks.Unconscious:Play();

		local activeInterface: InterfaceInstance = modClientGuis.ActiveInterface;
		if activeInterface then
			activeInterface.Properties.AimPointerVisible = false;
		end

		task.wait(5);
		
		modClientGuis.toggleGameBlinds(true, 15);
		
		TweenService:Create(blurEffect, TweenInfo.new(10), {Size = 15;}):Play();
		game.Lighting:SetAttribute("FogStart", 40);
		game.Lighting:SetAttribute("FogEnd", 250);

		task.wait(6);
		task.spawn(function()
			if CutsceneSequence.QualityLevel > 6 then
				repeat
					modCharacter.MouseProperties.CameraSmoothing = modCharacter.MouseProperties.CameraSmoothing +0.002;
				until modCharacter.MouseProperties.CameraSmoothing > 0.2 or not task.wait(1/10);
			else
				task.wait(10);
			end
			
			modCharacter.MouseProperties.CameraSmoothing = 0;
			modClientGuis.toggleGameBlinds(true, 0);
		end);

		local bloomTween = TweenService:Create(bloomEffect, TweenInfo.new(6), {Intensity = 0; Size=0;});
		bloomTween.Completed:Connect(function() bloomEffect.Enabled = false; end);
		bloomTween:Play();
		
		modData.ToggleChat();
	end);
	
	local playerDied = false;
	local masonPrefab, masonNpcClass;
	CutsceneSequence:NewServerScene("spawnFriend", function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.HealthComp.CurHealth = playerClass.HealthComp.MaxHealth;

		playerClass.CharacterGarbage:Tag(playerClass.OnIsDeadChanged:Connect(function(isDead)
			if isDead then return end;
			playerDied = true;
			modServerManager:Teleport(player, "TheBeginning");
		end))
		modMission:Progress(player, MISSION_ID, function(mission)
			mission.ProgressionPoint = 1;
		end)

		Debugger:Log("Spawn mason");
		
		masonNpcClass = modNpcs.spawn2({
			Name = "Mason";
			CFrame = CFrame.new(-1.22, 55.46, -287.322);
			Player = player;
			AddComponents = {};
		});
		masonPrefab = masonNpcClass.Character;
		
		local actionIndex = 0;
		local cutsceneActions = {};

		masonNpcClass.Properties.CutsceneActive = true;
		masonNpcClass.CutsceneActions = cutsceneActions;
		masonNpcClass.Garbage:Tag(cutsceneActions);

		table.insert(masonNpcClass.CutsceneActions, function()
			Debugger:Log("Run to player.");

			masonNpcClass.Move:SetMoveSpeed("set", "default", 18);
			masonNpcClass:ToggleInteractable(false);
			
			masonNpcClass.Move:MoveTo(Vector3.new(2.737, 55.387, -192.427));
			masonNpcClass.Move.OnMoveToEnded:Wait(10);
			masonNpcClass:SetCFrame(CFrame.new(2.737, 55.387, -192.427) * CFrame.Angles(0, math.rad(180), 0));

			Debugger:Warn("Play crouch look");
			masonNpcClass.PlayAnimation("CrouchLook");
		end);

		table.insert(masonNpcClass.CutsceneActions, function()
			Debugger:Log("Stand with player.");
			masonNpcClass.PlayAnimation("CrouchPickUp");
		end);

		table.insert(masonNpcClass.CutsceneActions, function()
			Debugger:Log("Handout")
			masonNpcClass.Move:SetMoveSpeed("set", "default", 13);
			
			masonNpcClass.Move:MoveTo(Vector3.new(-3.35487795, 55.2862129, -212.686417));
			masonNpcClass.Move.OnMoveToEnded:Wait(4);
			
			masonNpcClass:SetCFrame(CFrame.new(-3.35487795, 55.2862129, -212.686417));
			masonNpcClass.Move:Face(playerClass.RootPart);

			masonNpcClass.PlayAnimation("Handout", 1.4);
		end);

		table.insert(masonNpcClass.CutsceneActions, function()
			Debugger:Log("Guns out.");

			masonNpcClass.StopAnimation("Handout", 0.5);

			masonNpcClass.WieldComp:Equip({
				ItemId = "revolver454";
				OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
					if toolHandler.EquipmentClass == nil then return end;
					local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

					local modifier: ConfigModifier = equipmentClass.Configurations.newModifier("npcDmg");
					modifier.SetValues.Damage = 20;
					modifier.Priority = 999;
					equipmentClass.Configurations:AddModifier(modifier, true);
				end;
			});

			masonNpcClass.Move:Face(Vector3.new(4.431, 56.31, -166.753));
			masonNpcClass.Move:SetMoveSpeed("set", "default", 0);

			masonNpcClass:GetComponent("ProtectPlayer")();
		end);

		table.insert(masonNpcClass.CutsceneActions, function()
			Debugger:Log("Run to car");

			masonNpcClass.Move:SetMoveSpeed("set", "default", 20);
			masonNpcClass.Move:MoveTo(Vector3.new(-8.782, 55.3, -219.586));
		end);

		masonNpcClass.NextAction = function(yield)
			local done = false;
			task.spawn(function()
				actionIndex = actionIndex +1;
				Debugger:Log("Next action : ", actionIndex);
				masonNpcClass.CutsceneActions[actionIndex]();
				done = true;
			end)
			if yield == true then
				repeat 
					task.wait(0.5);
				until done == true;
			end
		end

		masonNpcClass.SetAnimation("CrouchLook", {script.MasonAnimations.CrouchLookAnim});
		masonNpcClass.SetAnimation("Handout", {script.MasonAnimations.Handout});
		masonNpcClass.SetAnimation("CrouchPickUp", {script.MasonAnimations.CrouchPickUp});

		masonNpcClass.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
	end);
	
	CutsceneSequence:NewScene("studioLogo", function()
		local activeInterface: InterfaceInstance = modClientGuis.ActiveInterface;

		local cutsceneFrame = script:WaitForChild("Cutscene"):Clone();
		cutsceneFrame.Parent = activeInterface.ScreenGui;

		studioLogo = cutsceneFrame:WaitForChild("StudioLogo");
		titleLogo = cutsceneFrame:WaitForChild("TitleLogo");

		TweenService:Create(studioLogo, TweenInfo.new(1), {ImageTransparency = 0;}):Play();
		task.wait(3.5);
		TweenService:Create(studioLogo, TweenInfo.new(1), {ImageTransparency = 1;}):Play();
		task.wait(1);
		
		modClientGuis.toggleGameBlinds(true, 0);
	end);
	
	
	CutsceneSequence:NewScene("titleLogo", function()
		modClientGuis.toggleGameBlinds(true, 0);
		
		TweenService:Create(titleLogo, TweenInfo.new(1), {ImageTransparency = 0;}):Play();
		task.wait(3.5);
		TweenService:Create(titleLogo, TweenInfo.new(1), {ImageTransparency = 1;}):Play();
		TweenService:Create(blurEffect, TweenInfo.new(3), {Size = 6;}):Play();
		if musicTrack then
			TweenService:Create(musicTrack, TweenInfo.new(10), {Volume = 0.1;}):Play();
		end
		
	end);

	local zombieNpcClasses = {};
	local disableSecondSpawner = true;
	
	CutsceneSequence:NewServerScene("MasonArrives", function()

		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local playerClass = shared.modPlayers.get(player);

		task.delay(3, function()
			masonNpcClass.Chat(player, sceneDialogues[1].Reply);
		end)

		masonNpcClass.NextAction(true);
		CutsceneSequence:Pause(18);
		
		masonNpcClass.Chat(player, sceneDialogues[2].Reply);
		CutsceneSequence:NextScene("UnconsciousWake");
		
		task.wait(1);
		CutsceneSequence:Pause(18);

		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint < 2 then 
				mission.ProgressionPoint = 2; 
				modAnalyticsService:LogOnBoarding{
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission1_WakeUp;
				};
			end;
		end)
		
		task.wait(1);
		masonNpcClass.NextAction();
		
		playerClass.Character:SetAttribute("VisibleArms", true);
		CutsceneSequence:NextScene("playerWake");
		masonNpcClass.Chat(player, sceneDialogues[3].Reply);
		
		task.wait(2);
		CutsceneSequence:Pause(18);
		CutsceneSequence:NextScene("playerAllowMove");
		
		masonNpcClass.Chat(player, sceneDialogues[4].Reply);
		masonNpcClass.NextAction();

		task.wait(1.3);
		
		local item, _storage = modStorage.FindItemIdFromStorages("p250", player);
		if item == nil then
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 3 then mission.ProgressionPoint = 3; end;
			end)
			
			local rightHandAtt = masonPrefab:FindFirstChild("RightHandAttachment", true);
			local newPickup: BasePart = script:WaitForChild("Mission1Pickup"):Clone();

			local ridgidConst = newPickup:WaitForChild("RigidConstraint");
			local dropGlow = newPickup:WaitForChild("DropGui");
			dropGlow.Enabled = true;
			newPickup.Parent = workspace.Interactables;

			ridgidConst.Attachment0 = rightHandAtt;
			ridgidConst.Parent = masonPrefab;
			
			local mission = modMission:GetMission(player, MISSION_ID);
			repeat
				task.wait(0.1);
				masonNpcClass.Move:Face(playerClass.RootPart);
			until mission.ProgressionPoint == 4;

		else
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
			end)

		end
		
		local explosionSoundPart = workspace.Environment:WaitForChild("ExplosionSoundPart");
		modAudio.Play("HordeGrowl", explosionSoundPart);
		masonNpcClass.NextAction();

		masonNpcClass.Chat(players, sceneDialogues[5].Reply);
		
		task.wait(2);
		
		local endSpawnLoop = false;
		local zombieKilled = 0;

		local function loadZombies(npcClass: NpcClass)
			table.insert(zombieNpcClasses, npcClass);

			local npcChar = npcClass.Character;
			local properties = npcClass.Properties;

			properties.Level = 0;
			properties.HordeAggression = true;
			properties.TargetableDistance = 1024;
			properties.CanForgetTargets = false;
			properties.DropRewardId = nil;

			npcClass.Move:SetMoveSpeed("set", "forcespeed", 6, 9);

			npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
				if not isDead then return end;

				zombieKilled = zombieKilled +1;
				for a=#zombieNpcClasses, 1, -1 do
					if zombieNpcClasses[a] == npcClass then
						table.remove(zombieNpcClasses, a);
					end
				end
				if zombieKilled >= 5 then
					endSpawnLoop = true;
				end
			end)
			
			task.spawn(function()
				local targetHandlerComp = npcClass:GetComponent("TargetHandler");
				targetHandlerComp:AddTarget(masonPrefab);
				targetHandlerComp:AddTarget(playerClass.Character);
			end)
			task.spawn(function()
				npcClass.Move:MoveTo(masonPrefab:GetPivot().Position);
			end)
			task.spawn(function()
				while not npcClass.HealthComp.IsDead do
					task.wait(1);
					npcClass.OnThink:Fire();
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
				if endSpawnLoop then
					break;
				else
					shared.modNpcs.spawn2{
						Name = "Zombie";
						CFrame = pickSpawn();
						BindSetup = loadZombies;
					};
					task.wait(4);
				end;
			end
			for a=1, 12 do
				if disableSecondSpawner then
					break;
				else
					shared.modNpcs.spawn2{
						Name = "Zombie";
						CFrame = pickSpawn();
						BindSetup = loadZombies;
					};
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
		if playerAnimTracks.Unconscious then playerAnimTracks.Unconscious:Stop(); end
		if playerAnimTracks.UnconsciousWake then playerAnimTracks.UnconsciousWake:Play(); end

		local playerClass = shared.modPlayers.get(localPlayer);
		local head = playerClass.Head;
		if head:FindFirstChild("unconsciousFace") then head.unconsciousFace:Destroy(); end
		if script:FindFirstChild("face") then script.face.Parent = head; end;
	end)
	
	CutsceneSequence:NewScene("playerWake", function()
		if playerAnimTracks.UnconsciousWake then playerAnimTracks.UnconsciousWake:Stop(); end
		if playerAnimTracks.CrouchPickUp then playerAnimTracks.CrouchPickUp:Play(); end
		
		TweenService:Create(blurEffect, TweenInfo.new(3), {Size = 3;}):Play();
		delay(3, function()
			blurEffect.Size = 2;
		end)
		
		local modCharacter = modData:GetModCharacter();
		local classPlayer = shared.modPlayers.get(localPlayer);
		local rootPart = classPlayer.RootPart;
		modCharacter.CharacterProperties.FirstPersonCamCFrame = nil;
		
		rootPart.Anchored = false;
		rootPart.CFrame = CFrame.new(rootPart.CFrame.p); 

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
		modConfigurations.Set("DisableInventory", false);
		modConfigurations.Set("CanQuickEquip", true);
		
		local activeInterface: InterfaceInstance = modClientGuis.ActiveInterface;
		if activeInterface then
			activeInterface.Properties.AimPointerVisible = true;
		end
	end);
	
	
	CutsceneSequence:NewScene("onWeaponEquip", function()
		modConfigurations.Set("DisableHealthbar", false);
	end);
	
	CutsceneSequence:NewServerScene("blowUpBridge", function()

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
		masonNpcClass.Chat(players, sceneDialogues[6].Reply);
		masonNpcClass:GetComponent("ProtectPlayer").IsProtecting = false;
		masonNpcClass.NextAction();
		wait(1);
		workspace.Environment.CarSeat:Sit(masonNpcClass.Humanoid);
		task.wait(3);
		disableSecondSpawner = true;
		task.wait(3);
		originalBridge2:Destroy();
		newBridge2.Parent = workspace.Environment;
		TweenService:Create(explosionLight, TweenInfo.new(0.2), {Range = 100;}):Play();
		modAudio.Play("VechicleExplosion", explosionSoundPart);
		modAudio.Play("Explosion4", explosionSoundPart);

		for a=#zombieNpcClasses, 1, -1 do
			local zombieNpcClass: NpcClass = zombieNpcClasses[a];

			zombieNpcClass.HealthComp:TakeDamage(DamageData.new{
				Damage = 10000;
				DamageType = "Explosive";
				DamageCate = DamageData.DamageCategory.ExplosiveBarrel;
			});
			zombieNpcClass.HealthComp:SetIsDead(true);
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
		masonNpcClass.Chat(players, sceneDialogues[7].Reply);
		explosionEffect.Parent = GasTankPart;
		task.spawn(function() CutsceneSequence.NextScene(CutsceneSequence, "camShake"); end)

		local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.WieldComp:Unequip();

		TweenService:Create(explosionLight, TweenInfo.new(3), {Range = 0;}):Play();
		wait(5);

		local char = player.Character;
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.Health = 10;
		end
		if not playerDied then
			modMission:CompleteMission(player, MISSION_ID);
			modAnalyticsService:LogOnBoarding{
				Player=player;
				OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission1_Complete;
			};

			modServerManager:Travel(player, "TheWarehouse");
		else
			modServerManager:Teleport(player, "TheBeginning");
		end
	end);

	CutsceneSequence:NewScene("intensifyMusic", function()
		if musicTrack == nil then return end;
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
		
		if playerAnimTracks.Unconscious then playerAnimTracks.Unconscious:Play(); end
		
		modConfigurations.Set("DisablePinnedMission", true);
		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("CanQuickEquip", false);
		modCharacter.CameraShakeAndZoom(20, 5, 3, 0.01, true);
		
		bloomEffect.Enabled = true;
		TweenService:Create(blurEffect, TweenInfo.new(0.4), {Size = 20;}):Play();
		TweenService:Create(bloomEffect, TweenInfo.new(0.1), {Intensity = 1; Size=30;}):Play();

		modClientGuis.toggleGameBlinds(false, 9);
		
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanInteract = false;
		modCharacter.MouseProperties.CameraSmoothing = 0.1;
	end);
	
	
	return CutsceneSequence;
end;