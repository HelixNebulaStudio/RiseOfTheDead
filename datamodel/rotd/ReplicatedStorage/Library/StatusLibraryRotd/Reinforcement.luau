local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Reinforcement";
    Icon="rbxassetid://6121421255";
    Name="Reinforcement";
    Description="A R.A.T. member is temporarily hired to assist you.";
    Buff=true;
    Cleansable=true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local namesList = {"Jesse"; "Diana"; "Frank"; "Maverick"; "Larry"};

    if playerClass.Properties.ReinforcementBuff ~= nil then
        playerClass.Properties.ReinforcementBuff:Destroy();
    end

    local npcName = namesList[math.random(1, #namesList)];

    local npcModel = shared.modNpcs.spawn(npcName, playerClass.RootPart.CFrame, function(npc, npcModule)
        npcModule.Humanoid.Name = "Pet";
        npcModule.Owner = playerClass:GetInstance();
    end, shared.require(game.ServerStorage.Prefabs.CustomNpcModules.PetNpcModule));

    playerClass.Properties.ReinforcementBuff = npcModel;
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    if playerClass.Properties.ReinforcementBuff ~= nil then
        playerClass.Properties.ReinforcementBuff:Destroy();
    end
end

return modStatusClass.new(statusPackage);