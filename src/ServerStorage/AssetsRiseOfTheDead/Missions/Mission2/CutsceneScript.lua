local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 2;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	if modBranchConfigs.IsWorld("TheWarehouse") then
		modOnGameEvents:ConnectEvent("OnDoorEnter", function(player, interactData)
			local doorName = interactData.Name;
			if doorName == nil then return end;
	
			if doorName == "Bedroom Door" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint < 3 then
						mission.ProgressionPoint = 3;

						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_ExitBedroom;
						};
					end;
				end)
				
			elseif doorName == "Warehouse Exit Door" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint == 8 then
						mission.ProgressionPoint = 9;
					end;
				end)
				
			end
		end)

		local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
		modOnGameEvents:ConnectEvent("OnNpcDeath", function(npcModule)
			if npcModule.Name ~= "Zombie" then return end;

			local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");
			for _, playerTag in pairs(playerTags) do
				local player = playerTag.Player;
				
				if modMission:IsComplete(player, missionId) then continue end;

				modMission:Progress(player, missionId, function(mission)
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
		
		modOnGameEvents:ConnectEvent("OnRatShopAction", function(player, actionPacket)
			if actionPacket.Action ~= "BuyAmmo" then return end;
			if not modMission:Progress(player, missionId) then return end;

			modMission:Progress(player, missionId, function(mission)
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
			
		end)

		modOnGameEvents:ConnectEvent("OnMedicHeal", function(player, npcName)
			if not modMission:Progress(player, missionId) then return end;

			modMission:Progress(player, missionId, function(mission)
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
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;

	local modInterface;
	if modData then
		repeat
			modInterface = modData:GetInterfaceModule();
			Debugger:Warn("Waiting for interface..");
			if modInterface == nil then task.wait(); end
		until modInterface ~= nil;
	end
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
		
		local masonPrefab, masonModule;
		masonModule = modNpc.GetPlayerNpc(player, "Mason");
		if masonModule == nil then
			modNpc.Spawn("Mason", nil, function(npc, npcModule)
				npcModule.Owner = player;
				masonPrefab = npc;
				masonModule = npcModule;
			end);
			masonModule:AddComponent("AntiSit");
			
			modReplicationManager.ReplicateOut(player, masonPrefab);
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
				masonModule.StopCarLoop();
				if mission.ProgressionPoint == 1 then
					for a=1, 5 do
						shared.modAntiCheatService:Teleport(player, CFrame.new(-20.8, 59.7, -40.4, -0.09, 0, -0.99, 0, 1, 0, 1, 0, -0.09));
						if player:DistanceFromCharacter(Vector3.new(-20.8, 59.7, -40.4)) <= 16 then
							break;
						else
							task.wait(1);
						end
					end
					
					CutsceneSequence:NextScene("onPlayerSpawns");
					CutsceneSequence:Pause(20);
					
					task.delay(1, function()
						if masonModule and masonModule.PlayAnimation then
							masonModule.PlayAnimation("Lean");
							masonModule.Actions:Teleport(CFrame.new(-16.8199978, 57.6597404, -23.8900318, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						end
					end)
					
					task.delay(1, function()
						shared.modAntiCheatService:Teleport(player, CFrame.new(-19.9, 57.6, -35.95, -0.99, 0, 0.037, 0, 1, 0, -0.037, 0, -0.99));
					end)
					
					modAnalyticsService:LogOnBoarding{
						Player=player;
						OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission2_WakeUp;
					};

					CutsceneSequence:NextScene("wakeUp");

				elseif mission.ProgressionPoint == 2 then
					CutsceneSequence:NextScene("enableInterfaces");

					masonModule.StopAnimation("Lean");
					
					masonModule:ToggleInteractable(false);
					masonModule.Move:SetMoveSpeed("set", "default", 10);
					task.wait(2);

					if mission.ProgressionPoint ~= 2 then return end;
					masonModule.Chat(masonModule.Owner, "Follow me...");
					masonModule.Move:Face(Vector3.new(-0.619997144, 57.6597404, -25.171896));
					wait(0.1);

					if mission.ProgressionPoint ~= 2 then return end;
					masonModule.Move:MoveTo(Vector3.new(-5.81999636, 57.6597404, -24.2718925));
					masonModule.Move.MoveToEnded:Wait(2);
					wait(0.2);

					if mission.ProgressionPoint ~= 2 then return end;
					masonModule.Move:Face(Vector3.new(-5.81999636, 57.6597404, -20.3718967));
					wait(0.5);

					if mission.ProgressionPoint ~= 2 then return end;
					masonModule.Actions:EnterDoor("bedroomdoorMain");
					masonModule.Chat(masonModule.Owner);
					wait(0.5);
					
					masonModule.Move:MoveTo(Vector3.new(16.5800056, 57.6597404, -32.6719055));
					masonModule.Move.MoveToEnded:Wait(3);

					if mission.ProgressionPoint ~= 2 then return end;
					masonModule.Move:Face(Vector3.new(10.5800047, 57.6597404, -28.6719055));
					
					masonModule.Chat(masonModule.Owner, "Talk to Dr. Deniski");
					masonModule:ToggleInteractable(true);

				elseif mission.ProgressionPoint == 3 then
					CutsceneSequence:NextScene("enableInterfaces");

				elseif mission.ProgressionPoint == 4 then
					masonModule.Chat(masonModule.Owner);
					masonModule.Actions:Teleport(CFrame.new(15.9152822, 57.6004868, -31.9428711, -0.521899104, 0, 0.853007257, 0, 1, 0, -0.853007257, 0, -0.521899104));
					masonModule.Actions:FaceOwner();
					masonModule:ToggleInteractable(true);

				elseif mission.ProgressionPoint == 5 then
					masonModule.StopAnimation("Lean");
					task.wait(2);

					masonModule.Chat(masonModule.Owner, "I'll go and try to repair the car now..");
					masonModule.Move:SetMoveSpeed("set", "default", 10);
					
					task.wait(1);
					masonModule:ToggleInteractable(true);
					masonModule.Move:MoveTo(Vector3.new(51.2800293, 57.6597404, 40.0281067));
					
					masonModule.CarLoop();
					--mission.Changed:Disconnect(OnChanged);
				end
				
			elseif mission.Type == 3 then -- OnComplete
				masonModule.Actions:Teleport(CFrame.new(15.9152822, 57.6004868, -31.9428711, -0.521899104, 0, 0.853007257, 0, 1, 0, -0.853007257, 0, -0.521899104));
				masonModule.StopAnimation("Lean");
				masonModule.CarLoop();

			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end)
	
	local blurEffect, wakeAnimation;
	CutsceneSequence:NewScene("onPlayerSpawns", function()
		local modCharacter = modData:GetModCharacter();

		local classPlayer = shared.modPlayers.Get(localPlayer);
		local rootPart = classPlayer.RootPart;
		local humanoid = classPlayer.Humanoid;
		local head = classPlayer.Head;
		local camera = workspace.CurrentCamera;

		blurEffect = Instance.new("BlurEffect");
		blurEffect.Name = "CutsceneBlur";
		blurEffect.Size = 100;
		blurEffect.Parent = camera;

		rootPart.CFrame = CFrame.new(-20.8, 59.7, -40.4, -0.09, 0, -0.99, 0, 1, 0, 1, 0, -0.09);
		modInterface:ToggleGameBlinds(false, 0);

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
		modInterface:ToggleGameBlinds(false, 0);
		task.wait(2);
		modInterface:ToggleGameBlinds(true, 10);
		
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

		local classPlayer = shared.modPlayers.Get(localPlayer);
		local rootPart = classPlayer.RootPart;
		local head = classPlayer.Head;
		
		local unconsciousAnimation = modCharacter:GetAnimation("Unconscious");

		modInterface:ToggleGameBlinds(false, 1);
		task.wait(3.5);
		
		if head:FindFirstChild("face") then head.face:Destroy(); end
		if script:FindFirstChild("face") then script.face.Parent = head; end
		if unconsciousAnimation then
			unconsciousAnimation:Stop();
		end
		
		rootPart.CFrame = CFrame.new(-20.0200005, 57.6597404, -36.5718994, -1, 0, 0, 0, 1, 0, 0, 0, -1);
		wakeAnimation:Play();
		wakeAnimation:AdjustSpeed(0);
		modInterface:ToggleGameBlinds(true, 2);
		
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