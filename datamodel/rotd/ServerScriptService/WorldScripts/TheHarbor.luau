local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            local revasDoorTemplate = script:WaitForChild("RevasDoorway");
		    local newRevasDoor = revasDoorTemplate:Clone();
            newRevasDoor.Parent = workspace.Interactables;
            
            local doorInteractConfig = newRevasDoor:FindFirstChild("Interactable");
            local doorInteractable: InteractableInstance = modInteractables.getOrNew(doorInteractConfig);
            doorInteractable:SetPermissions("CanInteract", false);
            
            modReplicationManager.ReplicateOut({player}, newRevasDoor);

        end, 999);

        -- Harbor Rat Safehouse
        WorldCore.CaitlinClass = shared.modNpcs.spawn2{Name="Caitlin";};
        shared.modNpcs.spawn2{Name="Greg";};
        shared.modNpcs.spawn2{Name="Cooper";};
        shared.modNpcs.spawn2{Name="Lewis";};
        shared.modNpcs.spawn2{Name="David";};

        modGameModeManager:Initialize("Boss", "Vein Of Nekron");
    end
end


return WorldCore;