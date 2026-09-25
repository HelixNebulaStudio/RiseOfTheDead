local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modPlayerNpcs = shared.require(game.ReplicatedStorage.Library.PlayerNpcs);

--== Variables;
local MISSION_ID = 88;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if shared.WorldName == "RadioStation" then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;
			
			if interactable.Id == "radioStationEnter" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 6 then
						mission.ProgressionPoint = 6;
					end;
				end)
			end
		end)
	end

else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

end

--== Script;
return function(CutsceneSequence)

	--MARK: TheResidentials
	if shared.WorldName == "TheResidentials" then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local playerClass: PlayerClass = shared.modPlayers.get(player);
			local caitlinPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Caitlin");
			local caitlinNpcClass: NpcClass = caitlinPlayerNpc.NpcClass;

			caitlinPlayerNpc:SetCFrame{
				CFrame = CFrame.new(1143.839, 57.916, 28.544);
				MissionId = MISSION_ID;
			};

			local TRANSMISSION_MP = 1;
			local function runTransmission()
				caitlinNpcClass:ToggleInteractable(false);
				task.wait(0.5);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;

				local playerPos = playerClass.Head.Position;
				local rootPos = caitlinNpcClass.RootPart.Position;
				caitlinNpcClass.Move:Face(rootPos + (rootPos - playerPos).Unit * 6);

				task.wait(0.3);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;

				caitlinNpcClass.Properties.CutsceneEquip = "walkietalkie";
				task.wait(1);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;

				pcall(function()
					modAudio.Play("RadioChatter", caitlinNpcClass.RootPart);
				end)
				task.wait(3);

				caitlinNpcClass.Chat(player, "Calling November Sierra Romeo.. This is callsign Viper Over..");

				task.wait(5);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;
				caitlinNpcClass.Chat(player, "Yes sir. Target located.");

				task.wait(5);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;
				caitlinNpcClass.Chat(player, "No sir. He's sending a messenger first.");

				task.wait(5);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;
				caitlinNpcClass.Chat(player, "Roger, the Radio Station nearby?");

				task.wait(5);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;
				caitlinNpcClass.Chat(player, "Understood, sir. Asset en route for verification.");

				task.wait(4);
				if not game.Players:IsAncestorOf(player) or mission.ProgressionPoint ~= TRANSMISSION_MP then return end;

				caitlinNpcClass.Properties.CutsceneEquip = nil;
				caitlinNpcClass.Move:Face(playerPos);
				caitlinNpcClass.Move:HeadTrack(playerClass.Head, 3);
				caitlinNpcClass:ToggleInteractable(true);

				mission.SaveData.TransmissionDone = true;
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 3 then
						mission.ProgressionPoint = 3;
					end
				end)
			end

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable

				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == TRANSMISSION_MP then
						if firstRun and mission.SaveData.TransmissionDone then
							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint <= 2 then
									mission.ProgressionPoint = 2;
								end
							end)
							return;
						end

						task.spawn(function()
							while mission.ProgressionPoint == TRANSMISSION_MP and not mission.SaveData.TriggerTransmission do
								if not game.Players:IsAncestorOf(player) then return end;
								task.wait(0.5);
							end

							if mission.ProgressionPoint ~= TRANSMISSION_MP then return end;
							runTransmission();
						end)


					elseif mission.ProgressionPoint == 2 then


					end

				elseif mission.Type == 3 then -- OnComplete

				end
			end
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

	--MARK: RadioStation
	elseif shared.WorldName == "RadioStation" then
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;

			local playerClass: PlayerClass = shared.modPlayers.get(player);
			local caitlinPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Caitlin");
			local caitlinNpcClass: NpcClass = caitlinPlayerNpc.NpcClass;

			caitlinPlayerNpc:SetCFrame{
				CFrame = CFrame.new(1134.713, 109.495, -547.812) * CFrame.Angles(0, math.rad(44), 0);
				MissionId = MISSION_ID;
			};

			
			local leoPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Leo");
			local leoNpcClass: NpcClass = leoPlayerNpc.NpcClass;

			local skinnerPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Skinner");
			local skinnerNpcClass: NpcClass = skinnerPlayerNpc.NpcClass;

			local rexPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Rex");
			local rexNpcClass: NpcClass = rexPlayerNpc.NpcClass;

			local shawPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Shaw");
			local shawNpcClass: NpcClass = shawPlayerNpc.NpcClass;

			local walterPlayerNpc: PlayerNpc = modPlayerNpcs.getPlayerNpc(player, "Walter");
			local walterNpcClass: NpcClass = walterPlayerNpc.NpcClass;


			local function OnChanged(firstRun)
				if mission.Type == 2 then
				elseif mission.Type == 1 then
					if mission.ProgressionPoint <= 3 then
						if firstRun then
							caitlinNpcClass.PlayAnimation("Wave");
							modMission:Progress(player, MISSION_ID, function(mission)
								if mission.ProgressionPoint <= 4 then
									mission.ProgressionPoint = 4;
								end
							end)
						end

					elseif mission.ProgressionPoint == 5 then
						
						leoPlayerNpc:SetCFrame{
							CFrame = CFrame.new(1165.333, 100.474, -525.591) * CFrame.Angles(0, 0, 0);
							MissionId = MISSION_ID;
						};
						
						skinnerPlayerNpc:SetCFrame{
							CFrame = CFrame.new(1181.051, 100.443, -532.333) * CFrame.Angles(0, math.rad(30), 0);
							MissionId = MISSION_ID;
						};

						rexPlayerNpc:SetCFrame{
							CFrame = CFrame.new(1150.337, 96.092, -550.614) * CFrame.Angles(0, math.rad(-90), 0);
							MissionId = MISSION_ID;
						};

						shawPlayerNpc:SetCFrame{
							CFrame = CFrame.new(1173.018, 96.092, -548.408) * CFrame.Angles(0, math.rad(55), 0);
							MissionId = MISSION_ID;
						};

						walterPlayerNpc:SetCFrame{
							CFrame = CFrame.new(1157.919, 96.092, -539.78) * CFrame.Angles(0, math.rad(-23), 0);
							MissionId = MISSION_ID;
						}

						local nWeld = walterNpcClass.Character:WaitForChild("MaskWeld"):Clone();
						local oWeld = walterNpcClass.Character:WaitForChild("Gas Mask"):WaitForChild("Handle"):WaitForChild("AccessoryRigidConstraint");

						oWeld.Enabled = false;
						nWeld.Parent = oWeld.Parent;
						nWeld.Part0 = nWeld.Parent;
						nWeld.Part1 = walterNpcClass.Head;

						leoNpcClass:ToggleInteractable(false);
						skinnerNpcClass:ToggleInteractable(false);
						rexNpcClass:ToggleInteractable(false);
						shawNpcClass:ToggleInteractable(false);
						walterNpcClass:ToggleInteractable(false);

						walterNpcClass.Move:Face(leoNpcClass:GetCFrame().Position);
						shawNpcClass.Move:Face(walterNpcClass:GetCFrame().Position);

					elseif mission.ProgressionPoint == 6 then

						mission.Cache.LowTension = modAudio.Play("Soundtrack:LowTension", workspace)
						mission.Cache.LowTension.Volume = 0.4;

						task.wait(3);
						walterNpcClass.Chat(player, "That's not possible. Moving that many bodies..");
						
						task.wait(5);
						leoNpcClass.Chat(player, "Just get it done!");

					end
				end
			end
			
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)

	end

	return CutsceneSequence;
end;