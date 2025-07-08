
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClass);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);

end
--==
function modWorldCoreClass.onRequire()

end


function modWorldCoreClass:SpawnGift(player: Player, giftId: string, giftCf: CFrame)
    local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;

    local content = {};
    if modEvents:GetEvent(player, giftId) == nil then
        modEvents:NewEvent(player, {Id=giftId});
        content = modCrates.GenerateRewards(giftId);
    end

    profile.Garbage:Tag(modCrates.spawn(giftId, giftCf, {player}, content, true));
end


function modWorldCoreClass:SpawnPlayerNpc(player: Player, npcName: string)
    local npcClass = shared.modNpcs.getByOwner(player, npcName);
    if npcClass == nil then
        npcClass = shared.modNpcs.spawn2{
            Name = npcName;
            Owner = player;
        };
        if npcClass then
            modReplicationManager.ReplicateOut(player, npcClass.Character);
        end
    end
    return npcClass;
end


function modWorldCoreClass:InitGameWorld(gameMode, gameStage)
    local isHard = false;
    if RunService:IsStudio() then
        if workspace:GetAttribute("IsHard") == true then
            isHard = true;
        end
    end

    local studioLobbyData = {
        GameMode={
            Type=gameMode;
            Stage=gameStage;
            Room={
                MaxPlayers=1;
                Players={};
                IsHard=isHard;
            };
        };
    };
    modGameModeManager.StudioData = studioLobbyData;

    local waitingforFirstPlayer = true;
    local gameModeStart = false;
    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        if RunService:IsStudio() or modBranchConfigs.CurrentBranch.Name == "Dev" then
            local lobbyPlayers = studioLobbyData.GameMode.Room.Players;
            for _, player in pairs(game.Players:GetPlayers()) do
                table.insert(lobbyPlayers, {Name=player.Name; UserId=player.UserId});
            end
        end
        
        if waitingforFirstPlayer then
            waitingforFirstPlayer = false;

            task.wait(3);
            gameModeStart = true;
            for _, p in pairs(game.Players:GetPlayers()) do
		        modGameModeManager:OnPlayerJoin(p);
            end

        elseif gameModeStart then
		    modGameModeManager:OnPlayerJoin(player);
        end
    end)
end


return modWorldCoreClass;
