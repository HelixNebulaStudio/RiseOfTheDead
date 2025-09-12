local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "FollowPlayer";
    };
}

function treePackage.FollowPlayer(npcClass: NpcClass, followDist: number?, followSpeed: number?)
    local player: Player = npcClass.Properties.FollowingPlayer or npcClass.Player;
    if player == nil then return false end;

    local followRootPart = player.Character and player.Character.PrimaryPart;
    if followRootPart and workspace:IsAncestorOf(followRootPart) then
        local distance = player:DistanceFromCharacter(npcClass.RootPart.Position);

        if distance >= 64 then
            npcClass.RootPart.CFrame = followRootPart.CFrame;
            
        elseif distance >= 16 then
            npcClass.Move:SetMoveSpeed("set", "sprint", followSpeed or 25, 2, 0.3);
            
        else
            npcClass.Move:SetMoveSpeed("set", "walk", followSpeed and followSpeed/2 or 10, 2, 0.3);
            
        end
        
        npcClass.Move:Follow(followRootPart, followDist or 5, 2);
    end

    return true;
end

return treePackage;