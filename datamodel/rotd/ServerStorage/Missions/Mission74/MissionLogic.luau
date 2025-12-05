local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local MISSION_ID = 74;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
		local triggerId: string = ...;
		if triggerId == "SafehomeBreach_RepairWall" then 
			local player = event.Player;
			if player == nil then return end;

			modMission:Progress(player, MISSION_ID, function(mission)
				mission.ProgressionPoint = 2;
			end)
		
		elseif triggerId == "SafehomeBreach_EventEnd" then
			for _, oPlayer in pairs(game.Players:GetPlayers()) do
				local mission = modMission:GetMission(oPlayer, MISSION_ID);
				if mission and mission.ProgressionPoint == 2 then
					modMission:CompleteMission(oPlayer, MISSION_ID);
				end
			end
		end;
	end)


	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
		
		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission)
				mission.ProgressionPoint = 2;
			end)
		end
	end)

end

return MissionLogic;