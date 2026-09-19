local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local MISSION_ID = 21;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil then return end;

		local bossName = npcClass.Name;
		if npcClass.Name ~= "The Prisoner" and npcClass.Name ~= "Tanker" and npcClass.Name ~= "Fumes" then return end;

		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			if modMission:IsComplete(player, MISSION_ID) then continue end

			modMission:Progress(player, MISSION_ID, function(mission)
				mission.ObjectivesCompleted[bossName] = true;
			end)

		end
	end)
end

return MissionLogic;