local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);

local MISSION_ID = 57;

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeCoop = shared.require(game.ServerScriptService.ServerLibrary.GameModeCoop);
    modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

    modGameModeManager.GameWorld = true;

    shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
        local player: Player? = event.Player;
        if player == nil then return end;

        local triggerId: string, interactable: InteractableInstance = ...;
        if triggerId == "TakeMrKlawsJournal" then 
			if not modMission:IsComplete(player, MISSION_ID) then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 2 then
						mission.ProgressionPoint = 3;
					end
				end)
			end
        end;

    end)
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Coop", "Mr. Klaw's Workshop";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeCoop.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    
    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);
end

return WorldCore;