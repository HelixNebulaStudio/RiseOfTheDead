local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modPlayerNpcs = shared.require(game.ReplicatedStorage.Library.PlayerNpcs);

--== Variables;
local MISSION_ID = 87;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	if shared.WorldName == "TheResidentials" then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(event: EventPacket, ...)
			local player: Player? = event.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;

			if interactable.Id == "resCommunityEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission) 
					if mission.ProgressionPoint < 9 then 
						mission.ProgressionPoint = 9;

					elseif mission.ProgressionPoint >= 16 and mission.ProgressionPoint < 19 then
						mission.ProgressionPoint = 19;

					end;
				end)

			elseif interactable.Id == "libraryStaffDoor" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint >= 14 and mission.ProgressionPoint <= 15 then
						mission.ProgressionPoint = 15;
					end
				end)

			elseif interactable.Id == "libraryStaffDoorExit" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint >= 16 and mission.ProgressionPoint <= 18 then
						mission.ProgressionPoint = 18;
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
					if mission.ProgressionPoint <= 16 then
						mission.ProgressionPoint = 16;
					end
				end)

				return;
			end

			interactable.Config:SetAttribute("_Label", "Empty Box");


			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 12 then 
					mission.ObjectivesCompleted[objId] = true;
					
					if mission.ObjectivesCompleted.PaperBox1 == true
					and mission.ObjectivesCompleted.PaperBox2 == true
					and mission.ObjectivesCompleted.PaperBox3 == true then
						mission.ProgressionPoint = 13;
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

		local josephPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Joseph");
		local josephNpcClass: NpcClass = josephPlayerNpc.NpcClass;
		
		local caitlinPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Caitlin");
		local caitlinNpcClass: NpcClass = caitlinPlayerNpc.NpcClass;
		caitlinPlayerNpc:SetCFrame{
			MissionId = MISSION_ID;
		}

		if shared.WorldName == "TheHarbor" then
		elseif shared.WorldName == "TheResidentials" then
			josephPlayerNpc:SetCFrame{
				MissionId = MISSION_ID;
			};
		end

		local pp11Active = false;
		local p16Skip = false;
		local function OnChanged(firstRun)
			if mission.Type == 3 then
				if shared.WorldName == "TheResidentials" then
					caitlinPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(1149.165, 57.87, 26.979) * CFrame.Angles(0, math.rad(10), 0);
					};
					
				elseif shared.WorldName == "TheHarbor" then
					if shared.WorldCore.CaitlinClass then
						--modReplicationManager.SetClientParent(player, shared.WorldCore.CaitlinClass.Character, game.ReplicatedStorage);
					end
					
				end
				return;
			end
			if mission.Type ~= 1 then return end;

			if shared.WorldName == "TheResidentials" then
				if firstRun then
					if mission.ProgressionPoint > 10 and mission.ProgressionPoint <= 18 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 10;
						end)

					end
				end

			elseif shared.WorldName == "TheHarbor" then
				if firstRun then
					if mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 7 then
						josephPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(-306.58, 63.046, 219.337) * CFrame.Angles(0, math.rad(22), 0);
						};
					end

					if mission.ProgressionPoint >= 3 and mission.ProgressionPoint < 7 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 2;
						end)
						return;
					end
				end
			end


			if shared.WorldName == "TheResidentials" then
				--MARK: TheResidentials
				if mission.ProgressionPoint == 2 then
					if firstRun then
						josephPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(787.386, 41.301, 441.39) * CFrame.Angles(0, math.rad(-53), 0);
						};
						return;
					end

					josephNpcClass:ToggleInteractable(false);
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(1127.235, 56.218, 113.167);
					josephNpcClass.Move.OnMoveToEnded:Wait(15);

					local waitForPlayerComp = josephNpcClass:GetComponent("WaitForPlayer");
					waitForPlayerComp(15);
					if not game.Players:IsAncestorOf(player) then return end;

					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(1127.235, 55.389 + 1.35, 124.978);
					};
					task.wait(1);

					josephNpcClass.Properties.CutsceneWalkToInteract = "insuranceEntrance";
					task.wait(0.2);
					josephNpcClass.Move.OnMoveToEnded:Wait(60);
					josephNpcClass.Properties.CutsceneWalkTo = nil;
            		josephNpcClass:UseInteractable("insuranceEntrance");
					task.wait(1);

					josephNpcClass.Move:MoveTo(Vector3.new(893.156, 57.887, 268.553));
					josephNpcClass.Move.OnMoveToEnded:Wait(5);
					waitForPlayerComp(15);
					if not game.Players:IsAncestorOf(player) then return end;

					task.wait(1);

					josephNpcClass.Chat(player, "See that there hole in the wall?");
					task.wait(5);
					if not game.Players:IsAncestorOf(player) then return end;

					josephNpcClass.Chat(player, "Go through it and it leads to the water treatment station..");
					task.wait(4);
					if not game.Players:IsAncestorOf(player) then return end;

					josephNpcClass.Properties.CutsceneWalkToInteract = "waterTreatmentEnter";
					task.wait(0.2);
					josephNpcClass.Move.OnMoveToEnded:Wait(5);
					josephNpcClass.Properties.CutsceneWalkTo = nil;
            		josephNpcClass:UseInteractable("waterTreatmentEnter");
					task.wait(1);

					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(838.091, 41.301, 426.829);
					task.wait(0.2);
					josephNpcClass.Move.OnMoveToEnded:Wait(4);
					josephNpcClass.Properties.CutsceneLookAt = Vector3.new(834.991, 41.301, 413.429);

					task.wait(2);
					josephNpcClass.Properties.CutsceneWalkTo = nil;
					josephNpcClass.Properties.CutsceneLookAt = nil;

					josephNpcClass.Chat(player, "There's the door..");
					josephNpcClass.Move:SetMoveSpeed("set", "cutscene", 5, josephNpcClass.Move.MoveSpeedPriority.Action, 5);
					josephNpcClass.Move:MoveTo(Vector3.new(787.386, 41.301, 441.39));
					josephNpcClass.Move.OnMoveToEnded:Wait(5);
					task.wait(0.5);

					josephNpcClass.Properties.CutsceneWalkTo = nil;
					josephNpcClass.Properties.CutsceneLookAt = nil;

					josephNpcClass:ToggleInteractable(true);
					waitForPlayerComp(15);


				elseif mission.ProgressionPoint == 8 then
					task.spawn(function()
						while mission.Type == 1 and mission.ProgressionPoint == 8 do
							task.wait(1);
							if not game.Players:IsAncestorOf(player) then break end;
							
							local isInSafehome = player:GetAttribute("Location") == "Community Safehouse";
							if not isInSafehome then continue end;
							
							modMission:Progress(player, MISSION_ID, function(mission) 
								if mission.ProgressionPoint < 9 then 
									mission.ProgressionPoint = 9;
								end;
							end);
						end
					end)


				elseif mission.ProgressionPoint == 9 then
					josephNpcClass:ToggleInteractable(true);
					caitlinNpcClass:ToggleInteractable(true);

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
						if playerClass:DistanceFrom(entrance.MatchPos) <= 16 then
							pickEntrance = entrance;
							break;
						end
					end

					local tpCf = CFrame.new(pickEntrance.MatchPos);
					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = tpCf * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3));
					};
					caitlinPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = tpCf * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3));
					};

					josephNpcClass.Move:MoveTo(pickEntrance.JosephPos);
					josephNpcClass.Move:SetMoveSpeed("set", "cutscene", 10, josephNpcClass.Move.MoveSpeedPriority.Action, 8);
					josephNpcClass:ToggleInteractable(false);
					task.spawn(function()
						josephNpcClass.Move.OnMoveToEnded:Wait(8);
						josephNpcClass.Move:HeadTrack(caitlinNpcClass.Head, 10);
					end)
					task.delay(4, function()
						caitlinNpcClass.Chat(player, "So this is it.. The community safehouse.");
					end)
					caitlinNpcClass:ToggleInteractable(false);
					caitlinNpcClass.Move:MoveTo(pickEntrance.CaitlinPos);
					caitlinNpcClass.Move:SetMoveSpeed("set", "cutscene", 10, josephNpcClass.Move.MoveSpeedPriority.Action, 8);
					caitlinNpcClass.Move.OnMoveToEnded:Wait(12);
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					josephNpcClass.Chat(player, "Yeah, this is it.");
					josephNpcClass:ToggleInteractable(true);
					caitlinNpcClass:ToggleInteractable(true);


				elseif mission.ProgressionPoint == 10 then
					if firstRun then
						josephPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(1128.658, 57.66, 14.02) * CFrame.Angles(0, math.rad(180), 0);
						};
						caitlinPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(1137.93, 57.87, 24.89) * CFrame.Angles(0, math.rad(180), 0);
						};
					end
					caitlinNpcClass.Move:Face(Vector3.new(955.496, 89.461, -17.857));
					caitlinNpcClass.PlayAnimation("Point");


				elseif mission.ProgressionPoint == 11 then
					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);

					local josephFollowPlayerComp = josephNpcClass:GetComponent("FollowPlayer");
					josephFollowPlayerComp(nil, function()
						return mission.Type == 1 and mission.ProgressionPoint == 11;
					end)
					caitlinNpcClass.Move:SetMoveSpeed("set", "cutscene", 18, caitlinNpcClass.Move.MoveSpeedPriority.Action);

					task.wait(2);
					josephNpcClass.Chat(player, "About time..");

					local interactable: InteractableInstance = modInteractables.getById("resCommunityExit");
					local interactPart = interactable.Part;
					local pathFindAtt = interactPart:FindFirstChild("PathToInteract");

					
					caitlinNpcClass.Properties.CutsceneWalkTo = pathFindAtt.WorldPosition;
					caitlinNpcClass.Move.OnMoveToEnded:Wait(20);
					caitlinNpcClass.Properties.CutsceneWalkTo = nil;

					caitlinNpcClass:GetComponent("WaitForPlayer")(20);
					caitlinNpcClass:UseInteractable(interactable.Config, {});

					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(950.263, 56.695, -10.288);
					caitlinNpcClass.Move.OnMoveToEnded:Wait(35);
					caitlinNpcClass.Properties.CutsceneWalkTo = nil;

					caitlinNpcClass:GetComponent("WaitForPlayer")(20);
					task.wait(1);
					caitlinNpcClass.Move:SetMoveSpeed("remove", "cutscene");
					caitlinNpcClass.Chat(player, "Okay.. Look around and see if any of the boxes have anything..");
					caitlinNpcClass.Move:Face(Vector3.new(894.504, 77.51, -20.137));
					task.wait(2);

					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 12 then
							mission.ProgressionPoint = 12;
						end
					end)


				elseif mission.ProgressionPoint == 12 then
					if pp11Active then return end;
					pp11Active = true;

					if firstRun then
						caitlinPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(950.263, 56.695, -10.288);
						};
					end

					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);

					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(951.116, 57.7, -17.514);
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 10);

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
					
					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(950.263, 56.695, -10.288);
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(951.116, 57.7, -17.514);
					task.wait(3);
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(951.116, 57.7, -17.514);
					josephNpcClass.Properties.CutsceneLookAt = caitlinNpcClass:GetCFrame().Position;
					caitlinNpcClass.Properties.CutsceneLookAt = josephNpcClass:GetCFrame().Position;
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;

					josephNpcClass.Chat(player, "Hmmm, why here?..");

					task.wait(6);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "Cooper told us a story about how he once stole a bunch of money and hid it in a library...");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					josephNpcClass.Chat(player, "Is this before the apocalypse? And why a library?");
					josephNpcClass.Move:HeadTrack(caitlinNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "It was years ago, he said he got on a plane after the robbery...");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "and then jumped off while the plane was mid-flight...");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);
					josephNpcClass.Move:HeadTrack(caitlinNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					josephNpcClass.Chat(player, "I don't buy any of this.. He's just making this up..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "That's what I thought to, but I remember a newspaper article talking about something similar..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					josephNpcClass.Chat(player, "Hmmm.. So why a library?..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(8);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "I don't know, maybe he was a librarian before or something...");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "There's this one time, Cooper asked David to bet a book on the Fall of the Living card game...");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "Cooper won it, so I guess he wanted the book for something..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "Thing is.. I never saw Cooper read it, or any books for that matter..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "Maybe he just liked the book smell..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(10);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					josephNpcClass.Chat(player, ".. mhmm..");

					task.wait(6);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "Unfortunately for him, it looks like this place is entirely runned down..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(15);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 12 then return end;
					caitlinNpcClass.Chat(player, "People probably looted the books as kindling for fire..");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);


				elseif mission.ProgressionPoint == 13 then
					if firstRun then
						caitlinPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(950.263, 56.695, -10.288);
						};
						josephPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
							CFrame = CFrame.new(951.116, 57.7, -17.514);
						};
					end

					josephNpcClass.Properties.CutsceneLookAt = nil;
					caitlinNpcClass.Properties.CutsceneLookAt = nil;
					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);

					task.wait(4);
					caitlinNpcClass.Chat(player, "Wait, I have an idea of where it could be...");
					
					task.wait(1);

					task.delay(2, function()
						josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(870.286, 57.751, -31.345);
						josephNpcClass.Move:SetMoveSpeed("set", "cutscene", 5, josephNpcClass.Move.MoveSpeedPriority.Action, 8);
						josephNpcClass.Move.OnMoveToEnded:Wait(10);
						josephNpcClass.Move:HeadTrack(playerClass.Head, 3);
						josephNpcClass.PlayAnimation("CrossedArm");
					end)

					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(857.425, 57.751, -37.106);
					caitlinNpcClass.Move.OnMoveToEnded:Wait(10);

					caitlinNpcClass:GetComponent("WaitForPlayer")(10);
					caitlinNpcClass.Move:HeadTrack(playerClass.Head, 3);
					caitlinNpcClass.Chat(player, "It's more likely to be in here.");

					task.wait(3);

					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(856.506, 57.751, -44.418);
					caitlinNpcClass.Move.OnMoveToEnded:Wait(4);

					caitlinNpcClass.Move:Face(Vector3.new(816.252, 60.25, -42.672));
					task.wait(0.3);
					caitlinNpcClass.Properties.CutsceneWalkTo = nil;

					caitlinNpcClass.Chat(player, "Just let me pick open this locked door..");
					caitlinNpcClass.PlayAnimation("LockPicking");
					task.wait(10);
					if not player:IsDescendantOf(game.Players) or mission.ProgressionPoint ~= 13 then return end;

					modAudio.Play("KeyLock", caitlinNpcClass.RootPart).PlaybackSpeed = 1.4;
					task.wait(1);
					caitlinNpcClass.StopAnimation("LockPicking");
					task.wait(2);
					
					caitlinNpcClass.Chat(player, "Alright, it's unlocked.");
					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(858.618, 57.751, -37.175);
					caitlinNpcClass.Move:HeadTrack(playerClass.Head, 3);

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
						if mission.ProgressionPoint <= 14 then
							mission.ProgressionPoint = 14;
						end
					end)

				elseif mission.ProgressionPoint == 16 then
					josephNpcClass.Properties.CutsceneLookAt = nil;
					caitlinNpcClass.Properties.CutsceneLookAt = nil;
					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);

					josephNpcClass.Properties.CutsceneActive = true;
					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(851.427, 57.751, -42.472) * CFrame.Angles(0, math.rad(90), 0);
					};

					task.wait(1);
					josephNpcClass.Chat(player, "This room feels eriee..");
					josephNpcClass.PlayAnimation("LookAround");

					task.wait(4);
					if mission.ProgressionPoint ~= 16 then return end;

					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(840.627, 57.751, -42.472);
					task.wait(1);
					
					josephNpcClass.Chat(player, "Oh, you found the walkies!");
					p16Skip = true;

					task.wait(3);
					josephNpcClass.PlayAnimation("CrouchPickup");

					task.wait(0.1);
					josephNpcClass.Properties.CutsceneEquip = "walkietalkie";

					task.wait(3.3);
					if mission.ProgressionPoint ~= 16 then return end;
					josephNpcClass.Properties.CutsceneEquip = nil;

					task.wait(3);
					if mission.ProgressionPoint ~= 16 then return end;

					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(853.909, 60.15, -42.522);
					josephNpcClass.Move.OnMoveToEnded:Wait(3);
					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(868.818, 57.751, -46.898) * CFrame.Angles(0, math.rad(158), 0);
					};

					if mission.ProgressionPoint ~= 16 then return end;

					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 17 then
							mission.ProgressionPoint = 17;
						end
					end)

				elseif mission.ProgressionPoint == 18 then
					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);

					caitlinPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(869.506, 57.751, -33.018) * CFrame.Angles(0, math.rad(43), 0);
					};
					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(868.818, 57.751, -46.898) * CFrame.Angles(0, math.rad(158), 0);
					};
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(868.818, 57.751, -46.898);

					if p16Skip ~= true then
						josephNpcClass.Chat(player, "Good, you found the walkies!");
					end
					caitlinNpcClass.Chat(player, "I knew it was somewhere around here..");

					task.wait(4);
					caitlinNpcClass.Chat(player, "Alright, let's go..");

					task.wait(3);
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(1123.452, 57.701, 119.099);
					task.wait(1);
					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(1123.452, 57.701, 119.099);
					josephNpcClass.Move.OnMoveToEnded:Wait(40);

					task.spawn(function() 
						while mission.ProgressionPoint == 18 do
							task.wait(1);
							if not game.Players:IsAncestorOf(player) then break end;
							
							local location = player:GetAttribute("Location");
							if location == "Community Safehouse" then 
								modMission:Progress(player, MISSION_ID, function(mission) 
									if mission.ProgressionPoint < 19 then 
										mission.ProgressionPoint = 19;
									end;
								end);
							end
						end
					end)


				elseif mission.ProgressionPoint == 19 then
					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);
					josephNpcClass.Properties.CutsceneWalkTo = nil;
					caitlinNpcClass.Properties.CutsceneWalkTo = nil;
					task.wait(0.5);

					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(1127.165, 55.389, 107.03) * CFrame.Angles(0, math.rad(90), 0);
					};
					caitlinPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(1127.165, 55.389, 107.03) * CFrame.Angles(0, math.rad(90), 0);
					};

					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(1143.839, 57.916, 28.544);
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(1132.459, 57.839, 26.241);
					josephNpcClass.Move.OnMoveToEnded:Wait(25);

					modMission:Progress(player, MISSION_ID, function()
						if mission.ProgressionPoint <= 20 then
							mission.ProgressionPoint = 20;
						end
					end)


				elseif mission.ProgressionPoint == 20 then
					
					caitlinNpcClass:ToggleInteractable(false);
					josephNpcClass:ToggleInteractable(false);
					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(1132.459, 57.839, 26.241) * CFrame.Angles(0, math.rad(-90), 0);
					};
					caitlinPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(1143.839, 57.916, 28.544) * CFrame.Angles(0, math.rad(0), 0);
					};

					task.wait(1);
					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(1143.839, 57.916, 28.544);
					caitlinNpcClass.Properties.CutsceneLookAt = josephNpcClass:GetCFrame().Position;
					josephNpcClass.Properties.CutsceneWalkTo = caitlinNpcClass:GetCFrame().Position;

					caitlinNpcClass.Chat(player, "Alright, I helped you guys out, can I stay here for a while?");
					caitlinNpcClass.Move:HeadTrack(playerClass.Head, 10);
					josephNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);
					task.wait(0.2);
					caitlinNpcClass:ToggleInteractable(true);
					caitlinNpcClass.Properties.CutsceneLookAt = playerClass:GetCFrame().Position;

				elseif mission.ProgressionPoint == 21 then
					caitlinNpcClass.Properties.CutsceneWalkTo = Vector3.new(1143.839, 57.916, 28.544);
					caitlinNpcClass.Properties.CutsceneLookAt = playerClass:GetCFrame().Position;
					
					josephNpcClass.Properties.CutsceneWalkTo = nil;
					josephNpcClass.Properties.CutsceneLookAt = nil;
					
					task.spawn(function()
						josephPlayerNpc:SetCFrame{
							MissionId = MISSION_ID;
						};
					end)

				end


			elseif shared.WorldName == "TheHarbor" then
				--MARK: TheHarbor
				if mission.ProgressionPoint == 2 then
					josephNpcClass:ToggleInteractable(false);
					josephPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(-271.475, 40.961, 230.21) * CFrame.Angles(0, math.rad(90), 0);
					};
					task.wait(0.5);

					local waitForPlayerComp = josephNpcClass:GetComponent("WaitForPlayer");
					waitForPlayerComp(8, function(playerDistance) 
						playerClass:SetCFrame(josephNpcClass:GetCFrame());
					end);
					if not game.Players:IsAncestorOf(player) then return end;

					josephNpcClass.Chat(player, "This should be their basement..");
					task.wait(4);
					if not game.Players:IsAncestorOf(player) then return end;
					
					josephNpcClass.Properties.CutsceneWalkToInteract = "ratTunnelExit";
					task.wait(0.2);
					josephNpcClass.Move.OnMoveToEnded:Wait(5);
					josephNpcClass.Properties.CutsceneWalkTo = nil;
            		josephNpcClass:UseInteractable("ratTunnelExit");

					task.wait(0.5);
					if not game.Players:IsAncestorOf(player) then return end;

					josephNpcClass:ToggleInteractable(true);
					josephNpcClass.Chat(player, "Okay, let's look for the walkies and get out quick..");
					josephNpcClass.Properties.CutsceneWalkTo = Vector3.new(-370.416, 40.961, 240.159);
					josephNpcClass.Move.OnMoveToEnded:Wait(10);
					
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 3;
					end)


				elseif mission.ProgressionPoint == 3 then
					josephNpcClass.PlayAnimation("CrossedArm");

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

					local waitForPlayerComp = josephNpcClass:GetComponent("WaitForPlayer");
					local boxInteractable: InteractableInstance = modInteractables.getOrNew(newBoxInteractConfig);
					waitForPlayerComp(nil, function(playerDistance) 
						return boxInteractable.Values.IsOpened == true;
					end);
					if not game.Players:IsAncestorOf(player) then return end;

					pcall(function()
						game.Debris:AddItem((newBoxInteractConfig.Parent :: Model):FindFirstChild("Decal", true), 0);
					end)
					newBoxInteractConfig:SetAttribute("_Label", "Empty Box");

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 4;
					end)


				elseif mission.ProgressionPoint == 4 then
					josephNpcClass.Properties.CutsceneWalkTo = nil;
					caitlinNpcClass.Properties.CutsceneEquip = "mp7";
					caitlinNpcClass:UseInteractable("ratDormitoryEntrance");
					caitlinNpcClass:GetComponent("AvatarFace"):Set("Angry");

					caitlinPlayerNpc:SetCFrame{
						MissionId = MISSION_ID;
						CFrame = CFrame.new(-368.642, 40.123, 226.758) * CFrame.Angles(0, math.rad(-90), 0);
					};
					task.wait(0.5);

					josephNpcClass.Chat(player, "*hmmf* ... uh.. hello..");
					josephNpcClass.Move:Face(caitlinNpcClass:GetCFrame().Position);
					josephNpcClass.StopAnimation("CrossedArm");
					josephNpcClass.PlayAnimation("Surrender");
					task.wait(3);
					if not game.Players:IsAncestorOf(player) then return end;

					caitlinNpcClass.Move:Face(josephNpcClass:GetCFrame().Position);
					modStatusEffects.DirectCamera(player, caitlinNpcClass.Head.Position, 3.5);

					local waitForPlayerComp = caitlinNpcClass:GetComponent("WaitForPlayer");
					waitForPlayerComp(64);
					caitlinNpcClass.Chat(player, "Stop right there!");


				elseif mission.ProgressionPoint == 5 then
					josephNpcClass.Move:MoveTo(Vector3.new(-369.49, 40.9, 231.19));
					josephNpcClass.Move:SetMoveSpeed("set", "cutscene", 5, josephNpcClass.Move.MoveSpeedPriority.Action, 5);
					josephNpcClass.StopAnimation("Surrender");
					josephNpcClass:ToggleInteractable(false);

					task.wait(4);
					if player.Parent == nil then return end;
					caitlinNpcClass.Properties.CutsceneEquip = nil;
					josephNpcClass.Move:Face(caitlinNpcClass.RootPart);
					caitlinNpcClass.Move:Face(josephNpcClass.RootPart);
					caitlinNpcClass.Chat(player, "... Your name sounds familar, have we met before?");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(5);
					if player.Parent == nil then return end;
					josephNpcClass.Chat(player, "... I don't believe we have..");
					josephNpcClass.Move:HeadTrack(caitlinNpcClass.Head, 3);

					task.wait(3);
					if player.Parent == nil then return end;
					caitlinNpcClass.Chat(player, "...");

					task.wait(2);
					if player.Parent == nil then return end;
					caitlinNpcClass.Chat(player, "Nevermind...");
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);

					task.wait(3);
					if player.Parent == nil then return end;
					caitlinNpcClass.Move:HeadTrack(playerClass.Head, 3);

					task.wait(0.5);
					caitlinNpcClass.Chat(player, `Alright {player.Name}, I can help you, but first you will have to take me to your friend's safehouse.`);

					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint <= 6 then
							mission.ProgressionPoint = 6;
						end
					end)
					task.wait(0.5);
					if player.Parent == nil then return end;
					modDialogueService:InvokeDialogue(player, "talk", {
						NpcModel = caitlinNpcClass.Character;
					});


				elseif mission.ProgressionPoint == 6 then
					caitlinNpcClass.Move:HeadTrack(playerClass.Head, 3);
					

				elseif mission.ProgressionPoint == 7 then
					caitlinNpcClass.Move:HeadTrack(josephNpcClass.Head, 3);
					josephNpcClass:ToggleInteractable(true);

					if not firstRun then
						task.wait(5);
						caitlinNpcClass.Chat(player, "Heh, I'm not like the idiots upstairs. When you're ready, let's go.");
						caitlinNpcClass.Move:HeadTrack(playerClass.Head, 3);
						
						task.wait(5);
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel = josephNpcClass.Character;
						});
					end


				end
			end


			--MARK: All worlds
			if mission.ProgressionPoint == 8 then
				local caitlinFollowPlayerComp = caitlinNpcClass:GetComponent("FollowPlayer");
				local caitlinFollowDist = 13;
				caitlinFollowPlayerComp(nil, function()
					return mission.Type == 1 and mission.ProgressionPoint == 8;
				end, caitlinFollowDist)
				if not game.Players:IsAncestorOf(player) then return end;

				local josephFollowPlayerComp = josephNpcClass:GetComponent("FollowPlayer");
				josephFollowPlayerComp(nil, function()
					return mission.Type == 1 and mission.ProgressionPoint == 8;
				end)
				if not game.Players:IsAncestorOf(player) then return end;

				josephNpcClass:ToggleInteractable(false);
				caitlinNpcClass:ToggleInteractable(false);
			end


		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);

	end)
	
	return CutsceneSequence;
end;