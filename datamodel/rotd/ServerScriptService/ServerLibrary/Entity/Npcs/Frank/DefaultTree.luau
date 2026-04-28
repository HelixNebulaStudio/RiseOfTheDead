local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PathfindingService = game:GetService("PathfindingService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local treePackage = {
    LogicString = {
        Default = "PreLogic | (InCutscene & [DoCutsceneState]) | [Idle]";
    };
    
	ShopStandCFrame = CFrame.new(621.303, 57.699, -63.932) * CFrame.Angles(0, math.rad(-177), 0);
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

    if modBranchConfigurations.IsWorld("TheWarehouse") 
    or modBranchConfigurations.IsWorld("BioXResearch") then
        if cutscenePlayersComp:IsCutsceneActive("71") then
            
            local isInsideShop = properties.IsInsideShop;
            if isInsideShop then
                local shopExitInteractable: InteractableInstance = modInteractables.getById("sundaysShopExit");
                shopExitInteractable:SetUserPermissions(npcClass.Name, "CanInteract", true);
                local shopExitPoint = shopExitInteractable.Part:WaitForChild("PathToInteract");

                if not npcClass.Move:IsAtPosition(shopExitPoint.WorldPosition) then
                    local pathToShopExit: Path = PathfindingService:FindPathAsync(
                        npcClass.RootPart.Position, 
                        shopExitPoint.WorldPosition
                    );
                    if pathToShopExit.Status ~= Enum.PathStatus.Success then
                        npcClass:UseInteractable(shopExitInteractable.Id);
                    else
                        npcClass.Move:MoveTo(shopExitPoint.WorldPosition);
                        return;
                    end
                    return;
                end

                properties.IsInsideShop = false;
                npcClass:UseInteractable(shopExitInteractable.Id);

            else
                npcClass.Move:MoveTo(Vector3.new(630.1, 57.7, -56.65));

            end

        end
    end
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local shopInteractable: InteractableInstance = modInteractables.getById("sundaysShopEntrance");
    local isInsideShop = properties.IsInsideShop;
    if isInsideShop == false then
        shopInteractable:SetUserPermissions(npcClass.Name, "CanInteract", true);
        local shopPoint = shopInteractable.Part:WaitForChild("PathToInteract");

        if not npcClass.Move:IsAtPosition(shopPoint.WorldPosition) then
            local pathToShopEntrance: Path = PathfindingService:FindPathAsync(
                npcClass.RootPart.Position, 
                shopPoint.WorldPosition
            );
            if pathToShopEntrance.Status ~= Enum.PathStatus.Success then
                npcClass:UseInteractable(shopInteractable.Id);
                properties.IsInsideShop = true;
            end
            npcClass.Move:MoveTo(shopPoint.WorldPosition);
            return;
        end

        properties.IsInsideShop = true;
        npcClass:UseInteractable(shopInteractable.Id);

    else
        if not npcClass.Move:IsAtPosition(treePackage.ShopStandCFrame.Position) then
            local pathToShopEntrance: Path = PathfindingService:FindPathAsync(
                npcClass.RootPart.Position, 
                treePackage.ShopStandCFrame.Position
            );
            if pathToShopEntrance.Status ~= Enum.PathStatus.Success then
                npcClass:UseInteractable(shopInteractable.Id);
                properties.IsInsideShop = true;
            end
            npcClass.Move:MoveTo(treePackage.ShopStandCFrame.Position);
            return;
        end

        npcClass.Move:Face(treePackage.ShopStandCFrame.Position + treePackage.ShopStandCFrame.LookVector*10);
    end

    return false;
end

return treePackage;