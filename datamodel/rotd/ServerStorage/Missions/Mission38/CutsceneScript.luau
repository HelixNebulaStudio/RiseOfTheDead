local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 38;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	
	if modBranchConfigs.IsWorld("TheUnderground") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local robertModule = modNpcs.getByOwner(player, "Robert");

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 2 then
						if robertModule == nil then
							local npc = modNpcs.spawn("Robert", CFrame.new(345.23999, 8.55466652, -7.92925215, 1, 0, 0, 0, 1, 0, 0, 0, 1), function(npc, npcModule)
								npcModule.Owner = player;
								robertModule = npcModule;
								robertModule.StatusComp.Disabled = true;
							end);
							modReplicationManager.ReplicateOut(player, npc);
						end

						robertModule.Actions:Teleport(CFrame.new(345.23999, 8.55466652, -7.92925215, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						robertModule.Move:SetMoveSpeed("set", "default", 30);

						robertModule.Interactable.Parent = script;
						spawn(function()
							-- rbxassetid://141728515 original face
							local face = robertModule.Prefab.Head:WaitForChild("face");
							face.Texture = "rbxassetid://5195838286";
						end)
						robertModule.Actions:WaitForOwner(40);
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)

						robertModule.Move:MoveTo(Vector3.new(306.640442, -17.4503021, -71.8792801));
						robertModule.Move.OnMoveToEnded:Wait(10);
						robertModule.Actions:Teleport(CFrame.new(306.640442, -17.4503021, -71.8792801, 0, 0, 1, 0, 1, 0, -1, 0, 0));

						robertModule.Move:MoveTo(Vector3.new(273.730255, -23.8503113, 51.0707092));
						robertModule.Move.OnMoveToEnded:Wait(10);
						robertModule.Actions:Teleport(CFrame.new(273.730255, -23.8503113, 51.0707092, -1, 0, 0, 0, 1, 0, 0, 0, -1));

						robertModule.Move:MoveTo(Vector3.new(328.187, -20.387, 116.075));
						robertModule.Move.OnMoveToEnded:Wait(10);
						robertModule.Actions:WaitForOwner(40);
						robertModule.Actions:Teleport(CFrame.new(344.507, -20.387, 118.615, 0, 0, -1, 0, 1, 0, 1, 0, 0));

						robertModule.Move:MoveTo(Vector3.new(385.680115, -23.7978725, 121.620682));
						robertModule.Move.OnMoveToEnded:Wait(3);
						robertModule.Actions:Teleport(CFrame.new(385.680115, -23.7978725, 121.620682, 0, 0, -1, 0, 1, 0, 1, 0, 0));

						robertModule.Actions:WaitForOwner(60);
						wait(1);

						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 4;
						end)
						robertModule:TeleportHide();

					elseif mission.ProgressionPoint >= 4 then
						robertModule:TeleportHide();

					end
					
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

	elseif modBranchConfigs.IsWorld("TheResidentials") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local robertModule = modNpcs.getByOwner(player, "Robert");
			local function spawnRobert()
				if robertModule == nil then
					local npc = modNpcs.spawn("Robert", CFrame.new(1127.07922, 57.5696716, -108.439293, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
						npcModule.Owner = player;
						robertModule = npcModule;
						robertModule.StatusComp.Disabled = true;
					end);
					robertModule.SetAnimation("LookBack", {script.LookbackAnim});
					robertModule.AvatarFace.Default = "rbxassetid://141728515";
					modReplicationManager.ReplicateOut(player, npc);

					robertModule.Garbage:Tag(robertModule.BindOnTalkedTo.Event:Connect(function(prefab, target, choice)
						if prefab == robertModule.Prefab and target == robertModule.Owner then
							robertModule.Actions:FaceOwner();
						end
					end));
				end
			end

			if mission.ProgressionPoint >= 5 then
				spawnRobert();
				Debugger:Warn("Spawn robert");
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					local postCf = CFrame.new(1127.07922, 57.5696716, -108.439293, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					if mission.ProgressionPoint == 5 then
						robertModule.Actions:Teleport(postCf);
						robertModule.Move:SetMoveSpeed("set", "default", 15);
						robertModule.Move:Face(Vector3.new(1126.967, 58.25, -70.092));
						
						spawn(function()
							local face = robertModule.Prefab.Head:WaitForChild("face");
							face.Texture = "rbxassetid://5195838286";
						end)
						robertModule.Actions:WaitForOwner(60);
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 6;
						end)

					elseif mission.ProgressionPoint == 6 then
						robertModule.Actions:Teleport(postCf);
						spawn(function()
							local face = robertModule.Prefab.Head:WaitForChild("face");
							face.Texture = "rbxassetid://5195838286";
						end)
						robertModule.PlayAnimation("LookBack");

					elseif mission.ProgressionPoint == 7 then
						robertModule.Actions:Teleport(postCf);
						robertModule.StopAnimation("LookBack");
						spawn(function()
							-- rbxassetid://141728515 original face
							local face = robertModule.Prefab.Head:WaitForChild("face");
							face.Texture = "rbxassetid://141728515";
						end)

					end
					
					
				elseif mission.Type == 3 then -- OnComplete
					if not firstRun then
						wait(3);

						robertModule.Move:MoveTo(Vector3.new(1133.76843, 57.5696716, -82.2993088));
						robertModule.Move.OnMoveToEnded:Wait(10);

						robertModule.Actions:Teleport(CFrame.new(1133.76843, 57.5696716, -82.2993088, -0.389456064, 0, -0.921045125, 0, 1, 0, 0.921045125, 0, -0.389456064));

						robertModule.Move:MoveTo(Vector3.new(1174.27808, 57.5696716, -89.7092438));
						robertModule.Move.OnMoveToEnded:Wait(10);

						robertModule.Actions:Teleport(CFrame.new(1174.27808, 57.5696716, -89.7092438, 0.981316209, 0, 0.19240205, 0, 1, 0, -0.19240205, 0, 0.981316209));

						robertModule.Move:MoveTo(Vector3.new(1174.27808, 57.5696716, -89.7092438));
						robertModule.Move.OnMoveToEnded:Wait(10);

						robertModule.Actions:Teleport(CFrame.new(1174.27808, 57.5696716, -89.7092438, 0.981316209, 0, 0.19240205, 0, 1, 0, -0.19240205, 0, 0.981316209));

						robertModule.Move:MoveTo(Vector3.new(1165.12732, 60.4196625, -106.909111));
						robertModule.Move.OnMoveToEnded:Wait(10);

						robertModule.Actions:Teleport(CFrame.new(1165.12732, 60.4196625, -106.909111, 0.0202159919, 0, 0.999795616, 0, 1, 0, -0.999795616, 0, 0.0202159919));
						wait(1);
						robertModule.Actions:Teleport(CFrame.new(1158.65759, 60.4196625, -106.909111, 0.0202159919, 0, 0.999795616, 0, 1, 0, -0.999795616, 0, 0.0202159919));

						robertModule.Move:MoveTo(Vector3.new(1138.83765, 60.4196625, -126.609146));
						robertModule.Move.OnMoveToEnded:Wait(10);

					end

					if robertModule then
						robertModule.Actions:Teleport(CFrame.new(1138.83765, 60.4196625, -126.609146, -0.0202159919, 0, -0.999795616, 0, 1, 0, 0.999795616, 0, -0.0202159919));
	
						robertModule.AvatarFace:Set("Confident");
	
						local hair = robertModule.Prefab:WaitForChild("Hair");
						hair.Handle.Transparency = 0;

					else
						Debugger:Warn("Failed to load RobertModule for mission 38");
					end

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

	end
	
	return CutsceneSequence;
end;