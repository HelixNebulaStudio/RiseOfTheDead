local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 14;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if not RunService:IsServer() then return end;
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if not modBranchConfigurations.IsWorld("TheWarehouse") then return end;

	shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;

		if interactable.Id == "sundaysEntrance" then
			modMission:Progress(player, MISSION_ID, function(mission) 
				if mission.ProgressionPoint < 2 then 
					mission.ProgressionPoint = 2; 
				end;
			end)

		end
	end)
end

return MissionLogic;