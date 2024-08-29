local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local missionId = 81;
if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

	--if not modBranchConfigs.IsWorld("TheHarbor") then return MissionLogic end;

	modOnGameEvents:ConnectEvent("OnFotlLossNpc", function(npcPrefab)
		for _, player in pairs(game.Players:GetPlayers()) do

			if npcPrefab.Name == "David" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 3 then
						mission.ProgressionPoint = 4;
					end

					local npcModule = modNpc.GetNpcModule(npcPrefab);
					if npcModule and npcModule.Chat then
						npcModule.Chat(player, `Well played {player.Name}!`);
						task.wait(3);
						npcModule.Chat(player, `Hope you can beat Cooper now.`);
					end
				end)

			elseif npcPrefab.Name == "Cooper" then
				modMission:Progress(player, missionId, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 5;
						mission.SaveData.CooperLost = 1;
					end
				end)
			end
		end
	end)

	modOnGameEvents:ConnectEvent("OnFotlWonNpc", function(npcPrefab)
		for _, player in pairs(game.Players:GetPlayers()) do
			if npcPrefab.Name == "Cooper" then
				modMission:Progress(player, missionId, function(mission)
					if mission.SaveData.CooperRematch == 1 then
						if mission.ProgressionPoint <= 4 then
							mission.ProgressionPoint = 5;

							local npcModule = modNpc.GetNpcModule(npcPrefab);
							if npcModule and npcModule.Chat then
								npcModule.Chat(player, `Begineer's luck!`);
							end
						end
					end

					mission.SaveData.CooperRematch = 1;
				end)
			end
		end
	end)

	modOnGameEvents:ConnectEvent("OnEmote", function(player, emoteId)
		local modEmotesLibrary = require(game.ReplicatedStorage.Library.EmotesLibrary);
		local emoteLib = modEmotesLibrary:Find(emoteId);

		local isDance = emoteLib and emoteLib.IsDance == true;
		
		local cooperPrefab = workspace.Entity:FindFirstChild("Cooper");

		modMission:Progress(player, missionId, function(mission)
			if mission.ProgressionPoint == 5 or mission.ProgressionPoint == 6 then
				if isDance then
					mission.ProgressionPoint = 7;
					
					task.wait(0.5);

					local modDialogueService = require(game.ReplicatedStorage.Library.DialogueService);
					if cooperPrefab then
						modDialogueService:InvokeDialogue(player, "talk", {
							NpcModel=cooperPrefab;
						});
					end

				else

					local npcModule = cooperPrefab and modNpc.GetNpcModule(cooperPrefab);
					if npcModule and npcModule.Chat then
						local notDanceMsg = {
							"You call that a dance?";
							"That's not exactly a dance..";
							"What was that?!";
						};
						npcModule.Chat(player, notDanceMsg[math.random(1,#notDanceMsg)]);
					end

				end
			end
		end)

	end)

end

return MissionLogic;