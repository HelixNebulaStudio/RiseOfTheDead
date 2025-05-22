local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local missionId = 21;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnZombieDeath", function(zombieNpcModule)
		local bossName;
		if zombieNpcModule.Name == "The Prisoner" or zombieNpcModule.Name == "Tanker" or zombieNpcModule.Name == "Fumes" then
			bossName = zombieNpcModule.Name;
		end

		if bossName == nil then return end;

		local playerTags = modDamageTag:Get(zombieNpcModule.Prefab, "Player");
		for _, playerTag in pairs(playerTags) do
			local player = playerTag.Player;
			if modMission:IsComplete(player, missionId) then continue end

			modMission:Progress(player, missionId, function(mission)
				mission.ObjectivesCompleted[bossName] = true;
			end)
			
		end
	end)

end

return MissionLogic;