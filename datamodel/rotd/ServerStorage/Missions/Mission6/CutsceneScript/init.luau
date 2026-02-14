local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

--== Variables;
local MISSION_ID = 6;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	storagePrefabs = game.ReplicatedStorage.Prefabs:WaitForChild("Objects");
	
	if modBranchConfigurations.IsWorld("TheWarehouse") then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, interactable: InteractableInstance)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;
			
			if interactable.Id == "warehouseEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 2 then 
						modMission:CompleteMission(player, 6);
						
						modAnalyticsService:LogOnBoarding{
							Player=player;
							OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission6_Complete;
						};
					end;
				end)

			end
		end)

	end

else
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("TheWarehouse") then
		Debugger:Warn("Invalid place for cutscene ("..script.Name..")");
		return;
	end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		
		local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");
		local bloxMartCf = CFrame.new(268, 57.71, 33.87, -1, 0, 0.05, 0, 1, 0, -0.05, 0, -1);
		if robertNpcClass == nil then
			robertNpcClass = shared.modNpcs.spawn2{
				Name = "Robert";
				CFrame = bloxMartCf;
				Player = player;
				ReplicateOut = true;
			};
		end

		local function toggleLights()
			pcall(function()
				workspace.Environment.CeilingLightsA._lightSource.Material = Enum.Material.Neon;
				workspace.Environment.CeilingLightsA._lightSource._lightPoint.PointLight.Enabled = true;
				workspace.Environment.CeilingLightsB._lightSource.Material = Enum.Material.Neon;
				workspace.Environment.CeilingLightsB._lightSource._lightPoint.PointLight.Enabled = true;
			end)
		end
		spawn(toggleLights);
		
		local barricade, destructible: DestructibleInstance;
		
		local function OnChanged(firstRun)
			if firstRun and barricade == nil then
				barricade = modReplicationManager.getReplicated(player, "bloxmartBlockage")[1];
				Debugger:Warn("A GetReplicated ",barricade);

				if barricade then
					destructible = modDestructibles.getOrNew(barricade:WaitForChild("Destructible"));
							
					destructible.HealthComp.OnHealthChanged:Connect(function(newHealth: number, prevHealth: number, reason: anydict?)
						local healthPercent = (destructible.HealthComp.CurHealth/destructible.HealthComp.MaxHealth);
						Debugger:StudioWarn("barracade HealthChanged", healthPercent);

						modAudio.Play("StorageWoodDrop", barricade:FindFirstChildWhichIsA("BasePart"));

						local rngVec = modVector.RandomUnitVector(3) * math.random(100, 200);
						if healthPercent <= 0 then
							barricade.E.Anchored = false;
							barricade.E:ApplyImpulse(rngVec * barricade.E.AssemblyMass);
							for _, c in pairs(barricade:GetChildren()) do
								if c.Name:match("_playerClip") then
									c:Destroy();
								elseif c:IsA("BasePart") then
									c.Anchored = false;
								end
							end
						elseif healthPercent < 0.25 then
							barricade.D.Anchored = false;
							barricade.D:ApplyImpulse(rngVec * barricade.D.AssemblyMass);
						elseif healthPercent < 0.5 then
							barricade.C.Anchored = false;
							barricade.C:ApplyImpulse(rngVec * barricade.C.AssemblyMass);
						elseif healthPercent < 0.75 then
							barricade.B.Anchored = false;
							barricade.B:ApplyImpulse(rngVec * barricade.B.AssemblyMass);
						elseif healthPercent < 1 then
							barricade.A.Anchored = false;
							barricade.A:ApplyImpulse(rngVec * barricade.A.AssemblyMass);
						end
					end)

				end
			end

			if mission.Type == 2 then -- OnAvailable
				robertNpcClass.StopAnimation("Sit");
				robertNpcClass.RootPart.Anchored = true;
				robertNpcClass:SetCFrame(bloxMartCf);

				robertNpcClass.SetAnimation("Holding", {script:WaitForChild("RobertHoldingAnim")});
				robertNpcClass.PlayAnimation("Holding");
				
			elseif mission.Type == 1 then -- OnActive
				Debugger:Warn("B GetReplicated ",barricade);

				Debugger:Log("mission.ProgressionPoint", mission.ProgressionPoint, "barricade", barricade ~= nil);

				if mission.ProgressionPoint == 1 then
					robertNpcClass.StopAnimation("Sit");
					
					Debugger:Log("Set destructible enable");

					destructible.HealthComp:SetMaxHealth(1000);
					destructible.HealthComp:SetHealth(1000);
					destructible:SetEnabled(true);

					destructible.HealthComp.OnIsDeadChanged:Once(function()
						Debugger:Log("Barricade destroyed");
						game.Debris:AddItem(barricade, 20);
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint < 2 then
								mission.ProgressionPoint = 2;
								modAnalyticsService:LogOnBoarding{
									Player=player;
									OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission6_DestroyedBarricade;
								};

							end;
						end)
					end)

					robertNpcClass:SetCFrame(bloxMartCf);
					robertNpcClass.StopAnimation("Holding");
					robertNpcClass.RootPart.Anchored = false;
					robertNpcClass.Move:MoveTo(Vector3.new(268, 57.71, 20.87));
					task.wait(1);
					robertNpcClass.Move:Face("Player");

				elseif mission.ProgressionPoint == 2 then
					robertNpcClass.RootPart.Anchored = false;
					robertNpcClass.StopAnimation("Holding");
					robertNpcClass.Chat(robertNpcClass.Player, "Please take me somewhere safe.");
					
					local followPlayerComp = robertNpcClass:GetComponent("FollowPlayer");
					followPlayerComp(nil, function()
						return mission.Type == 1 and mission.ProgressionPoint == 2
					end)

				end
				
			elseif mission.Type == 3 then -- OnComplete
				if firstRun and not modMission:IsComplete(player, 7) then
					robertNpcClass.Move:Stop();
					robertNpcClass:SetCFrame(CFrame.new(15.6800423, 57.6597404, 42.3099594));
					robertNpcClass.Move:Face(Vector3.new(15.6800423, 57.6597404, 37.0099602));
					robertNpcClass.PlayAnimation("Sit", 0.75);

				end

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;