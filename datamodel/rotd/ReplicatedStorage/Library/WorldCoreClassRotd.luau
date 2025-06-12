
local RunService = game:GetService("RunService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClass);

if RunService:IsServer() then
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
    local npcClass = shared.modNpcs.spawn2{
        Name = npcName;
        Owner = player;
    };
    modReplicationManager.ReplicateOut(player, npcClass.Character);
    return npcClass;
end

return modWorldCoreClass;
