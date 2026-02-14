local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MissionLogic = {};
--==

local MISSION_ID = 81;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modNpcs = shared.modNpcs;

	--if not modBranchConfigurations.IsWorld("TheHarbor") then return MissionLogic end;
	if modBranchConfigurations.IsWorld("BioXResearch") then
		modNpcs.spawn2{
			Name = "Joseph";
			CFrame = CFrame.new(-50.208, -16.75, 23.504);
		};
		modNpcs.spawn2{
			Name = "Cooper";
			CFrame = CFrame.new(-55.208, -16.75, 23.504);
		};
		modNpcs.spawn2{
			Name = "David";
			CFrame = CFrame.new(-60.208, -16.75, 23.504);
		};
	end

	shared.modEventService:OnInvoked("FotlCardGame_BindNpcLose", function(eventPacket: EventPacket, ...)
		local gameLobby, loserNpcChar = ...;
		if eventPacket.Players == nil then return end;

		for _, player in pairs(eventPacket.Players) do
			if loserNpcChar.Name == "David" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 3 then
						mission.ProgressionPoint = 4;
					end

					local npcClass: NpcClass = modNpcs.getByModel(loserNpcChar);
					if npcClass then
						npcClass.Chat(player, `Well played {player.Name}!`);
						task.wait(3);
						npcClass.Chat(player, `Hope you can beat Cooper now.`);
					end
				end)

			elseif loserNpcChar.Name == "Cooper" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 4 then
						mission.ProgressionPoint = 5;
						mission.SaveData.CooperLost = 1;
					end
				end)

			end
		end
	end)
	shared.modEventService:OnInvoked("FotlCardGame_BindNpcWin", function(eventPacket: EventPacket, ...)
		local gameLobby, winnerNpcChar = ...;
		if eventPacket.Players == nil then return end;

		for _, player in pairs(eventPacket.Players) do
			if winnerNpcChar.Name == "Cooper" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.SaveData.CooperRematch == 1 then
						if mission.ProgressionPoint == 4 then
							mission.ProgressionPoint = 5;

							local npcClass: NpcClass = modNpcs.getByModel(winnerNpcChar);
							if npcClass then
								npcClass.Chat(player, `Begineer's luck!`);
							end
						end
					end

					mission.SaveData.CooperRematch = 1;
				end)
			end
		end
	end)

	shared.modEventService:OnInvoked("Character_BindEmote", function(eventPacket: EventPacket, ...)
		local player = eventPacket.Player;
		if player == nil then return end;

		local emoteId = ...;
		if emoteId == nil then return end;

		local modEmotesLibrary = shared.require(game.ReplicatedStorage.Library.EmoteAnimationsLibrary);
		local emoteLib = modEmotesLibrary:Find(emoteId);

		local isDance = emoteLib and emoteLib.IsDance == true;
		
		local cooperPrefab = workspace.Entity:FindFirstChild("Cooper");

		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 5 or mission.ProgressionPoint == 6 then
				if isDance then
					mission.ProgressionPoint = 7;
					
					task.wait(0.5);

					local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);
					if cooperPrefab then
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel=cooperPrefab;
						});
					end

				else

					local npcClass: NpcClass = cooperPrefab and modNpcs.getByModel(cooperPrefab);
					if npcClass then
						local notDanceMsg = {
							"You call that a dance?";
							"That's not exactly a dance..";
							"What was that?!";
						};
						
						if mission.CarlsonNotDanceTick == nil or tick()-mission.CarlsonNotDanceTick >= 1 then
							mission.CarlsonNotDanceTick = tick();
							npcClass.Chat(player, notDanceMsg[math.random(1,#notDanceMsg)]);
						end
					end

				end
			end
		end)
	end)

end

return MissionLogic;