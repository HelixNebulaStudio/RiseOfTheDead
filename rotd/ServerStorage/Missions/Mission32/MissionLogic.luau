local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local MISSION_ID = 32;

local MissionLogic = {};
--==
if RunService:IsServer() then
    local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

    if modBranchConfigurations.IsWorld("EasterButchery") then
        shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
            local player: Player? = eventPacket.Player;
            if player == nil then return end;

            local interactable: InteractableInstance = ...;

            if interactable.Id == "easterDoor1" then
                modStatusEffects.Dizzy(player, 10);
                modMission:Progress(player, MISSION_ID, function(mission)
                    if mission.ProgressionPoint == 2 then 
                        mission.ProgressionPoint = 3;
                    end;
                end)
                
            end
        end)
    end
end

function MissionLogic.onRequire()
end

return MissionLogic;