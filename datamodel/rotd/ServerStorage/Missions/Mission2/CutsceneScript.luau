local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

--== Variables;
local MISSION_ID = 2;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
	modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	if modBranchConfigs.IsWorld("TheWarehouse") then
		local function onDoorEnter(eventPacket: EventPacket, interactable: InteractableInstance)
			local player = eventPacket.Player;
			Debugger:Warn(`onDoorEnter.`, player);
			if player == nil then return end;

			if interactable.Id == "bedroomdoorMain" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint < 3 then
						mission.ProgressionPoint = 3;

						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_ExitBedroom;
						};
					end;
				end)

			elseif interactable.Id == "warehouseExit" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 8 then
						mission.ProgressionPoint = 9;
					end;
				end)

			end
		end
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", onDoorEnter);


		local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
		shared.modEventService:OnInvoked("Npcs_BindDamaged", function(event: EventPacket, damageData: DamageData)
			local damageTo: CharacterClass? = damageData.DamageTo;
			if damageTo == nil then return end;
			if damageTo.HumanoidType ~= "Zombie" then return end;

			local playerTags = modDamageTag:Get(damageTo.Character, "Player");
			for _, playerTag in pairs(playerTags) do
				local player = playerTag.Player;
				
				if modMission:IsComplete(player, MISSION_ID) then continue end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint ~= 9 then return end;

					mission.SaveData.Kills = mission.SaveData.Kills -1;
					if mission.SaveData.Kills > 0 then return end;

					mission.ProgressionPoint = 10;

					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_KillTenZombies;
					};
				end)
				
			end
		end)
		
		
		shared.modEventService:OnInvoked("Shop_BindActionEvent", function(event: EventPacket, ...)
			local action: string, packet: anydict = ...;
			local player = event.Player;
			if player == nil then return end;
			
			if action == "BuyAmmo" then
				local storageItem = packet.StorageItem;
				local cost = packet.Cost;

				if not modMission:Progress(player, MISSION_ID) then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					local m2restorepointEvent = modEvents:GetEvent(player, "m2restorepoint");
					if mission.ProgressionPoint < 7 then
						mission.ProgressionPoint = 7;
						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_PurchaseAmmo;
						};

					elseif m2restorepointEvent then
						mission.ProgressionPoint = m2restorepointEvent.Point;
						modEvents:RemoveEvent(player, "m2restorepoint");
					end;
				end)
			end
		end)
		
		shared.modEventService:OnInvoked("Dialogue_BindMedicHeal", function(event: EventPacket, ...)
			local player: Player, dialog = ...;
			if not modMission:Progress(player, MISSION_ID) then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint < 4 then
					mission.ProgressionPoint = 4;
	
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_DrDeniskiHeal;
					};
				end;
			end)
		end)
		
	end

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;

		local playerClass: PlayerClass = shared.modPlayers.get(player);
		
		local masonNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Mason");
		if masonNpcClass == nil then
			masonNpcClass = modNpcs.spawn2({
				Name = "Mason";
				CFrame = CFrame.new(-1.22, 55.46, -287.322);
				Player = player;
			});
			modReplicationManager.ReplicateOut(player, masonNpcClass.Character);
			Debugger:Warn(`Spawn Mason`);
		end

		if not modMission:IsComplete(player, 1) then
			modMission:CompleteMission(player, 1);
		end
		if modMission:IsAvailable(player, 2) then
			modMission:StartMission(player, 2);
		end
		
		pcall(function()
			local item = modStorage.FindItemIdFromStorages("p250", player);
			if item == nil and modEvents:GetEvent(player, "hasBeginnerP250") == nil then
				local profile = shared.modProfile:Get(player);
				local activeInventory = profile.ActiveInventory;
				activeInventory:Add("p250");

			end
			modEvents:NewEvent(player, {Id="hasBeginnerP250"});
		end);
		

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				modMission:StartMission(player, 2);
				
			elseif mission.Type == 1 then -- OnActive
				masonNpcClass.Properties.CutsceneActive = true;
				
				if mission.ProgressionPoint == 1 then
					for a=1, 5 do
						playerClass:SetCFrame(CFrame.new(-20.8, 59.7, -40.4, -0.09, 0, -0.99, 0, 1, 0, 1, 0, -0.09));
						if player:DistanceFromCharacter(Vector3.new(-20.8, 59.7, -40.4)) <= 16 then
							break;
						else
							task.wait(1);
						end
					end
					
					CutsceneSequence:NextScene("onPlayerSpawns");
					CutsceneSequence:Pause(20);
					
					task.delay(1, function()
						masonNpcClass.PlayAnimation("Lean");
						masonNpcClass:SetCFrame(CFrame.new(-16.8199978, 57.6597404, -23.8900318, 1, 0, 0, 0, 1, 0, 0, 0, 1));
					end)
					
					task.delay(1, function()
						playerClass:SetCFrame(CFrame.new(-19.9, 57.6, -35.95, -0.99, 0, 0.037, 0, 1, 0, -0.037, 0, -0.99));
					end)
					
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_WakeUp;
					};

					CutsceneSequence:NextScene("wakeUp");

				elseif mission.ProgressionPoint == 2 then
					CutsceneSequence:NextScene("enableInterfaces");

					masonNpcClass.StopAnimation("Lean");
					
					masonNpcClass:ToggleInteractable(false);
					masonNpcClass.Move:SetMoveSpeed("set", "default", 10);
					
					task.wait(2);

					if mission.ProgressionPoint >= 4 then return end;
					
					masonNpcClass.Chat(masonNpcClass.Player, "Follow me...");
					masonNpcClass.Move:Face(Vector3.new(-0.619997144, 57.6597404, -25.171896));
			
					wait(0.1);

					if mission.ProgressionPoint >= 4 then return end;
							
					masonNpcClass.Move:MoveTo(Vector3.new(-5.81999636, 57.6597404, -24.2718925));
					masonNpcClass.Move.OnMoveToEnded:Wait(2);
					wait(0.2);

					if mission.ProgressionPoint >= 4 then return end;

					masonNpcClass.Move:Face(Vector3.new(-5.81999636, 57.6597404, -20.3718967));
					wait(0.5);

					if mission.ProgressionPoint >= 4 then return end;

					masonNpcClass:UseInteractable("bedroomdoorMain");
					wait(0.5);
					
					masonNpcClass.Move:MoveTo(Vector3.new(16.5800056, 57.6597404, -32.6719055));
					masonNpcClass.Move.OnMoveToEnded:Wait(3);

					if mission.ProgressionPoint >= 4 then return end;
					masonNpcClass.Move:Face(Vector3.new(10.5800047, 57.6597404, -28.6719055));
					
					masonNpcClass.Chat(masonNpcClass.Player, "Talk to Dr. Deniski");
					masonNpcClass:ToggleInteractable(true);

				elseif mission.ProgressionPoint == 3 then
					CutsceneSequence:NextScene("enableInterfaces");

				elseif mission.ProgressionPoint == 4 then
					
					masonNpcClass:SetCFrame(CFrame.new(15.9152822, 57.6004868, -31.9428711, -0.521899104, 0, 0.853007257, 0, 1, 0, -0.853007257, 0, -0.521899104));
					masonNpcClass.Move:Face(playerClass:GetCFrame().Position);
					masonNpcClass:ToggleInteractable(true);

				elseif mission.ProgressionPoint == 5 then
					masonNpcClass.StopAnimation("Lean");
					task.wait(2);

					masonNpcClass.Chat(masonNpcClass.Player, "I'll go and try to repair the car now..");
					masonNpcClass.Move:SetMoveSpeed("set", "default", 10);
					
					task.wait(1);
					masonNpcClass:ToggleInteractable(true);
					masonNpcClass.Move:MoveTo(Vector3.new(51.2800293, 57.6597404, 40.0281067));
					
					masonNpcClass.Properties.CutsceneActive = false;

				elseif mission.ProgressionPoint == 6 then
					local p250StorageItem = modStorage.FindItemIdFromStorages("p250", player);
					if p250StorageItem then
						p250StorageItem:SetValues("A", 0);
						p250StorageItem:Sync({"A"});
					end
				end
				
			elseif mission.Type == 3 then -- OnComplete
				masonNpcClass.Properties.CutsceneActive = false;
				masonNpcClass:SetCFrame(CFrame.new(15.9152822, 57.6004868, -31.9428711, -0.521899104, 0, 0.853007257, 0, 1, 0, -0.853007257, 0, -0.521899104));
				masonNpcClass.StopAnimation("Lean", 0.5);

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	local blurEffect, wakeAnimation;
	CutsceneSequence:NewScene("onPlayerSpawns", function()
		local modCharacter = modData:GetModCharacter();

		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local rootPart = playerClass.RootPart;
		local humanoid = playerClass.Humanoid;
		local head = playerClass.Head;
		local camera = workspace.CurrentCamera;

		blurEffect = Instance.new("BlurEffect");
		blurEffect.Name = "CutsceneBlur";
		blurEffect.Size = 100;
		blurEffect.Parent = camera;

		rootPart.CFrame = CFrame.new(-20.8, 59.7, -40.4, -0.09, 0, -0.99, 0, 1, 0, 1, 0, -0.09);
		modClientGuis.toggleGameBlinds(false, 0);

		local unconsciousFace = head:FindFirstChild("face")
		if unconsciousFace then
			unconsciousFace = unconsciousFace:Clone();
			head.face.Parent = script;
			unconsciousFace.Parent = head;
			unconsciousFace.Texture = "rbxassetid://2255073000";
		end
		

		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("DisableInventory", true);
		modConfigurations.Set("DisableHealthbar", true);
		modConfigurations.Set("DisableWorkbench", true);
		modConfigurations.Set("DisableExperiencebar", true);
		modConfigurations.Set("DisableGeneralStats", true);
		modConfigurations.Set("DisableHotbar", true);
		modConfigurations.Set("CanQuickEquip", false);
		modConfigurations.Set("DisableSquadInterface", true);
		modConfigurations.Set("DisableMasteryMenu", true);

		local unconsciousAnimation = humanoid:LoadAnimation(script:WaitForChild("Unconscious"));
		wakeAnimation = humanoid:LoadAnimation(script:WaitForChild("Wake"));
		
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanInteract = false;
		modCharacter.MouseProperties.CameraSmoothing = 0.02;
		modCharacter.CharacterProperties.FirstPersonCamCFrame = CFrame.new(-23.2607307, 58.3400955, -40.5012398, 0, -0.559190929, -0.829038858, 0, 0.829038858, -0.559190929, 1, 0, 0);
		rootPart.Anchored = true;
		
		if unconsciousAnimation then
			unconsciousAnimation:Play();
		end
		task.wait(1);
		modClientGuis.toggleGameBlinds(false, 0);
		task.wait(2);
		modClientGuis.toggleGameBlinds(true, 10);
		
		TweenService:Create(blurEffect, TweenInfo.new(10), {Size = 10;}):Play();
		wait(5);
		local smoothValueTag = Instance.new("NumberValue");
		smoothValueTag:GetPropertyChangedSignal("Value"):Connect(function()
			RunService.Heartbeat:Wait();
			modCharacter.MouseProperties.CameraSmoothing = smoothValueTag.Value;
		end)
		TweenService:Create(smoothValueTag, TweenInfo.new(10), {Value = 1;}):Play();
		wait(3);
		modCharacter.MouseProperties.CameraSmoothing = 0;
	end);

	CutsceneSequence:NewScene("wakeUp", function()
		local modCharacter = modData:GetModCharacter();

		local classPlayer = shared.modPlayers.get(localPlayer);
		local rootPart = classPlayer.RootPart;
		local head = classPlayer.Head;
		
		local unconsciousAnimation = modCharacter:GetAnimation("Unconscious");

		modClientGuis.toggleGameBlinds(false, 1);
		task.wait(3.5);
		
		if head:FindFirstChild("face") then head.face:Destroy(); end
		if script:FindFirstChild("face") then script.face.Parent = head; end
		if unconsciousAnimation then
			unconsciousAnimation:Stop();
		end
		
		rootPart.CFrame = CFrame.new(-20.0200005, 57.6597404, -36.5718994, -1, 0, 0, 0, 1, 0, 0, 0, -1);
		wakeAnimation:Play();
		wakeAnimation:AdjustSpeed(0);
		modClientGuis.toggleGameBlinds(true, 2);
		
		wait(0.25);
		wakeAnimation:AdjustSpeed(0.8);
		modCharacter.CharacterProperties.FirstPersonCamCFrame = nil;
		blurEffect:Destroy();
		for _, obj in pairs(workspace.CurrentCamera:GetChildren()) do
			if obj.Name == "CutsceneBlur" then
				obj:Destroy();
			end
		end
		wait(5);
		modConfigurations.Set("DisableWaypointers", false);
		modCharacter.CharacterProperties.CanMove = true;
		modCharacter.CharacterProperties.CanInteract = true;
		rootPart.Anchored = false;
		wakeAnimation:Stop();

		spawn(function()
			local unconsciousAnimation = nil;
			for a=1, 10 do
				unconsciousAnimation = modCharacter:GetAnimation("Unconscious");
				if unconsciousAnimation then
					unconsciousAnimation:Stop();
				else
					break;
				end
			end
		end)
	end)

	CutsceneSequence:NewScene("enableInterfaces", function()
		for _, obj in pairs(workspace.CurrentCamera:GetChildren()) do
			if obj.Name == "CutsceneBlur" then
				obj:Destroy();
			end
		end
		modConfigurations.Set("DisableWaypointers", false);
		modConfigurations.Set("DisableHotbar", false);
		modConfigurations.Set("DisableInventory", false);
		modConfigurations.Set("DisableWorkbench", false);
		modConfigurations.Set("DisableHealthbar", false);
		modConfigurations.Set("DisableExperiencebar", false);
		modConfigurations.Set("DisableGeneralStats", false);
		modConfigurations.Set("DisableHotbar", false);
		modConfigurations.Set("CanQuickEquip", true);
		modConfigurations.Set("DisableSquadInterface", false);
		modConfigurations.Set("DisableMasteryMenu", false);
	end);
	
	return CutsceneSequence;
end;