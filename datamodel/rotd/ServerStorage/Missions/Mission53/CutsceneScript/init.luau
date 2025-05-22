local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

--== Variables;
local MISSION_ID = 53;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
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
		

		local walterModule = modNpcs.getByOwner(player, "Walter");
		if walterModule == nil then
			local npc = modNpcs.spawn("Walter", nil, function(npc, npcModule)
				npcModule.Owner = player;
				walterModule = npcModule;
			end);
			modReplicationManager.ReplicateOut(player, npc);
			walterModule:TeleportHide();
		end

		local wilsonModule = modNpcs.getByOwner(player, "Wilson");
		local waypoint1 = Vector3.new(641.839, 93.332, -72.035);
		local cargoScene, helicopterPrefab, heliCfTag, cargoDoorA, cargoDoorB, cargoDoorATag, cargoDoorBTag;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if firstRun and mission.ProgressionPoint ~= 1 and mission.ProgressionPoint <= 3 then
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 1;
					end)
					return;
				end

				if mission.ProgressionPoint == 1 then
					if cargoScene == nil then
						remoteCameraShakeAndZoom:FireClient(player, 5, 0, 1, 2, false);
						cargoScene = script:WaitForChild("CargoScene"):Clone();
						cargoScene.Parent = workspace;
						modReplicationManager.ReplicateOut(player, cargoScene);

						helicopterPrefab = cargoScene:WaitForChild("HelicopterRig");
						local clientEffect = script.HelicopterEffect:Clone();
						local prefabTag = clientEffect:WaitForChild("Prefab");
						prefabTag.Value = helicopterPrefab;

						heliCfTag = Instance.new("CFrameValue");
						heliCfTag.Value = helicopterPrefab:GetPrimaryPartCFrame();
						heliCfTag:GetPropertyChangedSignal("Value"):Connect(function()
							helicopterPrefab:SetPrimaryPartCFrame(heliCfTag.Value);
						end)
						heliCfTag.Parent = helicopterPrefab;

						local cargoDoorA = cargoScene:WaitForChild("cargoDoorA");
						local cargoDoorB = cargoScene:WaitForChild("cargoDoorB");

						cargoDoorATag = Instance.new("CFrameValue");
						cargoDoorATag.Value = cargoDoorA:GetPrimaryPartCFrame();
						cargoDoorATag:GetPropertyChangedSignal("Value"):Connect(function()
							cargoDoorA:SetPrimaryPartCFrame(cargoDoorATag.Value);
						end)
						cargoDoorATag.Parent = cargoDoorA;

						cargoDoorBTag = Instance.new("CFrameValue");
						cargoDoorBTag.Value = cargoDoorB:GetPrimaryPartCFrame();
						cargoDoorBTag:GetPropertyChangedSignal("Value"):Connect(function()
							cargoDoorB:SetPrimaryPartCFrame(cargoDoorBTag.Value);
						end)
						cargoDoorBTag.Parent = cargoDoorB;

						clientEffect.Parent = player.Character;
					end

					wilsonModule:ToggleInteractable(false);
					walterModule.Actions:Teleport(CFrame.new(659.80249, 94.9728851, -64.4730988, 0.275637239, 0, 0.961261749, 0, 1, 0, -0.961261749, 0, 0.275637239));

					wilsonModule.InMission = true;
					
					wilsonModule.Move:MoveTo(Vector3.new(613.64, 71.458, -94.619));
					wilsonModule.Move.MoveToEnded:Wait(5);
					
					wilsonModule.Move:MoveTo(Vector3.new(620.380676, 90.7988586, -95.4239197));
					wilsonModule.Move.MoveToEnded:Wait(10);
					
					wilsonModule.Actions:Teleport(CFrame.new(620.380676, 90.7988586, -95.4239197, 2.38419432e-07, 0, -1.00000334, 0, 0.999998569, 0, 1.00000608, 0, -2.38419403e-07));
					
					wilsonModule.Move:MoveTo(Vector3.new(640.453, 90.799, -74.582));
					wilsonModule.Move.MoveToEnded:Wait(5);
					
					while game.Players:IsAncestorOf(player) and player:DistanceFromCharacter(waypoint1) > 16 do
						task.wait(1);
					end
					if not game.Players:IsAncestorOf(player) then return end;

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 2;
					end)

				elseif mission.ProgressionPoint == 2 then

					walterModule.SetAnimation("TakeOffMask", {script:WaitForChild("TakeOffMask")});

					TweenService:Create(heliCfTag, TweenInfo.new(1), {
						Value=CFrame.new(665.327759, 122.156693, -65.71595, -0.949426413, 0.150374383, 0.275639594, 0.156434491, 0.987688363, -3.7252903e-09, -0.272246003, 0.0431195311, -0.961261153);
					}):Play();
					wait(0.9);
					local anchors = cargoScene:WaitForChild("AttachAnchors"):GetChildren();
					for _, obj in pairs(anchors) do
						obj.Anchored = false;
					end
					wait(0.1);
					TweenService:Create(heliCfTag, TweenInfo.new(2), {
						Value=CFrame.new(699.652527, 151.303589, -55.8733864, -0.954096198, -0.117148288, 0.275639653, -0.121869311, 0.99254632, 0, -0.273585021, -0.0335920081, -0.961261332);
					}):Play();
					wait(1);
					TweenService:Create(heliCfTag, TweenInfo.new(2), {
						Value=CFrame.new(731.894287, 162.079498, -79.3726425, 0.437129796, 0.429375529, 0.790289998, 0.0211626887, 0.873532951, -0.486308515, -0.899151683, 0.229303777, 0.372760206);
					}):Play();
					wait(1)
					TweenService:Create(heliCfTag, TweenInfo.new(2), {
						Value=CFrame.new(773.394714, 167.538437, -45.7220879, 0.74985671, 0.496620655, -0.437130302, -0.560592473, 0.827821434, -0.0211625528, 0.35135603, 0.260920823, 0.899149239);
					}):Play();
					wait(1)
					TweenService:Create(heliCfTag, TweenInfo.new(10), {
						Value=CFrame.new(1160.98584, 184.275528, 143.103088, 0.74985671, 0.496620655, -0.437130302, -0.560592473, 0.827821434, -0.0211625528, 0.35135603, 0.260920823, 0.899149239);
					}):Play();
					Debugger.Expire(helicopterPrefab, 10);
					wait(2)

					TweenService:Create(cargoDoorATag, TweenInfo.new(2), {
						Value=CFrame.new(654.471191, 97.3799973, -74.124527) * CFrame.Angles(0, math.rad(-125), 0);
					}):Play();
					TweenService:Create(cargoDoorBTag, TweenInfo.new(2), {
						Value=CFrame.new(651.385498, 97.3799973, -63.7809982) * CFrame.Angles(0, math.rad(125), 0);
					}):Play();
					wait(2)

					walterModule.Movement:Move(Vector3.new(648.141, 94.54, -73.628)):Wait();
					walterModule.Actions:Teleport(CFrame.new(648.140991, 94.5396881, -73.6277466, 0, 0, 1, 0, 1, 0, -1, 0, 0));
					wilsonModule.Move:Face(walterModule.RootPart.Position);
					walterModule.Chat(walterModule.Owner, "Why hello Wrighton Dale!");
					wait(5);
					walterModule.Chat(walterModule.Owner, "What a mess it has became..");
					wait(5);
					wilsonModule.Chat(wilsonModule.Owner, "Are you the only inspector they sent?");
					wait(5);
					walterModule.Chat(walterModule.Owner, "Oh, err, yes. Can you verify that this location is secure?");
					wait(5);
					wilsonModule.Chat(wilsonModule.Owner, "I can verify, we've set up station here for a while now..");
					wait(5);
					walterModule.Chat(walterModule.Owner, "Very well, I can begin my tasks.");
					wait(3);
					walterModule.Chat(walterModule.Owner, "Gas concentration readings.. looks acceptable to breath..");
					wait(3);
					walterModule.PlayAnimation("TakeOffMask");
					wait(0.5);
					local weldSwap = script:WaitForChild("MaskWeld");
					local nWeld = weldSwap:Clone();
					local oWeld = walterModule.Prefab:WaitForChild("Gas Mask"):WaitForChild("Handle"):WaitForChild("AccessoryWeld");

					oWeld.Enabled = false;
					nWeld.Parent = oWeld.Parent;
					nWeld.Part0 = nWeld.Parent;
					nWeld.Part1 = walterModule.Head;

					wait(2);
					walterModule.Chat(walterModule.Owner, "Oh wow, it stinks..");
					walterModule.AvatarFace:Set("Question");
					wait(5);
					walterModule.Actions:FaceOwner();
					walterModule.Chat(walterModule.Owner, "You there, come here..");
					walterModule.AvatarFace:Set("Confident");

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 3;
					end)

				elseif mission.ProgressionPoint >= 3 then

					if cargoScene == nil then
						cargoScene = script:WaitForChild("CargoScene"):Clone();
						cargoScene.Parent = workspace;
						modReplicationManager.ReplicateOut(player, cargoScene);

						cargoScene:WaitForChild("HelicopterRig"):Destroy();
						local cargoDoorA = cargoScene:WaitForChild("cargoDoorA");
						local cargoDoorB = cargoScene:WaitForChild("cargoDoorB");

						cargoDoorA:SetPrimaryPartCFrame(CFrame.new(654.471191, 97.3799973, -74.124527) * CFrame.Angles(0, math.rad(-125), 0));
						cargoDoorB:SetPrimaryPartCFrame(CFrame.new(651.385498, 97.3799973, -63.7809982) * CFrame.Angles(0, math.rad(125), 0));

						local weldSwap = script:WaitForChild("MaskWeld");
						local nWeld = weldSwap:Clone();
						local oWeld = walterModule.Prefab:WaitForChild("Gas Mask"):WaitForChild("Handle"):WaitForChild("AccessoryWeld");

						oWeld.Enabled = false;
						nWeld.Parent = oWeld.Parent;
						nWeld.Part0 = nWeld.Parent;
						nWeld.Part1 = walterModule.Head;

					end

					wilsonModule.InMission = true;
					wilsonModule:ToggleInteractable(true);
					
					wilsonModule.Actions:Teleport(CFrame.new( 639.822266, 90.7045059, -75.1730194, -0.1926018, 0, -0.981276989, 0, 1, 0, 0.981276989, 0, -0.1926018));
					walterModule.Actions:Teleport(CFrame.new(648.140991, 94.5396881, -73.6277466, 0, 0, 1, 0, 1, 0, -1, 0, 0));


				end
				
			elseif mission.Type == 3 then -- OnComplete

				if cargoScene == nil then
					cargoScene = script:WaitForChild("CargoScene"):Clone();
					cargoScene.Parent = workspace;
					modReplicationManager.ReplicateOut(player, cargoScene);

					cargoScene:WaitForChild("HelicopterRig"):Destroy();
					local cargoDoorA = cargoScene:WaitForChild("cargoDoorA");
					local cargoDoorB = cargoScene:WaitForChild("cargoDoorB");

					cargoDoorA:SetPrimaryPartCFrame(CFrame.new(654.471191, 97.3799973, -74.124527) * CFrame.Angles(0, math.rad(-125), 0));
					cargoDoorB:SetPrimaryPartCFrame(CFrame.new(651.385498, 97.3799973, -63.7809982) * CFrame.Angles(0, math.rad(125), 0));

					local weldSwap = script:WaitForChild("MaskWeld");
					local nWeld = weldSwap:Clone();
					local oWeld = walterModule.Prefab:WaitForChild("Gas Mask"):WaitForChild("Handle"):WaitForChild("AccessoryWeld");

					oWeld.Enabled = false;
					nWeld.Parent = oWeld.Parent;
					nWeld.Part0 = nWeld.Parent;
					nWeld.Part1 = walterModule.Head;

				end
				walterModule.Actions:Teleport(CFrame.new(648.140991, 94.5396881, -73.6277466, 0, 0, 1, 0, 1, 0, -1, 0, 0));

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;