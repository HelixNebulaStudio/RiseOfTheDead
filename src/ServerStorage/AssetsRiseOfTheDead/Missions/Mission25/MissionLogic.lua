local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

local missionId = 25;
if RunService:IsServer() then
	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnZombieDeath", function(zombieNpcModule)
		if zombieNpcModule.Configuration == nil or zombieNpcModule.Configuration.SantaHat == nil then return end;

		local playerTags = modDamageTag:Get(zombieNpcModule.Prefab, "Player");
		for _, playerTag in pairs(playerTags) do
			local player = playerTag.Player;
			if modMission:IsComplete(player, missionId) then continue end

			modMission:Progress(player, missionId, function(mission)
				if mission.SaveData.Kills > 0 then
					mission.SaveData.Kills = mission.SaveData.Kills -1;
				end
				if mission.SaveData.Kills <= 0 then
					mission.ProgressionPoint = 2;
				end
			end)
			
		end
	end)
end

return MissionLogic;