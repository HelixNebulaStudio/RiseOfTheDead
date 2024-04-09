local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMapLibrary = require(game.ReplicatedStorage.Library.MapLibrary);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local missionId = 77;
if RunService:IsServer() then
	local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	if modBranchConfigs.IsWorld("SunkenShip") then
		modOnGameEvents:ConnectEvent("OnDoorEnter", function(player, interactData)
			if interactData and interactData.Id == "ElderVexeronExit" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 4;
					end
				end);
			end
		end)
	end
	
	function MissionFunctions.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;
		local profile = shared.modProfile:Get(player);

		local cleanEnabled = true;
		if profile.Premium then
			cleanEnabled = false;
		end
		if profile.PolicyData.IsSubjectToChinaPolicies then
			cleanEnabled = true;
		end
		if profile.PolicyData.AreAdsAllowed then
			cleanEnabled = true;
		end
		if #profile.PolicyData.AllowedExternalLinkReferences <= 0 then
			cleanEnabled = true;
		end
		local cleanUserIds = {
			568638188; --garet
			1300846062; --robo
			572465429; -- chicken
			993577280; -- blackout
			509692137; -- fancy
			539804701; -- sot
		};
		if table.find(cleanUserIds, player.UserId) then
			cleanEnabled = true;
		end
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then
					if modBranchConfigs.IsWorld("SunkenShip") then
						Debugger:Warn("Load ElderVexIntieriorScript");
						
						local vexeronRoom = workspace.Environment:WaitForChild("VexeronRoom");
						
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
						
						local spinScript: Script = vexeronRoom:WaitForChild("ElderVexIntieriorScript");
						spinScript.Enabled = true;
						
						local enterPart = vexeronRoom:WaitForChild("Entrance");
						if cleanEnabled then
							local cleanAudio = modAudio.Play("SewersAmbient", enterPart, true, 0.75);
						end
						local destination = enterPart:WaitForChild("Destination");

						
						local function EnterElderVex(elderVexNpcModule)
							if not (mission.Type == 1 and mission.ProgressionPoint == 1) then return end;
							Debugger:Warn("EnterElderVex");

							modStatusEffects.VexBile(player, 10);
							
							local sound = modAudio.Play("JawsChomp", player.Character.PrimaryPart);
							local tpCframe = CFrame.new(destination.WorldPosition) * CFrame.Angles(0, 0, 0);
							shared.modAntiCheatService:Teleport(player, tpCframe);
							
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint <= 2 then
									mission.ProgressionPoint = 2;
								end
							end);
							
							elderVexNpcModule.SnoozeState = 1;
							task.spawn(function()
								while mission.ProgressionPoint <= 2 do
									elderVexNpcModule.SnoozeTimer = tick();
									task.wait(1);
								end
								elderVexNpcModule.SnoozeTimer = tick()-240;
							end)
							
						end
						profile.Cache.Mission77_EnterElderVex = EnterElderVex;
					end
					
				elseif mission.ProgressionPoint == 2 then
					if modBranchConfigs.IsWorld("SunkenShip") then
						Debugger:Warn("Mission77, ProgressionPoint 2");
						
						local exitInteractModule = workspace.Interactables:WaitForChild("ElderVexExit"):WaitForChild("Interactable");
						local exitInteractData = require(exitInteractModule);
						exitInteractData.Script = exitInteractModule;
						exitInteractData.Locked = true;
						exitInteractData:Sync();
						
						local vexeronRoom = workspace.Environment:WaitForChild("VexeronRoom");
						local entrancePart = vexeronRoom:WaitForChild("Entrance");
						
						local spawnPoints = {};
						for _, obj in pairs(entrancePart:GetChildren()) do
							if obj.Name == "CrateSpawn" then
								table.insert(spawnPoints, obj);
							end
						end
						
						local crateFound = {};
						for a=1, #spawnPoints do
							local spawnPointAtt: Attachment = spawnPoints[a];
							
							local newPrefab, interactData = modCrates.Spawn("raresunkencrate", spawnPointAtt.WorldCFrame, {player}, {});
							local basePart = newPrefab:WaitForChild("Handle");
							local baseAtt = basePart:WaitForChild("BaseAttachment");
							
							local ridgidConstraint = Instance.new("RigidConstraint");
							ridgidConstraint.Attachment0 = spawnPointAtt;
							ridgidConstraint.Attachment1 = baseAtt;
							ridgidConstraint.Parent = basePart;
							basePart.Anchored = false;
							

							local storageId = interactData.StorageId;
							
							local crateStorage = shared.modStorage.Get(storageId, player);
							crateStorage:Add("blueprintpiece", {Values={
								Name=shared.modStorage.RegisterItemName("Turret Blueprint Piece ".. a.."/2");
								DescExtend=modRichFormatter.H3Text("\nMission: ").."There only seem to be two pieces of the blueprint inside Elder Vexeron.";
							};});
							crateStorage.OnChanged:Connect(function()
								if crateStorage:Loop() <= 0 then
									crateFound[a] = true;
								end
								
								for b=1, 2 do
									if crateFound[b] == nil then break end;
									if b == 2 then
										modMission:Progress(player, missionId, function(mission)
											mission.ProgressionPoint = 3;
										end);
									end
								end
								
							end)
						end
						
					else
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 1;
						end);
					end
					
				elseif mission.ProgressionPoint == 3 then
					if modBranchConfigs.IsWorld("SunkenShip") then
						Debugger:Warn("Mission77, ProgressionPoint 3");
						local exitInteractModule = workspace.Interactables:WaitForChild("ElderVexExit"):WaitForChild("Interactable");
						local exitInteractData = require(exitInteractModule);
						exitInteractData.Script = exitInteractModule;
						exitInteractData.Locked = false;
						if not cleanEnabled then
							exitInteractData.EnterSound = "Fart";
						end
						exitInteractData:Sync();
						
					else
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 4;
						end);
					end

				elseif mission.ProgressionPoint == 5 then
					
					if mission.SaveData.QueueMission68 == nil then
						modMission:AddMission(player, 68, nil, true);
						mission.SaveData.QueueMission68 = true;
					end
					
					local onSunkenSalvagesSpawnDone = false;
					local function onSunkenSalvagesSpawn(spawnCframe)
						if not (mission.Type == 1 and mission.ProgressionPoint == 5) then return end;
						if onSunkenSalvagesSpawnDone == true then return end;
						onSunkenSalvagesSpawnDone = true;
						
						Debugger:Warn("onSunkenSalvagesSpawn");
						
						local newPrefab, interactData = modCrates.Spawn("raresunkencrate", spawnCframe, {player}, {});
						
						local storageId = interactData.StorageId;

						local crateStorage = shared.modStorage.Get(storageId, player);
						
						crateStorage:Add("blueprintpiece", {Values={
							Name=shared.modStorage.RegisterItemName("Final Turret Blueprint Piece");
							DescExtend=modRichFormatter.H3Text("\nMission: ").."Finally, now the Mysterious Engineer can help make something out of these schematics.";
						};});
						crateStorage.OnChanged:Connect(function()
							if crateStorage:Loop() <= 0 then
								modMission:Progress(player, missionId, function(mission)
									mission.ProgressionPoint = 6;
									Debugger.Expire(newPrefab, 1);
								end);
							end
						end)
						
					end
					profile.Cache.Mission77_OnSunkenSalvagesSpawn = onSunkenSalvagesSpawn;
					
					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true, mission);
	end
end

return MissionFunctions;