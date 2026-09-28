local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PathfindingService = game:GetService("PathfindingService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);

local treePackage = {
    LogicString = {
        Default = "PreLogic | (InCutscene & [DoCutsceneState]) | [Idle]";
    };
    
	ShopStandCFrame = CFrame.new(-11.3109531, 57.6494408, 18.8490143, 0, 0, -1, 0, 1, 0, 1, 0, 0);
}

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.InCutscene(npcClass: NpcClass)
    local cutscenePlayersComp = npcClass:GetComponent("CutscenePlayers");
    return cutscenePlayersComp:HasPlayers();
end

function treePackage.DoCutsceneState(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local cutscenePlayersComp = npcClass:GetComponent("CutscenePlayers");

    if shared.WorldName == "TheWarehouse" or shared.WorldName == "BioXResearch" then
        if cutscenePlayersComp:IsCutsceneActive("16")
        or cutscenePlayersComp:IsCutsceneActive("17") then
            
            local shopDoorInteractable = modInteractables.getById("warehouseShopDoor");
            if shopDoorInteractable then
                shopDoorInteractable:SetUserPermissions(npcClass.Name, "CanInteract", true);
            end

            local outsideShopPos = Vector3.new(7.18, 57.6, 30.76);
            if not npcClass.Move:IsAtPosition(outsideShopPos) then
                npcClass.Move:MoveTo(outsideShopPos);
                return;
            end

        end
    end
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local insideShopPos = treePackage.ShopStandCFrame.Position;
    local isInsideShop = npcClass.Move:IsAtPosition(insideShopPos);
    if isInsideShop == false then
        npcClass.Move:MoveTo(insideShopPos);
        return;

    else
        if shared.WorldName == "TheWarehouse" or shared.WorldName == "BioXResearch" then
            local shopDoorInteractable = modInteractables.getById("warehouseShopDoor");
            if shopDoorInteractable then
                local door: DoorInstance = modDoors.getOrNew(shopDoorInteractable.Values.DoorConfig);
                if door then
                    door:Toggle(false);
                end
            end
        end

        npcClass.Move:Face(treePackage.ShopStandCFrame.Position + treePackage.ShopStandCFrame.LookVector*10);
    end

    return false;
end

return treePackage;