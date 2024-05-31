local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 18;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	
	if modBranchConfigs.IsWorld("TheWarehouse") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;

			local robertModule = modNpc.GetPlayerNpc(player, "Robert");
			if robertModule == nil then
				local npc = modNpc.Spawn("Robert", nil, function(npc, npcModule)
					npcModule.Owner = player;
					robertModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					robertModule.Move:Stop();
					wait(0.5);
					robertModule.Actions:EnterDoor("safehouse2Entrance");
					robertModule.Chat(player, "");
					local face = robertModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://21311520" end;
					
					robertModule.Move:SetMoveSpeed("set", "default", 10);
					robertModule.Humanoid.JumpPower = 0;

					robertModule.Move:MoveTo(Vector3.new(662.87, 57.81, -13.28));
					robertModule.Move.MoveToEnded:Wait(10);
					robertModule.Move:Face(Vector3.new(650, 57.8096695, -13.2840099));
					
					robertModule.Interactable.Parent = robertModule.Prefab;
					
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 2 then
						robertModule.Chat(robertModule.Owner, "I'll follow your lead.");
						robertModule.Interactable.Parent = script;
						robertModule.Wield.Equip("mp5");
						pcall(function()
							robertModule.Wield.ToolModule.Configurations.MinBaseDamage = 40;
						end);

						robertModule.Actions:FollowOwner(function()
							if robertModule.Target then
								local enemyHumanoid = robertModule.Target:FindFirstChildWhichIsA("Humanoid");
								if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart and robertModule.IsInVision(enemyHumanoid.RootPart) then
									robertModule.Wield.SetEnemyHumanoid(enemyHumanoid);
									robertModule.Move:Face(enemyHumanoid.RootPart);
									robertModule.Wield.PrimaryFireRequest();
								else
									robertModule.Target = nil;
								end
							else
								robertModule.Wield.ReloadRequest();
							end
							return mission.Type == 1 and mission.ProgressionPoint == 2;
						end);
					end
					
				elseif mission.Type == 3 then -- OnComplete
					robertModule:TeleportHide();

				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)
		
	elseif modBranchConfigs.IsWorld("TheUnderground") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
			
			
			local carlsonModule = modNpc.GetPlayerNpc(player, "Carlson");
			if carlsonModule == nil then
				modReplicationManager.ReplicateOut(player, modNpc.Spawn("Carlson", nil, function(npc, npcModule)
					npcModule.Owner = player;
					carlsonModule = npcModule;
				end));
			end

			local erikModule = modNpc.GetPlayerNpc(player, "Erik");
			if erikModule == nil then
				modReplicationManager.ReplicateOut(player, modNpc.Spawn("Erik", nil, function(npc, npcModule)
					npcModule.Owner = player;
					erikModule = npcModule;
				end));
			end

			local dianaModule = modNpc.GetPlayerNpc(player, "Diana");
			if dianaModule == nil then
				modReplicationManager.ReplicateOut(player, modNpc.Spawn("Diana", nil, function(npc, npcModule)
					npcModule.Owner = player;
					dianaModule = npcModule;
				end));
			end

			local robertModule = modNpc.GetPlayerNpc(player, "Robert");
			if robertModule == nil then
				modReplicationManager.ReplicateOut(player, modNpc.Spawn("Robert", CFrame.new(1.65, 15, -2.57), function(npc, npcModule)
					npcModule.Owner = player;
					robertModule = npcModule;
				end));
			end
			
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					dianaModule.Actions:Teleport(CFrame.new(-200.6, 49.5, 245.7));

					carlsonModule.PlayAnimation("Injured");
					local face = carlsonModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://168332209" end;
					
					erikModule.PlayAnimation("Scared");
					local face = erikModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://2222767231" end;

					if mission.ProgressionPoint >= 4 then
						local face = robertModule.Prefab:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://22877631" end;
					end

					if firstRun then
						if mission.ProgressionPoint >= 9 then
							robertModule:TeleportHide();
						elseif mission.ProgressionPoint >= 7 then
							robertModule.Actions:Teleport(CFrame.new(-81.5, 8.682, 290));
						end
					end

					if mission.ProgressionPoint == 3 then
						local face = robertModule.Prefab:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://416829404" end; 
						robertModule.Actions:Teleport(CFrame.new(1.65, 15, -2.57));
						robertModule.Interactable.Parent = script;
						robertModule.Wield.Equip("mp5");
						pcall(function()
							robertModule.Wield.ToolModule.Configurations.MinBaseDamage = 60;
						end);

						local exitPosition = Vector3.new(-25.5, 7.5, 159.0);
						robertModule.Actions:FollowOwner(function()
							if robertModule.Target then
								local enemyHumanoid = robertModule.Target:FindFirstChildWhichIsA("Humanoid");
								if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart and robertModule.IsInVision(enemyHumanoid.RootPart) then
									robertModule.Wield.SetEnemyHumanoid(enemyHumanoid);
									robertModule.Move:Face(enemyHumanoid.RootPart);
									robertModule.Wield.PrimaryFireRequest();
								else
									robertModule.Target = nil;
								end
							else
								robertModule.Wield.ReloadRequest();
							end
							if (robertModule.RootPart.Position-exitPosition).Magnitude <= 50 then
								modMission:Progress(player, missionId, function(mission)
									if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
								end)
							end
							return mission.Type == 1 and mission.ProgressionPoint == 3;
						end);
						
					elseif mission.ProgressionPoint == 4 then
						
						robertModule.Move:SetMoveSpeed("set", "default", 15);
						
						robertModule.Chat(robertModule.Owner, "I hear something, follow me.");
						spawn(function() robertModule.Wield.ReloadRequest(); end)

						robertModule.Move:MoveTo(Vector3.new(5.2, 8.65, 177.85));
						robertModule.Move.MoveToEnded:Wait(15);
						
						robertModule.Actions:Teleport(CFrame.new(5.2, 8.65, 177.85));
						if mission.ProgressionPoint ~= 4 then return end;

						robertModule.Move:Face(Vector3.new(-7.35, 8.65, 167.4));
						local protectActive = true;
						robertModule.Actions:ProtectOwner(function()
							return protectActive;
						end)
						wait(6);
						if mission.ProgressionPoint ~= 4 then return end;

						protectActive = false;
						robertModule.Actions:WaitForOwner(30);
						if mission.ProgressionPoint ~= 4 then return end;

						robertModule.Chat(robertModule.Owner, "This way..");

						robertModule.Move:MoveTo(Vector3.new(3.15, 8.071, 257.45));
						robertModule.Move.MoveToEnded:Wait(6);
						
						robertModule.Actions:Teleport(CFrame.new(3.15, 8.071, 257.45));
						if mission.ProgressionPoint ~= 4 then return end;

						robertModule.Chat(robertModule.Owner, "Woah, look at this place..");
						robertModule.Move:Face(Vector3.new(-10.3, 8.071, 262.6));
						local face = robertModule.Prefab:FindFirstChild("face", true);
						if face then face.Texture = "rbxassetid://22877631" end;
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
						end)
						
					elseif mission.ProgressionPoint == 5 then
						if firstRun then
							robertModule.Actions:Teleport(CFrame.new(-50.795, 8.232, 279.45));
						end
						
						robertModule.Move:Stop();
						wait(1);
						if mission.ProgressionPoint ~= 5 then return end;

						robertModule.Move:MoveTo(Vector3.new(-50.795, 8.232, 279.45));
						robertModule.Move:SetMoveSpeed("set", "default", 8);
						
					elseif mission.ProgressionPoint == 6 then
						if not firstRun then
							robertModule.Move:Stop();
							
							robertModule.Actions:EnterDoor("safehouse3Door");
							robertModule.Chat(robertModule.Owner, "Oh my god! What happened here?!");
							robertModule.Wield.Unequip();
							
							robertModule.Move:SetMoveSpeed("set", "default", 15);

							robertModule.Move:MoveTo(Vector3.new(-101.6, 8.682, 315.75));
							robertModule.Move.MoveToEnded:Wait(20);
							
							robertModule.Move:Face(Vector3.new(-101.25, 8.682, 318.9));
							
							robertModule.PlayAnimation("CrouchLook", 1);
							wait(0.5);
							robertModule.Chat(robertModule.Owner, "Hey, are you okay?");
							wait(1);
							robertModule.Chat(robertModule.Owner);
							erikModule.Chat(erikModule.Owner, "Are.. are they gone?");
							wait(3);
							erikModule.Chat(erikModule.Owner);
							robertModule.Chat(robertModule.Owner, "Who are they?");
							wait(3);
							robertModule.Chat(robertModule.Owner);
							erikModule.Chat(erikModule.Owner, "The bandits");
							wait(3);
							erikModule.Chat(erikModule.Owner);
							robertModule.Chat(robertModule.Owner, "Don't worry, I think they're gone now..");
							wait(3);
							robertModule.StopAnimation("CrouchLook", 1);
							
							robertModule.Move:MoveTo(Vector3.new(-81.5, 8.682, 290));
							robertModule.Move.MoveToEnded:Wait(10);
							
						else
							robertModule.Actions:Teleport(CFrame.new(-81.5, 8.682, 290));
						end
						
					elseif mission.ProgressionPoint == 8 then
						robertModule.Interactable.Parent = robertModule.Prefab;
						
					elseif mission.ProgressionPoint == 9 then
						carlsonModule.StopAnimation("Injured");
						robertModule.Interactable.Parent = script;
						
						robertModule.Move:SetMoveSpeed("set", "default", 15);

						robertModule.Move:MoveTo(Vector3.new(-57.95, 8.682, 279.45));
						robertModule.Move.MoveToEnded:Wait(10);
						
						robertModule.Actions:EnterDoor("safehouse3Exit");
						
						robertModule.Move:MoveTo(Vector3.new(1.75, 8.55, 231.1));
						robertModule.Move.MoveToEnded:Wait(10);
						
						robertModule:TeleportHide();
						
					end
					
				elseif mission.Type == 3 then -- OnComplete
					dianaModule.Actions:Teleport(dianaModule.SpawnPoint);
					if modMission:GetMission(player, 38) == nil then
						robertModule:TeleportHide();
					end
					local face = carlsonModule.Prefab:FindFirstChild("face", true);
					if face then face.Texture = "rbxassetid://21311520" end; 
					if firstRun then
						erikModule.PlayAnimation("ScaredPeek");
					end
					robertModule:TeleportHide();

				end
			end

			modMission:Progress(player, missionId, function(mission)
				if mission.Type == 1 and mission.ProgressionPoint == 4 then
					mission.ProgressionPoint = 5;
				end;
			end)
			
			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)
		
	end
	
	return CutsceneSequence;
end;