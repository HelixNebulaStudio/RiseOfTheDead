local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);

local MISSION_ID = 77;
if RunService:IsServer() then
	local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if shared.WorldName == "SunkenShip" or shared.WorldName == "BioXResearch" then

		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local id: string, interactable: InteractableInstance = ...;

			task.spawn(function()
				if id ~= "ElderVexeronExit" then return end;

				local playerClass: PlayerClass = shared.modPlayers.get(player);
				playerClass:SetCFrame(CFrame.new(-45.057, 374.059, -42.535));

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 4;
					end
				end);
				
				modStatusEffects.VexBile(player, 0);
			end)
		end)
		
		shared.modEventService:OnInvoked("ElderVexeron_BindEaten", function(event: EventPacket, ...)
			local player = event.Player;
			if player == nil then return end;

			local elderVex: NpcClass = ...;

			task.spawn(function()
				Debugger:Warn("EnterElderVex");

				local mission = modMission:GetMission(player, MISSION_ID);
				if mission == nil then return end;
				if not (mission.Type == 1 and mission.ProgressionPoint == 1) then return end;

				modStatusEffects.VexBile(player, 10);
				
				modAudio.Play("JawsChomp", workspace);

				local playerClass: PlayerClass = shared.modPlayers.get(player);
				
				local vexeronRoom = workspace.Environment:WaitForChild("VexeronRoom");
				local enterPart = vexeronRoom:WaitForChild("Entrance");
				local destination = enterPart:WaitForChild("Destination");
				local tpCframe = CFrame.new(destination.WorldPosition) * CFrame.Angles(0, 0, 0);
				playerClass:SetCFrame(tpCframe);
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 2;
					end
				end);
				
				local properties = elderVex.Properties;
				if properties.State == "Snooze" then return end;
				properties.State = "Snooze";

				task.spawn(function()
					while mission.ProgressionPoint <= 2 do
						if elderVex.HealthComp.IsDead then break; end;
						if playerClass.HealthComp.IsDead then break; end;
						properties.StageChangedTick = tick();
						properties.SnoozeTimer = tick();
						properties.SpawnSpitterCooldown = tick() + 10;
						task.wait(1);
					end
					
					if playerClass.HealthComp.IsDead then 
						properties.SnoozeTimer = tick()-285;
					else
						properties.SnoozeTimer = tick()-240;
					end;
				end)
				
				for _, model in ipairs(properties.ActiveVexSpitters) do
					game.Debris:AddItem(model, 0);
				end
				table.clear(properties.ActiveVexSpitters);
			end)
		end)
	end
	
	function MissionFunctions.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;
		local profile = shared.modProfile:Get(player);

		if shared.WorldName == "SunkenShip" then
			local pgEnabled = true;
			if profile.Premium then
				pgEnabled = false;
			end

			local vexeronRoom = workspace.Environment:WaitForChild("VexeronRoom");
			local enterPart = vexeronRoom:WaitForChild("Entrance");
			local spinScript: Script = vexeronRoom:WaitForChild("ElderVexIntieriorScript");
			spinScript.Enabled = true;

			local exitInteractConfig = workspace.Interactables:WaitForChild("ElderVexExit"):WaitForChild("Interactable");
			local exitInteractable: InteractableInstance = modInteractables.getOrNew(exitInteractConfig);

			local cratesSpawned = false;
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						if pgEnabled then
							for _, obj in pairs(vexeronRoom:GetDescendants()) do
								if obj:IsA("BasePart") then
									
									if obj.Material == Enum.Material.Foil and obj.Color == Color3.fromRGB(86, 36, 36) then
										obj.Color = Color3.fromRGB(86, 86, 86);
										obj.Material = Enum.Material.Slate;
										
									elseif obj.Material == Enum.Material.Foil and obj.Color == Color3.fromRGB(86, 52, 52) then
										obj.Color = Color3.fromRGB(135, 116, 116);
										obj.Material = Enum.Material.Slate;

									elseif obj.Material == Enum.Material.Foil and obj.Color == Color3.fromRGB(163, 75, 75) then
										obj.Color = Color3.fromRGB(163, 163, 163);
										obj.Material = Enum.Material.Slate;

									elseif obj.Material == Enum.Material.Foil and obj.Color == Color3.fromRGB(86, 69, 69) then
										obj.Color = Color3.fromRGB(54, 68, 54);
										obj.Material = Enum.Material.Slate;
										
									end
								end
							end
						end
						
						
						if pgEnabled then
							modAudio.Play("SewersAmbient", enterPart, true, 0.75);
						end

					elseif mission.ProgressionPoint == 2 then
						Debugger:Warn("Mission77, ProgressionPoint 2");
						
						exitInteractConfig:SetAttribute("Locked", true);
						
						local vexeronRoom = workspace.Environment:WaitForChild("VexeronRoom");
						local entrancePart = vexeronRoom:WaitForChild("Entrance");
						
						if cratesSpawned then return end;
						cratesSpawned = true;

						local spawnPoints = {};
						for _, obj in pairs(entrancePart:GetChildren()) do
							if obj.Name == "CrateSpawn" then
								table.insert(spawnPoints, obj);
							end
						end
						
						mission.SaveData.PieceFound = 0;
						local crateFound = {};
						for a=1, #spawnPoints do
							local spawnPointAtt: Attachment = spawnPoints[a];
							
							local newPrefab, interactable = modCrates.spawn("raresunkencrate", spawnPointAtt.WorldCFrame, {player}, {}, true);
							local storageId = interactable.Values.StorageId;

							local basePart = newPrefab:WaitForChild("Handle");
							local baseAtt = basePart:WaitForChild("BaseAttachment");
							
							local ridgidConstraint = Instance.new("RigidConstraint");
							ridgidConstraint.Attachment0 = spawnPointAtt;
							ridgidConstraint.Attachment1 = baseAtt;
							ridgidConstraint.Parent = basePart;
							basePart.Anchored = false;
							
							local helperLight = Instance.new("PointLight");
							helperLight.Color = Color3.fromRGB(255, 102, 0);
							helperLight.Range = 6;
							helperLight.Brightness = 5;
							helperLight.Parent = basePart;

							local crateStorage = shared.modStorage.Get(storageId, player);
							if crateStorage == nil then
								Debugger:Warn(`Failed to spawn crate.`);
								continue;
							end

							crateStorage:Add("blueprintpiece", {
								CustomName = shared.modStorage.RegisterItemName("Turret Blueprint Piece ".. a.."/2");
								Values = {
									DescExtend=modRichFormatter.H3Text("\nMission: ").."There only seem to be two pieces of the blueprint inside Elder Vexeron.";
								};
							});
							crateStorage.OnChanged:Connect(function()
								local bpPieceExist = false;

								crateStorage:Loop(function(storageItem)
									if storageItem.ItemId == "blueprintpiece" then
										bpPieceExist = true;
									end
								end)
								if bpPieceExist then return end;

								if crateFound[a] ~= true then
									crateFound[a] = true;
									
									modMission:Progress(player, MISSION_ID, function(mission)
										mission.SaveData.PieceFound = (mission.SaveData.PieceFound or 0) +1;
										if mission.SaveData.PieceFound >= 2 then
											mission.ProgressionPoint = 3;
										end
									end)
								end
							end)
						end

					elseif mission.ProgressionPoint == 3 then
						Debugger:Warn("Mission77, ProgressionPoint 3");
						
						exitInteractConfig:SetAttribute("Locked", false);
					end
				end
			end
			mission.Changed:Connect(OnChanged);

		else
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
	
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 2 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 1;
						end);


					elseif mission.ProgressionPoint == 3 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 4;
						end);
						

					elseif mission.ProgressionPoint == 5 then
						if mission.SaveData.QueueMission68 == nil then
							local oldMission = missionProfile:Get(68);
							if oldMission then
								missionProfile:Destroy(oldMission);
							end
							
							modMission:AddMission(player, 68, nil, true);
							mission.SaveData.QueueMission68 = true;
						end
						
						local onSunkenSalvagesSpawnDone = false;
						local function onSunkenSalvagesSpawn(spawnCframe)
							if not (mission.Type == 1 and mission.ProgressionPoint == 5) then return end;
							if onSunkenSalvagesSpawnDone == true then return end;
							onSunkenSalvagesSpawnDone = true;
							
							Debugger:Warn("onSunkenSalvagesSpawn");
							
							local newPrefab, interactable = modCrates.spawn("raresunkencrate", spawnCframe, {player}, {}, true);
							local storageId = interactable.Values.StorageId;

							local crateStorage = shared.modStorage.Get(storageId, player);
							
							if crateStorage == nil then
								Debugger:Warn(`Fail to spawn crate.`);
								return;
							end
							crateStorage:Add("blueprintpiece", {
								CustomName=shared.modStorage.RegisterItemName("Final Turret Blueprint Piece");
								Values={
									DescExtend=modRichFormatter.H3Text("\nMission: ").."Finally, now the Mysterious Engineer can help make something out of these schematics.";
								};});
							crateStorage.OnChanged:Connect(function()
								local bpPieceExist = false;

								crateStorage:Loop(function(storageItem)
									if storageItem.ItemId == "blueprintpiece" then
										bpPieceExist = true;
									end
								end)
								if bpPieceExist then return end;
								
								modMission:Progress(player, MISSION_ID, function(mission)
									mission.ProgressionPoint = 6;
									Debugger.Expire(newPrefab, 1);
								end);
							end)
							
						end
						profile.Cache.Mission77_OnSunkenSalvagesSpawn = onSunkenSalvagesSpawn;
						
					end
				end
			end
			
			mission.Changed:Connect(OnChanged);
			OnChanged(true);

		end
	end

	if shared.WorldName == "TheHarbor" and shared.gameConfig.BranchName == "Dev" then
		task.spawn(function()
			Debugger.AwaitShared("modCommandsLibrary");
	
			shared.modCommandsLibrary:HookChatCommand("mission77", {
				Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
				Description = [[Mission77 Testing cmds;
				/mission77 tpcratestome
				]];
	
				RequiredArgs = 0;
				Function = function(speaker, args)
					local classPlayer = shared.modPlayers.get(speaker);
					local action = args[1];
					
					if action == "tpcratestome" then
						local playerCf = classPlayer:GetCFrame();
	
						local list = modReplicationManager.getReplicated(speaker, "Eaten Sunken Crate");
						for a=1, #list do
							local prefab = list[a];
							prefab:PivotTo(playerCf * CFrame.new(0, 0, 2*a));
						end
						
					else
						shared.Notify(speaker, "Unknown action for /mission77", "Negative");
	
					end
	
					return;
				end;
			});
	
		end)
	end
end

return MissionFunctions;