local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

--== Variables;
local MISSION_ID = 38;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	if modBranchConfigurations.IsWorld("TheResidentials") then
		shared.modEventService:OnInvoked("Dialogue_BindTalkedTo", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local npcModel: Model, choiceTag: string? = ...;
			if npcModel.Name ~= "Robert" then return end;

			local npcClass: NpcClass = modNpcs.getByModel(npcModel);
			if npcClass == nil then return end;

			local mission = modMission:GetMission(player, MISSION_ID);
			if mission.ProgressionPoint ~= 6 then return end;

			npcClass.Move:Face("Player");
		end)
	end
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	--MARK: TheUnderground
	if modBranchConfigurations.IsWorld("TheUnderground") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 2 then
						if robertNpcClass == nil then
							robertNpcClass = modNpcs.spawn2{
								Name = "Robert";
								Player = player;
								CFrame = CFrame.new(345.23999, 8.55466652, -7.92925215, 1, 0, 0, 0, 1, 0, 0, 0, 1);
								ReplicateOut = true;
							};
						end

						robertNpcClass:SetCFrame(CFrame.new(345.23999, 8.55466652, -7.92925215, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						robertNpcClass.Move:SetMoveSpeed("set", "default", 30);

						robertNpcClass:ToggleInteractable(false);
						spawn(function()
							-- rbxassetid://141728515 original face
							local face = robertNpcClass.Head:WaitForChild("face");
							face.Texture = "rbxassetid://5195838286";
						end)
						
						local robertWaitForPlayerComp = robertNpcClass:GetComponent("WaitForPlayer");
						robertWaitForPlayerComp.FacePlayerWhileWaiting = false;
						robertWaitForPlayerComp(40);

						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)

						robertNpcClass.Move:MoveTo(Vector3.new(306.640442, -17.4503021, -71.8792801));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);
						robertNpcClass:SetCFrame(CFrame.new(306.640442, -17.4503021, -71.8792801, 0, 0, 1, 0, 1, 0, -1, 0, 0));

						robertNpcClass.Move:MoveTo(Vector3.new(273.730255, -23.8503113, 51.0707092));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);
						robertNpcClass:SetCFrame(CFrame.new(273.730255, -23.8503113, 51.0707092, -1, 0, 0, 0, 1, 0, 0, 0, -1));

						robertNpcClass.Move:MoveTo(Vector3.new(328.187, -20.387, 116.075));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);
						robertWaitForPlayerComp(40);
						robertNpcClass:SetCFrame(CFrame.new(344.507, -20.387, 118.615, 0, 0, -1, 0, 1, 0, 1, 0, 0));

						robertNpcClass.Move:MoveTo(Vector3.new(385.680115, -23.7978725, 121.620682));
						robertNpcClass.Move.OnMoveToEnded:Wait(3);
						robertNpcClass:SetCFrame(CFrame.new(385.680115, -23.7978725, 121.620682, 0, 0, -1, 0, 1, 0, 1, 0, 0));

						robertWaitForPlayerComp(60);
						wait(1);

						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 4;
						end)
						robertNpcClass:TeleportHide();

					elseif mission.ProgressionPoint >= 4 then
						robertNpcClass:TeleportHide();

					end
					
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	--MARK: TheResidentials
	elseif modBranchConfigurations.IsWorld("TheResidentials") then

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");
			local function spawnRobert()
				if robertNpcClass == nil then
					robertNpcClass = modNpcs.spawn2{
						Name = "Robert";
						Player = player;
						CFrame = CFrame.new(1127.07922, 57.5696716, -108.439293, -1, 0, 0, 0, 1, 0, 0, 0, -1);
						ReplicateOut = true;
					};
					robertNpcClass.SetAnimation("LookBack", {script.LookbackAnim});
					robertNpcClass:GetComponent("AvatarFace").Default = "rbxassetid://141728515";
				end
			end


			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint >= 5 then
						spawnRobert();
						Debugger:Warn("Spawn robert");
					end

					local postCf = CFrame.new(1127.07922, 57.5696716, -108.439293, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					if mission.ProgressionPoint == 5 then
						robertNpcClass:SetCFrame(postCf);

						robertNpcClass.Move:SetMoveSpeed("set", "default", 15);
						robertNpcClass.Move:Face(Vector3.new(1126.967, 58.25, -70.092));
						
						spawn(function()
							local face = robertNpcClass.Head:WaitForChild("face");
							face.Texture = "rbxassetid://5195838286";
						end)

						local robertWaitForPlayer = robertNpcClass:GetComponent("WaitForPlayer");
						robertWaitForPlayer.FacePlayerWhileWaiting = false;
						robertWaitForPlayer(40);

						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 6;
						end)

					elseif mission.ProgressionPoint == 6 then
						robertNpcClass:SetCFrame(postCf)
						spawn(function()
							local face = robertNpcClass.Head:WaitForChild("face");
							face.Texture = "rbxassetid://5195838286";
						end)
						robertNpcClass.PlayAnimation("LookBack");

					elseif mission.ProgressionPoint == 7 then
						robertNpcClass:SetCFrame(postCf)
						robertNpcClass.StopAnimation("LookBack");
						spawn(function()
							-- rbxassetid://141728515 original face
							local face = robertNpcClass.Head:WaitForChild("face");
							face.Texture = "rbxassetid://141728515";
						end)

					end
					
					
				elseif mission.Type == 3 then -- OnComplete
					if not firstRun then
						wait(3);

						robertNpcClass.Move:SetMoveSpeed("set", "default", 8);
						
						robertNpcClass.Move:MoveTo(Vector3.new(1133.76843, 57.5696716, -82.2993088));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);

						robertNpcClass:SetCFrame(CFrame.new(1133.76843, 57.5696716, -82.2993088, -0.389456064, 0, -0.921045125, 0, 1, 0, 0.921045125, 0, -0.389456064));

						robertNpcClass.Move:MoveTo(Vector3.new(1174.27808, 57.5696716, -89.7092438));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);

						robertNpcClass:SetCFrame(CFrame.new(1174.27808, 57.5696716, -89.7092438, 0.981316209, 0, 0.19240205, 0, 1, 0, -0.19240205, 0, 0.981316209));

						robertNpcClass.Move:MoveTo(Vector3.new(1174.27808, 57.5696716, -89.7092438));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);

						robertNpcClass:SetCFrame(CFrame.new(1174.27808, 57.5696716, -89.7092438, 0.981316209, 0, 0.19240205, 0, 1, 0, -0.19240205, 0, 0.981316209));

						robertNpcClass.Move:MoveTo(Vector3.new(1165.12732, 60.4196625, -106.909111));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);

						robertNpcClass:SetCFrame(CFrame.new(1165.12732, 60.4196625, -106.909111, 0.0202159919, 0, 0.999795616, 0, 1, 0, -0.999795616, 0, 0.0202159919));
						task.wait(1);
						robertNpcClass:SetCFrame(CFrame.new(1158.65759, 60.4196625, -106.909111, 0.0202159919, 0, 0.999795616, 0, 1, 0, -0.999795616, 0, 0.0202159919));

						robertNpcClass.Move:MoveTo(Vector3.new(1138.83765, 60.4196625, -126.609146));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);

					end

					if robertNpcClass then
						robertNpcClass:SetCFrame(CFrame.new(1138.83765, 60.4196625, -126.609146, -0.0202159919, 0, -0.999795616, 0, 1, 0, 0.999795616, 0, -0.0202159919));
						robertNpcClass:GetComponent("AvatarFace"):Set("Confident");

					else
						Debugger:Warn("Failed to load Robert for mission 38");
					end

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

	end
	
	return CutsceneSequence;
end;