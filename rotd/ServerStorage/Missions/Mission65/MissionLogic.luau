local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local MissionLogic = {};

local MISSION_ID = 65;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass, damageData: DamageData = ...;
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
		if damageData == nil then return end;

		local isOnFire = false;

		if damageData.DamageType == "Fire" then
			isOnFire = true;
		end
		
		if not isOnFire then
			local statusComp: StatusComp = npcClass.StatusComp;
			isOnFire = #statusComp:ListStatusWithTags{"Fire"} > 0;
		end

		if not isOnFire then return end;

		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			if modMission:IsComplete(player, MISSION_ID) then continue end;
			modMission:Progress(player, MISSION_ID, function(mission)
				mission.SaveData.Kills = mission.SaveData.Kills -1;
				if mission.SaveData.Kills <= 0 then
					modMission:CompleteMission(player, MISSION_ID);
				end
			end)
		end
	end)

end

return MissionLogic;