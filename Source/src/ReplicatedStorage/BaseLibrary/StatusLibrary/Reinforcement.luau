local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Reinforcement";
    Icon="rbxassetid://6121421255";
    Name="Reinforcement";
    Description="A R.A.T. member is temporarily hired to assist you.";
    Buff=true;
    Cleansable=true;
};

function statusPackage:OnApply()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local namesList = {"Jesse"; "Diana"; "Frank"; "Maverick"; "Larry"};
    
    if playerClass.Properties.ReinforcementBuff ~= nil then
        playerClass.Properties.ReinforcementBuff:Destroy();
    end

    local npcName = namesList[math.random(1, #namesList)];

    local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
    local npcModel = modNpc.Spawn(npcName, playerClass.RootPart.CFrame, function(npc, npcModule)
        npcModule.Humanoid.Name = "Pet";
        npcModule.Owner = playerClass:GetInstance();
    end, require(game.ServerStorage.PrefabStorage.CustomNpcModules.PetNpcModule));

    playerClass.Properties.ReinforcementBuff = npcModel;
end

function statusPackage:OnExpire()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    if playerClass.Properties.ReinforcementBuff ~= nil then
        playerClass.Properties.ReinforcementBuff:Destroy();
    end
end

return modStatusClass.new(statusPackage);