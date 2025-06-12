local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);

end

local DEADBODY_ID = 1;
local GIFT_SPAWNCF = CFrame.new(689.499939, 69.1379852, -74.0011292, 1, 0, 0, 0, 1, 0, 0, 0, 1);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()

    if RunService:IsServer() then --MARK: IsServer
        local DEADBODY_MODEL = script:WaitForChild("Deadbody");

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            if player.UserId == DEADBODY_ID then
                DEADBODY_MODEL.Parent = game.ServerStorage;
            end

            WorldCore:SpawnGift(player, "sundaysGift", GIFT_SPAWNCF);
            WorldCore:SpawnPlayerNpc("Wilson");

        end, 999);

        shared.modEngineCore:ConnectOnPlayerRemoved(script, function(player: Player)
            if player.UserId == DEADBODY_ID then
                DEADBODY_MODEL.Parent = workspace.Entity;
            end
        end)
        DEADBODY_MODEL.Parent = workspace.Entity;
        modAudio.Play("Flies", DEADBODY_MODEL.PrimaryPart, true);

        -- Safehouse 1
        shared.modNpcs.spawn2{Name="Russell";};
        shared.modNpcs.spawn2{Name="Stephanie";};
        shared.modNpcs.spawn2{Name="Dr. Deniski";};
        shared.modNpcs.spawn2{Name="Nick";};
        shared.modNpcs.spawn2{Name="Jefferson";};

        -- Safehouse 2
        shared.modNpcs.spawn2{Name="Carlos";};
        shared.modNpcs.spawn2{Name="Frank";};
        shared.modNpcs.spawn2{Name="Jane";};
        shared.modNpcs.spawn2{Name="Michael";};
        
        modGameModeManager:Initialize("Raid", "Tombs");


    elseif RunService:IsClient() then --MARK: IsClient


    end
end

return WorldCore;