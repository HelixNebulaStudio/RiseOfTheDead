local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MISSION_ID = 4;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if not RunService:IsServer() then return end;

	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

	if not modBranchConfigs.IsWorld("TheWarehouse") then return; end;
	
	shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
		local npcClass: NpcClass = ...;
		if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
				
		local playerTags = modDamageTag:Get(npcClass.Character, "Player");
		for a=1, #playerTags do
			local playerTag = playerTags[a];
			local player: Player = playerTag.Player;
			if player == nil or not game.Players:IsAncestorOf(player) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission: Mission)
				if mission.ObjectivesCompleted.ArmSearch then return end;
				mission.SaveData.Kills = (mission.SaveData.Kills or 0) +1;
				if math.random(1, 6) > 1 and mission.SaveData.Kills <= 10 then return end;

				local new = modItemDrops.Spawn(
					{ItemId="zombiearm"; OnceOnly=true;}, 
					npcClass.RootPart.CFrame, 
					player
				);
				modReplicationManager.ReplicateIn(player, new, workspace.Interactables);
			end)

		end
	end)
end

return MissionLogic;