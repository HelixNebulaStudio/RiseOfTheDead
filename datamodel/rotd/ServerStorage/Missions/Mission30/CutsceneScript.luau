local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local MISSION_ID = 30;

--== Server Variables;
if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigurations.IsWorld("TheUnderground") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
			
			local rachelPrefab = workspace.Entity:FindFirstChild("Rachel");
			local rachelNpcClass: NpcClass = rachelPrefab and modNpcs.getByModel(rachelPrefab);
			
			local vladimirPrefab = workspace.Entity:FindFirstChild("Vladimir");
			local vladimirNpcClass: NpcClass = vladimirPrefab and modNpcs.getByModel(vladimirPrefab);
			
			local stanNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Stan");
			if stanNpcClass == nil then
				stanNpcClass = modNpcs.spawn2{
					Name = "Stan";
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					stanNpcClass:SetCFrame(CFrame.new(235.934204, -22.3296394, 92.4541245, 1, 0, 0, 0, 1, 0, 0, 0, 1));
					if stanNpcClass.WieldComp.ItemId == nil then
						stanNpcClass.WieldComp:Equip{
							ItemId = "czevo3";
						};
					end
					
					stanNpcClass:GetComponent("WaitForPlayer")(30);
					local attractNpcs = stanNpcClass:GetComponent("AttractNpcs");
					if attractNpcs then
						attractNpcs.AttractHumanoidType = {"Zombie"};
						attractNpcs.SelfAttractAlert = true;
						attractNpcs:Activate();
					end
					stanNpcClass:GetComponent("ProtectPlayer")();
					
					repeat
						stanNpcClass.Humanoid.Health = math.random(59, 61);
						
						local targetHandlerComp = stanNpcClass:GetComponent("TargetHandler");
						if targetHandlerComp == nil then 
							stanNpcClass.Move:Face("Player");
						end;

						task.wait(0.5);
					until player == nil or mission == nil or player.Parent == nil or mission.Type ~= 2;
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						stanNpcClass:ToggleInteractable(false);
						task.wait(3);
						stanNpcClass.Chat(stanNpcClass.Player, "Follow me...");
						
						stanNpcClass.Move:SetMoveSpeed("set", "default", 25);
						stanNpcClass.Move:MoveTo(Vector3.new(308.2, 9.83, 1.94));

						stanNpcClass.Move.OnMoveToEnded:Wait(20);
						if stanNpcClass == nil then return end;
						
						stanNpcClass:GetComponent("WaitForPlayer")(30);
						if stanNpcClass == nil then return end;

						stanNpcClass:GetComponent("ProtectPlayer").IsProtecting = false;
						
						stanNpcClass:UseInteractable("trainStationSafehouseEntrance");
						stanNpcClass.WieldComp:Unequip();
						stanNpcClass.Move:SetMoveSpeed("set", "default", 7);
						stanNpcClass.Move:MoveTo(Vector3.new(280, 9.83, -6.45));

						stanNpcClass.Move.OnMoveToEnded:Wait(10);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:Face(Vector3.new(287.25, 9.83, -6.54));

						task.wait(1);
						stanNpcClass.Chat(stanNpcClass.Player, "Hey ehh, Rachel, I need to patch up again..");
						wait(3.5);
						if rachelNpcClass then rachelNpcClass.Chat(player, "You need to be careful out there.."); end;
						wait(3.5);
						for a=1, 5 do
							stanNpcClass.HealthComp:TakeDamage(DamageData.new{
								Damage = -8;
								DamageType = "Heal";
							})
							task.wait(0.5);
						end
						if rachelNpcClass then rachelNpcClass.Chat(player, "There, done."); end;
						wait(2.5)
						stanNpcClass.Humanoid.Health = 100;
						stanNpcClass.Chat(stanNpcClass.Player, "Thanks a lot.");
						wait(1)
						
						stanNpcClass.Move:SetMoveSpeed("set", "default", 7);
						stanNpcClass.Move:MoveTo(Vector3.new(224.28, 9.83, -10.46));

						stanNpcClass.Move.OnMoveToEnded:Wait(5);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:SetMoveSpeed("set", "default", 7);
						
						wait(1)
						stanNpcClass.Chat(stanNpcClass.Player, "Yo Vlad! When are you going to have stock of that item I wanted?!");
						wait(5.5)
						if vladimirNpcClass then
							vladimirNpcClass.Chat(player, "Ugh.. Not sure, stop asking please. Так раздражает..");
						end
						wait(4.5);

						stanNpcClass.Move:MoveTo(Vector3.new(235.3, 9.8, 10.4));
						stanNpcClass.Move.OnMoveToEnded:Wait(5);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:Face("Player");

						stanNpcClass.Chat(stanNpcClass.Player, "Hey, "..player.Name);
						stanNpcClass:ToggleInteractable(true);
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 1 then
								mission.ProgressionPoint = 2;
							end;
						end)
						
					elseif mission.ProgressionPoint == 2 then
						stanNpcClass:SetCFrame(CFrame.new(235.310089, 9.83002663, 10.3999949, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						
					elseif mission.ProgressionPoint == 3 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:SetCFrame(CFrame.new(235.310089, 9.83002663, 10.3999949, 1, 0, 0, 0, 1, 0, 0, 0, 1));

						wait(2);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:SetMoveSpeed("set", "default", 7);
						stanNpcClass.Move:MoveTo(Vector3.new(230.71, 9.83, 10.74));

						stanNpcClass.Move.OnMoveToEnded:Wait(5);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:Face(Vector3.new(230.65, 12.165, 14.3));

						wait(0.5);
						if stanNpcClass == nil then return end;

						stanNpcClass:UseInteractable("trainStationSafehouseExit2");

						wait(2);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:MoveTo(Vector3.new(271.33, 25.69, -20.69));

						stanNpcClass.Move.OnMoveToEnded:Wait(2);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:Face(Vector3.new(276.16, 28.8, -40.043));
						
						if stanNpcClass.WieldComp.ItemId == nil then
							stanNpcClass.WieldComp:Equip{
								ItemId = "czevo3";
							};
						end

						stanNpcClass.Chat(stanNpcClass.Player, "Oh boy.. we better just save ammo and run past them.");

						wait(5);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:SetMoveSpeed("set", "default", 25);
						stanNpcClass.Move:MoveTo(Vector3.new(268.98, 52.65, -259.39));

						stanNpcClass.Move.OnMoveToEnded:Wait(15);
						if stanNpcClass == nil then return end;

						stanNpcClass:UseInteractable("mallFenceEntrance");
						stanNpcClass.Move:MoveTo(Vector3.new(273.25, 55.57, -282.3));

						stanNpcClass.Move.OnMoveToEnded:Wait(2);
						if stanNpcClass == nil then return end;

						stanNpcClass.Move:Face("Player");
						stanNpcClass.Chat(stanNpcClass.Player, "Ah.. Wrighton Dale Mall.. ");
						
					elseif mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 9 then
						if stanNpcClass == nil then return end;
						stanNpcClass:TeleportHide();
					end
				elseif mission.Type == 3 then -- OnComplete
					stanNpcClass:TeleportHide();
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
		return CutsceneSequence;

	--MARK: TheMall
	elseif modBranchConfigurations.IsWorld("TheMall") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
			
			local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
			local patrickNpcClass: NpcClass = patrickPrefab and modNpcs.getByModel(patrickPrefab);
			
			local mallStanSpawn = CFrame.new(755.640137, 59.1950226, -805.369812, -1, 0, 0, 0, 1, 0, 0, 0, -1);
			local stanNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Stan");
			
			local function OnChanged(firstRun)
				if mission.Type == 1 then -- OnActive
					if firstRun and mission.ProgressionPoint >= 4 and stanNpcClass == nil then
						stanNpcClass = modNpcs.spawn2{
							Name = "Stan";
							CFrame = mallStanSpawn;
							Player = player;
							ReplicateOut = true;
						};
					end
					
					if mission.ProgressionPoint == 4 then
						stanNpcClass:SetCFrame(mallStanSpawn);
						
					elseif mission.ProgressionPoint == 5 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:SetCFrame(mallStanSpawn);
						
						wait(2);
						stanNpcClass.Move:SetMoveSpeed("set", "default", 25);
						
						local waypoint = Vector3.new(714.962, 95.72, -721.133);
						
						waypoint = Vector3.new(731.861, 131.438, -728.346);
						stanNpcClass.Move:MoveTo(waypoint);
						stanNpcClass.Move.OnMoveToEnded:Wait(20);

						if stanNpcClass:DistanceFromCharacter(waypoint) > 20 then
							stanNpcClass:SetCFrame(CFrame.new(waypoint));
						end
						
						stanNpcClass.Move:SetMoveSpeed("set", "default", 10);
						waypoint = Vector3.new(793.235, 162.864, -726.123);  --Bandit Camp entrance
						
						stanNpcClass.Move:MoveTo(waypoint);
						stanNpcClass.Move.OnMoveToEnded:Wait(15);
						stanNpcClass.Move:Face(Vector3.new(797.496, 160.864, -730.922));
						
						if stanNpcClass:DistanceFromCharacter(waypoint) > 20 then
							stanNpcClass.Move:Stop();
							stanNpcClass:SetCFrame(CFrame.new(waypoint));
						end
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 5 then
								mission.ProgressionPoint = 6;
							end;
						end)
						
					elseif mission.ProgressionPoint == 6 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:SetCFrame(CFrame.new(793.235, 162.6, -726.123));

						local waitForPlayer = stanNpcClass:GetComponent("WaitForPlayer");
						waitForPlayer.FacePlayerWhileWaiting = false;
						waitForPlayer(20);
						waitForPlayer.FacePlayerWhileWaiting = true;
						if stanNpcClass == nil then return end;
						task.wait(0.5);
					
						stanNpcClass.WieldComp:Unequip();
						
						patrickNpcClass.Move:HeadTrack(stanNpcClass.Head, 15);
						patrickNpcClass.Move:Face(stanNpcClass.RootPart);
						stanNpcClass.Move:Face(patrickNpcClass.RootPart);
						stanNpcClass.Move:HeadTrack(patrickNpcClass.Head, 15);

						patrickNpcClass.Chat(player, "HALT! STOP RIGHT THERE OR I SHOOT!");
						wait(3);
						stanNpcClass.Chat(stanNpcClass.Player, "WAIT wait wait!!! We are here to talk!");
						wait(3);
						patrickNpcClass.Chat(player, "What do you want?!");
						stanNpcClass.Move:Face(patrickNpcClass.RootPart);
						wait(3);
						stanNpcClass.Chat(stanNpcClass.Player, "We want to speak to your leader.");
						wait(3);
						patrickNpcClass.Chat(player, "Not gonna happen. Leave now!");
						wait(3);
						stanNpcClass.Move:Face("Player");
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 6 then
								mission.ProgressionPoint = 7;
							end;
						end)
						
					elseif mission.ProgressionPoint == 7 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:SetCFrame(CFrame.new(793.235, 162.6, -726.123));
						stanNpcClass:GetComponent("WaitForPlayer")(20);
						stanNpcClass.Move:Face("Player");
						
					elseif mission.ProgressionPoint == 8 then
						stanNpcClass:ToggleInteractable(false);
						stanNpcClass:SetCFrame(CFrame.new(793.235, 162.6, -726.123));
						stanNpcClass:GetComponent("WaitForPlayer")(20);
						stanNpcClass.Move:Face("Player");
						
					elseif mission.ProgressionPoint == 9 then
						stanNpcClass:ToggleInteractable(true);
						
					elseif mission.ProgressionPoint == 10 then
						stanNpcClass:ToggleInteractable(false);
						
						stanNpcClass.Move:SetMoveSpeed("set", "default", 25);
						stanNpcClass.Move:MoveTo(Vector3.new(735.55, 93.874, -705.439)); -- mallShopSafehouseEntrance 
						stanNpcClass.Move.OnMoveToEnded:Wait(20);

						task.wait(0.5);
						modMission:CompleteMission(player, MISSION_ID);
					end

				elseif mission.Type == 3 then -- OnComplete
					if not modMission:IsComplete(player, 33) and stanNpcClass then
						stanNpcClass:ToggleInteractable(true);

						stanNpcClass:UseInteractable("mallShopSafehouseEntrance");
						stanNpcClass.WieldComp:Unequip();

						stanNpcClass.Move:MoveTo(Vector3.new(755.09, 94.925, -652.029));
						stanNpcClass.Move.OnMoveToEnded:Wait(20);
						stanNpcClass.Move:Face(Vector3.new(755.09, 94.925, -642.626));
					end
				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)
		
		return CutsceneSequence;
	end

	return;
end;