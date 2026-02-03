local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

--== Variables;
local MISSION_ID = 87;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	if modBranchConfigs.IsWorld("TheResidentials") then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;

			if interactable.Id == "resCommunityEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission) 
					if mission.ProgressionPoint < 8 then 
						mission.ProgressionPoint = 8;
					elseif mission.ProgressionPoint < 18 then
						mission.ProgressionPoint = 18;
					end;
				end)

			elseif interactable.Id == "libraryStaffDoor" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 14 then
						mission.ProgressionPoint = 14;
					end
				end)
			elseif interactable.Id == "libraryStaffDoorExit" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 17 then
						mission.ProgressionPoint = 17;
					end
				end)
			end
		end)

		shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local triggerId: string, interactable: InteractableInstance = ...;
			if triggerId ~= "m87OpenBoxes" then return end;

			local objId = interactable.Values.ObjId;
			pcall(function()
				game.Debris:AddItem((interactable.Config.Parent :: Model):FindFirstChild("Decal", true), 0);
			end)

			if objId == "PaperBox4" then
				interactable.Config:SetAttribute("_Label", "Box of Walkie Talkies...");

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 15 then
						mission.ProgressionPoint = 15;
					end
				end)

				return;
			end

			interactable.Config:SetAttribute("_Label", "Empty Box");


			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 11 then 
					mission.ObjectivesCompleted[objId] = true;
					
					if mission.ObjectivesCompleted.PaperBox1 == true
					and mission.ObjectivesCompleted.PaperBox2 == true
					and mission.ObjectivesCompleted.PaperBox3 == true then
						mission.ProgressionPoint = 12;
					end
				end;
			end)
		end)
	end
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
			
		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local worldJosephModel;
		if worldJosephModel == nil and shared.WorldCore.JosephClass then
			worldJosephModel = shared.WorldCore.JosephClass.Character;
		end
		local josephClass: NpcClass = modNpcs.getPlayerNpc(player, "Joseph");
		local function spawnLocalJosephClass()
			if josephClass and josephClass.Player ~= player then josephClass = nil; end;
			if josephClass then return end;
			if worldJosephModel then
				modReplicationManager.UnreplicateFrom(player, worldJosephModel);
			end

			local spawnCf = playerClass:GetCFrame();
			if worldJosephModel then
				spawnCf = worldJosephModel:GetPivot();
			end
			josephClass = shared.modNpcs.spawn2{
				Name = "Joseph";
				Player = player;
				CFrame = spawnCf;
			};
			if josephClass == nil then return end;

			if modBranchConfigs.IsWorld("TheResidentials") and josephClass then
				modReplicationManager.ReplicateOut(player, josephClass.Character);
			end
			task.delay(1, function()
				local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
				local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
				remoteSetHeadIcon:FireAllClients(0, "Joseph", "Heal");
			end)
		end
		
		local caitlinClass: NpcClass = modNpcs.getPlayerNpc(player, "Caitlin");
		local worldCaitlinModel;
		if worldCaitlinModel == nil and shared.WorldCore.CaitlinClass then
			worldCaitlinModel = shared.WorldCore.CaitlinClass.Character;
		end
		local function spawnLocalCaitlinClass()
			if caitlinClass and caitlinClass.Player ~= player then caitlinClass = nil; end;
			if caitlinClass then return end;

			if worldCaitlinModel then
				modReplicationManager.UnreplicateFrom(player, worldCaitlinModel);
			end

			local spawnCf = playerClass:GetCFrame();
			if worldCaitlinModel then
				spawnCf = worldCaitlinModel:GetPivot();
			end
			caitlinClass = shared.modNpcs.spawn2{
				Name = "Caitlin";
				Player = player;
				CFrame = spawnCf;
			};
			if caitlinClass == nil then return end;

			if modBranchConfigs.IsWorld("TheHarbor") then
				modReplicationManager.ReplicateOut(player, caitlinClass.Character);
			end
			Debugger:StudioWarn(`Spawned local caitlin {caitlinClass.Id}`);
		end

		if modBranchConfigs.IsWorld("TheHarbor") then
			caitlinClass = modNpcs.getByModel(workspace.Entity:FindFirstChild("Caitlin"));
		end

		local caitlinHarborPosePos = Vector3.new(-308.741, 62.996, 206.642);
		local initIntro = false;
		local pp11Active = false;
		local function OnChanged(firstRun)
			if mission.Type ~= 1 then return end;

			if josephClass == nil then
				if mission.ProgressionPoint >= 2 or modBranchConfigs.IsWorld("TheResidentials") then
					spawnLocalJosephClass();
				end
			end

			if firstRun then
				if mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 6 then
					josephClass:SetCFrame(CFrame.new(-306.58, 63.046, 219.337) * CFrame.Angles(0, math.rad(22), 0));
				end
			end

			if not modBranchConfigs.IsWorld("TheHarbor") and mission.ProgressionPoint > 2 and mission.ProgressionPoint < 6 then
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ProgressionPoint = 2;
				end)
				return;
			end

			if mission.ProgressionPoint == 1 then
				-- wait for ready
			elseif mission.ProgressionPoint == 2 then

				-- ver2
				if modBranchConfigs.IsWorld("TheResidentials") then
					if firstRun then
						josephClass:SetCFrame(CFrame.new(787.386, 41.301, 441.39) * CFrame.Angles(0, math.rad(-53), 0));
						return;
					end

					josephClass:ToggleInteractable(false);
					josephClass.Properties.CutsceneActive = true;
					josephClass.Properties.CutsceneWalkTo = Vector3.new(1127.235, 56.218, 113.167);
					josephClass.Move.OnMoveToEnded:Wait(15);

					local waitForPlayerComp = josephClass:GetComponent("WaitForPlayer");
					waitForPlayerComp(15);

					josephClass:SetCFrame(CFrame.new(1127.235, 55.389 + 1.35, 124.978));
					task.wait(1);

					josephClass.Properties.CutsceneWalkToInteract = "insuranceEntrance";
					task.wait(0.2);
					josephClass.Move.OnMoveToEnded:Wait(60);
					josephClass.Properties.CutsceneWalkTo = nil;
            		josephClass:UseInteractable("insuranceEntrance");
					task.wait(1);

					josephClass.Move:MoveTo(Vector3.new(893.156, 57.887, 268.553));
					josephClass.Move.OnMoveToEnded:Wait(5);
					waitForPlayerComp(15);

					task.wait(1);

					josephClass.Chat(player, "See that there hole in the wall?");
					task.wait(5);

					josephClass.Chat(player, "Go through it and it leads to the water treatment station..");
					task.wait(4);

					josephClass.Properties.CutsceneWalkToInteract = "waterTreatmentEnter";
					task.wait(0.2);
					josephClass.Move.OnMoveToEnded:Wait(5);
					josephClass.Properties.CutsceneWalkTo = nil;
            		josephClass:UseInteractable("waterTreatmentEnter");
					task.wait(1);

					josephClass.Properties.CutsceneWalkTo = Vector3.new(838.091, 41.301, 426.829);
					task.wait(0.2);
					josephClass.Move.OnMoveToEnded:Wait(4);
					josephClass.Properties.CutsceneLookAt = Vector3.new(834.991, 41.301, 413.429);

					task.wait(2);
					josephClass.Properties.CutsceneWalkTo = nil;
					josephClass.Properties.CutsceneLookAt = nil;

					josephClass.Chat(player, "There's the door..");
					josephClass.Move:SetMoveSpeed("set", "cutscene", 5, josephClass.Move.MoveSpeedPriority.Action, 5);
					josephClass.Move:MoveTo(Vector3.new(787.386, 41.301, 441.39));
					josephClass.Move.OnMoveToEnded:Wait(5);
					task.wait(0.5);

					josephClass.Properties.CutsceneWalkTo = nil;
					josephClass.Properties.CutsceneLookAt = nil;

					josephClass:ToggleInteractable(true);
					waitForPlayerComp(15);


				elseif modBranchConfigs.IsWorld("TheHarbor") then

					josephClass.Properties.CutsceneActive = true;
					josephClass:ToggleInteractable(false);
					josephClass:SetCFrame(CFrame.new(-271.475, 40.961, 230.21) * CFrame.Angles(0, math.rad(90), 0));
					task.wait(0.5);

					local waitForPlayerComp = josephClass:GetComponent("WaitForPlayer");
					waitForPlayerComp(8, function(playerDistance) 
						playerClass:SetCFrame(josephClass:GetCFrame());
					end);

					josephClass.Chat(player, "This should be their basement..");
					task.wait(4);
					
					
					local newBoxInteractConfig: Configuration = modInteractables.createInteractable("ButtonRotd");
					newBoxInteractConfig:SetAttribute("_Animation", "OpenStorage");
					newBoxInteractConfig:SetAttribute("_InteractDuration", 1);
					newBoxInteractConfig:SetAttribute("_Uses", 1);
					newBoxInteractConfig:SetAttribute("_Label", "Open Box");
					newBoxInteractConfig:SetAttribute("_Toggle", "IsOpened");

					local boxModel = script.PaperBox5:Clone();
					newBoxInteractConfig.Parent = boxModel;

					boxModel.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, boxModel);


					josephClass.Properties.CutsceneWalkToInteract = "ratTunnelExit";
					task.wait(0.2);
					josephClass.Move.OnMoveToEnded:Wait(5);
					josephClass.Properties.CutsceneWalkTo = nil;
            		josephClass:UseInteractable("ratTunnelExit");

					task.wait(0.5);

					josephClass:ToggleInteractable(true);
					josephClass.Chat(player, "Okay, let's look for the walkies and get out quick..");
					josephClass.Properties.CutsceneWalkTo = Vector3.new(-370.416, 40.961, 240.159);
					josephClass.Move.OnMoveToEnded:Wait(10);
					task.wait(1);
					josephClass.PlayAnimation("CrossedArm");

					local boxInteractable: InteractableInstance = modInteractables.getOrNew(newBoxInteractConfig);
					waitForPlayerComp(nil, function(playerDistance) 
						return boxInteractable.Values.IsOpened == true;
					end);

					pcall(function()
						game.Debris:AddItem((newBoxInteractConfig.Parent :: Model):FindFirstChild("Decal", true), 0);
					end)
					newBoxInteractConfig:SetAttribute("_Label", "Empty Box");

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 3;
					end)

				else
					return;
				end


			elseif mission.ProgressionPoint == 3 then
				if not modBranchConfigs.IsWorld("TheHarbor") then
					return;
				end

				spawnLocalCaitlinClass();

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;

				josephClass.Properties.CutsceneWalkTo = nil;
				caitlinClass.Properties.CutsceneEquip = "mp7";
				caitlinClass:UseInteractable("ratDormitoryEntrance");
				caitlinClass:GetComponent("AvatarFace"):Set("Angry");
				task.wait(0.5);

				josephClass.Chat(player, "*hmmf* ... uh.. hello..");
				josephClass.Move:Face(caitlinClass.RootPart.Position);
				josephClass.StopAnimation("CrossedArm");
				josephClass.PlayAnimation("Surrender");
				task.wait(3);

				local waitForPlayerComp = caitlinClass:GetComponent("WaitForPlayer");
				waitForPlayerComp(24);
				caitlinClass.Chat(player, "Stop right there!");

			elseif mission.ProgressionPoint == 4 then
				if not modBranchConfigs.IsWorld("TheHarbor") then
					return;
				end

				josephClass.Move:MoveTo(Vector3.new(-369.49, 40.9, 231.19));
				josephClass.Move:SetMoveSpeed("set", "cutscene", 5, josephClass.Move.MoveSpeedPriority.Action, 5);
				josephClass.StopAnimation("Surrender");
				josephClass:ToggleInteractable(false);

				task.wait(4);
				caitlinClass.Properties.CutsceneEquip = nil;
				josephClass.Move:Face(caitlinClass.RootPart);
				caitlinClass.Move:Face(josephClass.RootPart);
				caitlinClass.Chat(player, "... Your name sounds familar, have we met before?");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(5);
				josephClass.Chat(player, "... I don't believe we have..");
				josephClass.Move:HeadTrack(caitlinClass.Head, 3);

				task.wait(3);
				caitlinClass.Chat(player, "...");

				task.wait(2);
				caitlinClass.Chat(player, "Nevermind...");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(3);
				caitlinClass.Move:HeadTrack(playerClass.Head, 3);
				task.wait(0.5);
				caitlinClass.Chat(player, `Alright {player.Name}, I can help you, but first you will have to take me to your friend's safehouse.`);

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 5 then
						mission.ProgressionPoint = 5;
					end
				end)
				task.wait(0.5);
				modDialogueService:InvokeDialogue(player, "talk", {
					NpcModel = caitlinClass.Character;
				});

			elseif mission.ProgressionPoint == 5 then
				if not modBranchConfigs.IsWorld("TheHarbor") then
					return;
				end

				caitlinClass.Move:HeadTrack(playerClass.Head, 3);
				
			elseif mission.ProgressionPoint == 6 then
				if not modBranchConfigs.IsWorld("TheHarbor") then
					return;
				end

				caitlinClass.Move:HeadTrack(josephClass.Head, 3);
				josephClass:ToggleInteractable(true);

				if not firstRun then
					task.wait(5);
					caitlinClass.Chat(player, "Heh, I'm not like the idiots upstairs. When you're ready, let's go.");
					caitlinClass.Move:HeadTrack(playerClass.Head, 3);
					
					task.wait(5);
					modDialogueService:InvokeDialogue(player, "talk", {
						NpcModel = josephClass.Character;
					});
				end

			elseif mission.ProgressionPoint == 7 then
				spawnLocalCaitlinClass();

				local caitlinFollowPlayerComp = caitlinClass:GetComponent("FollowPlayer");
				local caitlinFollowDist = 13;
				caitlinFollowPlayerComp(nil, function()
					return mission.Type == 1 and mission.ProgressionPoint == 7;
				end, caitlinFollowDist)

				local josephFollowPlayerComp = josephClass:GetComponent("FollowPlayer");
				josephFollowPlayerComp(nil, function()
					return mission.Type == 1 and mission.ProgressionPoint == 7;
				end)

				if modBranchConfigs.IsWorld("TheResidentials") then
					task.spawn(function()
						while mission.Type == 1 and mission.ProgressionPoint == 7 do
							task.wait(1);
							if not game.Players:IsAncestorOf(player) then break end;

							
							local isInSafehome = player:GetAttribute("Location") == "Community Safehouse";
							if not isInSafehome then continue end;
							
							modMission:Progress(player, MISSION_ID, function(mission) 
								if mission.ProgressionPoint < 8 then 
									mission.ProgressionPoint = 8;
								end;
							end);
						end
					end)
				end

			elseif mission.ProgressionPoint == 8 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end
				spawnLocalCaitlinClass();

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;

				task.wait(0.5);

				local entranceList = {
					{-- Radio entrance;
						MatchPos = Vector3.new(1126.973, 57.716, -160.456);
						JosephPos = Vector3.new(1130.352, 57.839, -65.122);
						CaitlinPos = Vector3.new(1130.82, 57.839, -77.952);
					};
					{-- Gas station entrance;
						MatchPos = Vector3.new(1126.558, 57.716, 106.654);
						JosephPos = Vector3.new(1129.236, 57.839, 12.874);
						CaitlinPos = Vector3.new(1128.686, 57.839, 28.865);
					};
				};

				local playerClass: PlayerClass = shared.modPlayers.get(player);
				local pickEntrance = entranceList[2];
				for _, entrance in pairs(entranceList) do
					if playerClass:DistanceFromCharacter(entrance.MatchPos) <= 16 then
						pickEntrance = entrance;
						break;
					end
				end

				local tpCf = CFrame.new(pickEntrance.MatchPos);
				josephClass:SetCFrame(tpCf * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)));
				caitlinClass:SetCFrame(tpCf * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)));

				josephClass.Move:MoveTo(pickEntrance.JosephPos);
				josephClass.Move:SetMoveSpeed("set", "cutscene", 10, josephClass.Move.MoveSpeedPriority.Action, 8);
				josephClass:ToggleInteractable(false);
				task.spawn(function()
					josephClass.Move.OnMoveToEnded:Wait(8);
					josephClass.Move:HeadTrack(caitlinClass.Head, 10);
				end)
				task.delay(4, function()
					caitlinClass.Chat(player, "So this is it.. The community safehouse.");
				end)
				caitlinClass:ToggleInteractable(false);
				caitlinClass.Move:MoveTo(pickEntrance.CaitlinPos);
				caitlinClass.Move:SetMoveSpeed("set", "cutscene", 10, josephClass.Move.MoveSpeedPriority.Action, 8);
				caitlinClass.Move.OnMoveToEnded:Wait(12);
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				josephClass.Chat(player, "Yeah, this is it.");
				josephClass:ToggleInteractable(true);
				caitlinClass:ToggleInteractable(true);
				caitlinClass.Properties.CutsceneActive = false;
				josephClass.Properties.CutsceneActive = false;

			elseif mission.ProgressionPoint == 9 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end
				spawnLocalCaitlinClass();

				caitlinClass.Move:Face(Vector3.new(955.496, 89.461, -17.857));
				caitlinClass.PlayAnimation("Point");

			elseif mission.ProgressionPoint == 10 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end
				spawnLocalCaitlinClass();

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;
				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);

				local josephFollowPlayerComp = josephClass:GetComponent("FollowPlayer");
				josephFollowPlayerComp(nil, function()
					return mission.Type == 1 and mission.ProgressionPoint == 10;
				end)
				caitlinClass.Move:SetMoveSpeed("set", "cutscene", 18, caitlinClass.Move.MoveSpeedPriority.Action);

				task.wait(2);
				josephClass.Chat(player, "About time..");

				local interactConfig = modInteractables.getById("resCommunityExit");
				local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
				local interactPart = interactable.Part;
				local pathFindAtt = interactPart:FindFirstChild("PathToInteract");

				 
				caitlinClass.Properties.CutsceneWalkTo = pathFindAtt.WorldPosition;
				caitlinClass.Move.OnMoveToEnded:Wait(20);
				caitlinClass.Properties.CutsceneWalkTo = nil;

				caitlinClass:GetComponent("WaitForPlayer")(20);
				caitlinClass:UseInteractable(interactConfig, {});

				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(950.263, 56.695, -10.288);
				caitlinClass.Move.OnMoveToEnded:Wait(35);
				caitlinClass.Properties.CutsceneWalkTo = nil;

				caitlinClass:GetComponent("WaitForPlayer")(20);
				task.wait(1);
				caitlinClass.Move:SetMoveSpeed("remove", "cutscene");
				caitlinClass.Chat(player, "Okay.. Look around and see if any of the boxes have anything..");
				caitlinClass.Move:Face(Vector3.new(894.504, 77.51, -20.137));
				task.wait(2);

				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 11 then
						mission.ProgressionPoint = 11;
					end
				end)

			elseif mission.ProgressionPoint == 11 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end

				if pp11Active then return end;
				pp11Active = true;

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;
				if firstRun then
					caitlinClass:SetCFrame(CFrame.new(950.263, 56.695, -10.288));
				end

				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);

				josephClass.Properties.CutsceneWalkTo = Vector3.new(951.116, 57.7, -17.514);
				caitlinClass.Move:HeadTrack(josephClass.Head, 10);

				local function newBoxInteractable()
					local newBoxInteractConfig = modInteractables.createInteractable("ButtonRotd");
					newBoxInteractConfig:SetAttribute("_Id", "m87OpenBoxes");
					newBoxInteractConfig:SetAttribute("_Animation", "OpenStorage");
					newBoxInteractConfig:SetAttribute("_InteractDuration", 1);
					newBoxInteractConfig:SetAttribute("_Uses", 1);
					newBoxInteractConfig:SetAttribute("_Label", "Open Box");

					return newBoxInteractConfig;
				end

				for a=1, 3 do
					local boxModel = script["PaperBox"..a]:Clone();

					local newBoxInteractConfig: Configuration = newBoxInteractable();
					newBoxInteractConfig.Parent = boxModel;

					local boxInteractable: InteractableInstance = modInteractables.getOrNew(newBoxInteractConfig);
					boxInteractable.Values.ObjId = boxModel.Name;
					
					boxModel.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, boxModel);
				end
				
				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(950.263, 56.695, -10.288);
				josephClass.Properties.CutsceneWalkTo = Vector3.new(951.116, 57.7, -17.514);
				task.wait(3);
				josephClass.Properties.CutsceneWalkTo = Vector3.new(951.116, 57.7, -17.514);
				josephClass.Properties.CutsceneLookAt = caitlinClass:GetCFrame().Position;
				caitlinClass.Properties.CutsceneLookAt = josephClass:GetCFrame().Position;
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;

				josephClass.Chat(player, "Hmmm, why here?..");

				task.wait(6);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "Cooper told us a story about how he once stole a bunch of money and hid it in a library...");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				josephClass.Chat(player, "Is this before the apocalypse? And why a library?");
				josephClass.Move:HeadTrack(caitlinClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "It was years ago, he said he got on a plane after the robbery...");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "and then jumped off while the plane was mid-flight...");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);
				josephClass.Move:HeadTrack(caitlinClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				josephClass.Chat(player, "I don't buy any of this.. He's just making this up..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "That's what I thought to, but I remember a newspaper article talking about something similar..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				josephClass.Chat(player, "Hmmm.. So why a library?..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(8);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "I don't know, maybe he was a librarian before or something...");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "There's this one time, Cooper asked David to bet a book on the Fall of the Living card game...");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "Cooper won it, so I guess he wanted the book for something..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "Thing is.. I never saw Cooper read it, or any books for that matter..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "Maybe he just liked the book smell..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(10);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				josephClass.Chat(player, ".. mhmm..");

				task.wait(6);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "Unfortunately for him, it looks like this place is entirely runned down..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);

				task.wait(15);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 11 then return end;
				caitlinClass.Chat(player, "People probably looted the books as kindling for fire..");
				caitlinClass.Move:HeadTrack(josephClass.Head, 3);


			elseif mission.ProgressionPoint == 12 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end
				if firstRun then
					caitlinClass:SetCFrame(CFrame.new(950.263, 56.695, -10.288));
					josephClass:SetCFrame(CFrame.new(951.116, 57.7, -17.514));
				end

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneLookAt = nil;
				caitlinClass.Properties.CutsceneLookAt = nil;
				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);

				task.wait(4);
				caitlinClass.Chat(player, "Wait, I have an idea of where it could be...");
				
				task.wait(1);

				task.delay(2, function()
					josephClass.Properties.CutsceneWalkTo = Vector3.new(870.286, 57.751, -31.345);
					josephClass.Move:SetMoveSpeed("set", "cutscene", 5, josephClass.Move.MoveSpeedPriority.Action, 8);
					josephClass.Move.OnMoveToEnded:Wait(10);
					josephClass.Move:HeadTrack(playerClass.Head, 3);
					josephClass.PlayAnimation("CrossedArm");
				end)

				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(857.425, 57.751, -37.106);
				caitlinClass.Move.OnMoveToEnded:Wait(10);

				caitlinClass:GetComponent("WaitForPlayer")(10);
				caitlinClass.Move:HeadTrack(playerClass.Head, 3);
				caitlinClass.Chat(player, "It's more likely to be in here.");

				task.wait(3);

				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(856.506, 57.751, -44.418);
				caitlinClass.Move.OnMoveToEnded:Wait(4);

				caitlinClass.Move:Face(Vector3.new(816.252, 60.25, -42.672));
				task.wait(0.3);
				caitlinClass.Properties.CutsceneWalkTo = nil;

				caitlinClass.Chat(player, "Just let me pick open this locked door..");
				caitlinClass.PlayAnimation("LockPicking");
				task.wait(10);
				if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;

				modAudio.Play("KeyLock", caitlinClass.RootPart).PlaybackSpeed = 1.4;
				task.wait(1);
				caitlinClass.StopAnimation("LockPicking");
				task.wait(2);
				
				caitlinClass.Chat(player, "Alright, it's unlocked.");
				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(858.618, 57.751, -37.175);
				caitlinClass.Move:HeadTrack(playerClass.Head, 3);

				local newStaffDoor = script:WaitForChild("libraryStaffDoor"):Clone();
				newStaffDoor.Parent = workspace.Interactables;
				modReplicationManager.ReplicateOut(player, newStaffDoor);

				local newBoxInteractConfig: Configuration = modInteractables.createInteractable("ButtonRotd");
				newBoxInteractConfig:SetAttribute("_Id", "m87OpenBoxes");
				newBoxInteractConfig:SetAttribute("_Animation", "OpenStorage");
				newBoxInteractConfig:SetAttribute("_InteractDuration", 1);
				newBoxInteractConfig:SetAttribute("_Uses", 1);
				newBoxInteractConfig:SetAttribute("_Label", "Open Box");

				local boxModel = script.PaperBox4:Clone();
				newBoxInteractConfig.Parent = boxModel;

				local boxInteractable: InteractableInstance = modInteractables.getOrNew(newBoxInteractConfig);
				boxInteractable.Values.ObjId = boxModel.Name;
				
				boxModel.Parent = workspace.Interactables;
				modReplicationManager.ReplicateOut(player, boxModel);

				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 13 then
						mission.ProgressionPoint = 13;
					end
				end)

			elseif mission.ProgressionPoint == 15 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneLookAt = nil;
				caitlinClass.Properties.CutsceneLookAt = nil;
				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);

				josephClass.Properties.CutsceneActive = true;
				josephClass:SetCFrame(CFrame.new(851.427, 57.751, -42.472) * CFrame.Angles(0, math.rad(90), 0));

				task.wait(1);
				josephClass.Chat(player, "This room feels eriee..");
				josephClass.PlayAnimation("LookAround");

				task.wait(4);
				josephClass.Properties.CutsceneWalkTo = Vector3.new(840.627, 57.751, -42.472);
				task.wait(1);
				josephClass.Chat(player, "Oh, you found the walkies!");

				task.wait(3);
				josephClass.PlayAnimation("CrouchPickup");

				task.wait(0.1);
				josephClass.Properties.CutsceneEquip = "walkietalkie";

				task.wait(3.3);
				josephClass.Properties.CutsceneEquip = nil;

				task.wait(3);

				josephClass.Properties.CutsceneWalkTo = Vector3.new(853.909, 60.15, -42.522);
				josephClass.Move.OnMoveToEnded:Wait(3);
				josephClass:SetCFrame(CFrame.new(868.818, 57.751, -46.898) * CFrame.Angles(0, math.rad(158), 0));

				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 16 then
						mission.ProgressionPoint = 16;
					end
				end)

			elseif mission.ProgressionPoint == 17 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;
				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);

				caitlinClass:SetCFrame(CFrame.new(869.506, 57.751, -33.018) * CFrame.Angles(0, math.rad(43), 0));
				josephClass:SetCFrame(CFrame.new(868.818, 57.751, -46.898) * CFrame.Angles(0, math.rad(158), 0));
				josephClass.Properties.CutsceneWalkTo = Vector3.new(868.818, 57.751, -46.898);

				caitlinClass.Chat(player, "I knew it was somewhere around here..");

				task.wait(4);
				caitlinClass.Chat(player, "Alright, let's go..");

				task.wait(3);
				josephClass.Properties.CutsceneWalkTo = Vector3.new(1123.452, 57.701, 119.099);
				task.wait(1);
				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(1123.452, 57.701, 119.099);
				josephClass.Move.OnMoveToEnded:Wait(40);

				
			elseif mission.ProgressionPoint == 18 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;
				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);
				josephClass.Properties.CutsceneWalkTo = nil;
				caitlinClass.Properties.CutsceneWalkTo = nil;
				task.wait(0.5);

				josephClass:SetCFrame(CFrame.new(1127.165, 55.389, 107.03) * CFrame.Angles(0, math.rad(90), 0));
				caitlinClass:SetCFrame(CFrame.new(1127.165, 55.389, 107.03) * CFrame.Angles(0, math.rad(90), 0));

				josephClass.Move:SetMoveSpeed("set", "cutscene", 5, josephClass.Move.MoveSpeedPriority.Action, 13);
				caitlinClass.Move:SetMoveSpeed("set", "cutscene", 5, caitlinClass.Move.MoveSpeedPriority.Action, 10);
				
				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(1143.839, 57.916, 28.544);
				josephClass.Properties.CutsceneWalkTo = Vector3.new(1132.459, 57.839, 26.241);
				josephClass.Move.OnMoveToEnded:Wait(25);

				modMission:Progress(player, MISSION_ID, function()
					if mission.ProgressionPoint <= 19 then
						mission.ProgressionPoint = 19;
					end
				end)

			elseif mission.ProgressionPoint == 19 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end

				caitlinClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneActive = true;

				caitlinClass:ToggleInteractable(false);
				josephClass:ToggleInteractable(false);
				josephClass:SetCFrame(CFrame.new(1132.459, 57.839, 26.241) * CFrame.Angles(0, math.rad(-90), 0));
				caitlinClass:SetCFrame(CFrame.new(1143.839, 57.916, 28.544) * CFrame.Angles(0, math.rad(0), 0));

				task.wait(1);
				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(1143.839, 57.916, 28.544);
				caitlinClass.Properties.CutsceneLookAt = josephClass:GetCFrame().Position;
				josephClass.Properties.CutsceneWalkTo = caitlinClass:GetCFrame().Position;

				caitlinClass.Chat(player, "Alright, I helped you guys out, can I stay here for a while?");
				caitlinClass.Move:HeadTrack(playerClass.Head, 10);
				josephClass.Move:HeadTrack(josephClass.Head, 3);
				task.wait(0.2);
				caitlinClass:ToggleInteractable(true);
				caitlinClass.Properties.CutsceneLookAt = playerClass:GetCFrame().Position;
				
			elseif mission.ProgressionPoint == 20 then
				if not modBranchConfigs.IsWorld("TheResidentials") then
					return;
				end

				caitlinClass.Properties.CutsceneActive = true;
				caitlinClass.Properties.CutsceneWalkTo = Vector3.new(1143.839, 57.916, 28.544);
				caitlinClass.Properties.CutsceneLookAt = playerClass:GetCFrame().Position;
				
				josephClass.Properties.CutsceneActive = true;
				josephClass.Properties.CutsceneWalkTo = nil;
				josephClass.Properties.CutsceneLookAt = nil;
				
				task.spawn(function()
					josephClass.Properties.CutsceneWalkTo = worldJosephModel:GetPivot().Position;
					josephClass.Move.OnMoveToEnded:Wait(45);
					josephClass.Character:Destroy();

					modReplicationManager.SetClientParent(player, worldJosephModel, workspace.Entity);
				end)

			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)
	
	return CutsceneSequence;
end;