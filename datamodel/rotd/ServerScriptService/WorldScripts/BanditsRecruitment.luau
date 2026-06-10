local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

if RunService:IsServer() then
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsServer() then --MARK: IsServer
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            WorldCore:LoadPlayerMissions(player, profile);

        end, 999);
    end
end

function WorldCore:LoadPlayerMissions(player: Player, profile: ProfileRotd)
	local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
	local missionsProfile: MissionsProfile = gameSave and gameSave.Missions;

    local mission63 = modMission:GetMission(player, 63);
    if mission63 and mission63.Type == 1 then
        game.Players:SetAttribute("AutoRespawn", true);
    end
end

return WorldCore;