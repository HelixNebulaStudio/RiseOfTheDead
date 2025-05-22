local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local missionId = 74;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnEventPoint", function(pointName, packet)
		if pointName == "SafehomeBreach_RepairWall" then 
			local player = packet.Player;
	
			modMission:Progress(player, missionId, function(mission)
				mission.ProgressionPoint = 2;
			end)

		elseif pointName == "SafehomeBreach_EventEnd" then
			for _, player in pairs(game.Players:GetPlayers()) do
				local mission = modMission:GetMission(player, missionId);
				if mission and mission.ProgressionPoint == 2 then
					modMission:CompleteMission(player, missionId);
				end
			end

		end;
	end)

	
	modOnGameEvents:ConnectEvent("OnZombieDeath", function(npcModule)
		if npcModule.SafehomeBreach == nil then return end;
		
		local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");

		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player = playerTag.Player;

			modMission:Progress(player, missionId, function(mission)
				mission.ProgressionPoint = 2;
			end)
		end
	end);

end

return MissionLogic;