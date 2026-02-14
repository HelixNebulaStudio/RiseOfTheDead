local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local modRichFormatter = shared.require(game.ReplicatedStorage.Library.UI.RichFormatter);

local MISSION_ID = 77;
if RunService:IsServer() then
	local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if modBranchConfigurations.IsWorld("SunkenShip") then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(event: EventPacket, ...)
			local player = event.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable.Id ~= "ElderVexeronExit" then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint <= 4 then
					mission.ProgressionPoint = 4;
				end
			end);
			
			modStatusEffects.VexBile(player, 0);
		end)
		
		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
			local player = event.Player;
			if player == nil then return end;

			local triggerId: string, vexeronNpcClass: NpcClass = ...;
			if triggerId ~= "EatenByVexeron" then return end;

			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			if not (mission.Type == 1 and mission.ProgressionPoint == 1) then return end;
			Debugger:Warn("EnterElderVex");

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
			
			if vexeronNpcClass.Properties.SnoozeState == 1 then return end;
			vexeronNpcClass.Properties.SnoozeState = 1;

			task.spawn(function()
				while mission.ProgressionPoint <= 2 do
					vexeronNpcClass.Properties.SnoozeTimer = tick();
					task.wait(1);
				end
				vexeronNpcClass.Properties.SnoozeTimer = tick()-240;
			end)
		end)
		
	end
	
	function MissionFunctions.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;
		local profile = shared.modProfile:Get(player);

		if modBranchConfigurations.IsWorld("SunkenShip") then
			local cleanEnabled = true;
			if profile.Premium then
				cleanEnabled = false;
			end

			local vexeronRoom = workspace.Environment:WaitForChild("VexeronRoom");
			local enterPart = vexeronRoom:WaitForChild("Entrance");
			local spinScript: Script = vexeronRoom:WaitForChild("ElderVexIntieriorScript");
			spinScript.Enabled = true;

			local cratesSpawned = false;
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						if cleanEnabled then
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
						
						
						if cleanEnabled then
							modAudio.Play("SewersAmbient", enterPart, true, 0.75);
						end

					elseif mission.ProgressionPoint == 2 then
						Debugger:Warn("Mission77, ProgressionPoint 2");
						
						local exitInteractModule = workspace.Interactables:WaitForChild("ElderVexExit"):WaitForChild("Interactable");
						local exitInteractData = shared.require(exitInteractModule);
						exitInteractData.Script = exitInteractModule;
						exitInteractData.Locked = true;
						exitInteractData:Sync();
						
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
							
							local newPrefab, interactData = modCrates.spawn("raresunkencrate", spawnPointAtt.WorldCFrame, {player}, {});
							local basePart = newPrefab:WaitForChild("Handle");
							local baseAtt = basePart:WaitForChild("BaseAttachment");
							
							local ridgidConstraint = Instance.new("RigidConstraint");
							ridgidConstraint.Attachment0 = spawnPointAtt;
							ridgidConstraint.Attachment1 = baseAtt;
							ridgidConstraint.Parent = basePart;
							basePart.Anchored = false;
							

							local storageId = interactData.StorageId;
							
							local crateStorage = shared.modStorage.Get(storageId, player);
							crateStorage:Add("blueprintpiece", {
								CustomName=shared.modStorage.RegisterItemName("Turret Blueprint Piece ".. a.."/2");
								Values={
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
						local exitInteractModule = workspace.Interactables:WaitForChild("ElderVexExit"):WaitForChild("Interactable");
						local exitInteractData = shared.require(exitInteractModule);
						exitInteractData.Script = exitInteractModule;
						exitInteractData.Locked = false;
						if not cleanEnabled then
							exitInteractData.EnterSound = "Fart";
						end
						exitInteractData:Sync();

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
							
							--Whitelist
							local newPrefab, interactData = modCrates.spawn("raresunkencrate", spawnCframe, {player}, {}, true);
							
							local storageId = interactData.StorageId;

							local crateStorage = shared.modStorage.Get(storageId, player);
							
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

	if modBranchConfigurations.IsWorld("TheHarbor") and shared.gameConfig.BranchName == "Dev" then
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