local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 6;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	storagePrefabs = game.ReplicatedStorage.Prefabs:WaitForChild("Objects");
	
	if modBranchConfigs.IsWorld("TheWarehouse") then
		modOnGameEvents:ConnectEvent("OnDoorEnter", function(player, interactData)
			local doorName = interactData.Name;
			if doorName == nil then return end;
			if not modMission:Progress(player, missionId) then return end;
	
			if doorName == "Warehouse Entrance Door" then
				modMission:Progress(player, missionId, function(mission)
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
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheWarehouse") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
		
		
		local robertModule = modNpc.GetPlayerNpc(player, "Robert");
		local bloxMartCf = CFrame.new(268, 57.71, 33.87, -1, 0, 0.05, 0, 1, 0, -0.05, 0, -1);
		if robertModule == nil then
			local npc = modNpc.Spawn("Robert", bloxMartCf, function(npc, npcModule)
				npcModule.Owner = player;
				robertModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
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
		
		local barricade, destructible;
		
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				barricade = modReplicationManager.GetReplicated(player, "bloxmartBlockage")[1];
				Debugger:Warn("A GetReplicated ",barricade);

				if barricade == nil then
					Debugger:Warn("New barracade for "..player.Name);
					barricade = storagePrefabs:WaitForChild("bloxmartBlockage"):Clone();
					modReplicationManager.ReplicateIn(player, barricade, workspace.Environment);
				end

				mission.Cache.Barricade = barricade

				destructible = barricade and barricade:FindFirstChild("Destructible") and require(barricade.Destructible) or nil;

				robertModule.StopAnimation("Sit");
				robertModule.RootPart.Anchored = true;
				robertModule.Actions:Teleport(bloxMartCf);

				robertModule.SetAnimation("Holding", {script:WaitForChild("RobertHoldingAnim")});
				robertModule.PlayAnimation("Holding");
				
			elseif mission.Type == 1 then -- OnActive
				barricade = modReplicationManager.GetReplicated(player, "bloxmartBlockage")[1];
				destructible = barricade and barricade:WaitForChild("Destructible") and require(barricade.Destructible) or nil;
				Debugger:Warn("B GetReplicated ",barricade);

				Debugger:Log("mission.ProgressionPoint", mission.ProgressionPoint, "barricade", barricade ~= nil);

				if mission.ProgressionPoint == 1 then
					robertModule.StopAnimation("Sit");
					if destructible then
						Debugger:Log("Set destructible enable");
						destructible:SetEnabled(true);
						destructible.OnDestroy = function()
							game.Debris:AddItem(barricade, 20);
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint < 2 then
									mission.ProgressionPoint = 2;
									modAnalyticsService:LogOnBoarding{
										Player=player;
										OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission6_DestroyedBarricade;
									};

								end;
							end)
						end
					else
						Debugger:Log("Missing destructible ",barricade);
					end;
					robertModule.Actions:Teleport(bloxMartCf);
					robertModule.StopAnimation("Holding");
					robertModule.RootPart.Anchored = false;
					robertModule.Move:MoveTo(Vector3.new(268, 57.71, 20.87));
					wait(1);
					robertModule.Actions:FaceOwner();

				elseif mission.ProgressionPoint == 2 then
					robertModule.RootPart.Anchored = false;
					robertModule.StopAnimation("Holding");
					robertModule.Chat(robertModule.Owner, "Please take me somewhere safe.");
					robertModule.Actions:FollowOwner(function()
						return mission.Type == 1 and mission.ProgressionPoint == 2
					end);
					mission.Cache.Barricade = nil;

				end
				
			elseif mission.Type == 3 then -- OnComplete
				if firstRun and not modMission:IsComplete(player, 7) then
					robertModule.Move:Stop();
					robertModule.Actions:Teleport(CFrame.new(15.6800423, 57.6597404, 42.3099594));
					robertModule.Move:Face(Vector3.new(15.6800423, 57.6597404, 37.0099602));
					robertModule.PlayAnimation("Sit", 0.75);

				end

			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;