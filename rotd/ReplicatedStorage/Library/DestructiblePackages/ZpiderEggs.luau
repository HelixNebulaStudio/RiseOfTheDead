local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local destructiblePackage = {
    Name = "ZpiderEggs";
};

function destructiblePackage.BindNew(destructible: DestructibleInstance)
    local healthComp: HealthComp = destructible.HealthComp;
    healthComp:SetMaxHealth(1000);
    healthComp:SetHealth(1000);

    if RunService:IsClient() then return end;


    local model: Model = destructible.Model;
    for _, obj in pairs(model:GetChildren()) do
        if obj.Name ~= "Decor" then continue end;
        if math.random(1, 2) ~= 1 then continue end;

        obj:Destroy();
    end
end

function destructiblePackage.BindDestroy(destructible: DestructibleInstance, damageData: DamageData, players)
    local model = destructible.Model;
    Debugger:Warn(`Zpider eggs destroyed`);

    task.spawn(function()
        for a=1, math.random(1, 4) do
            local spawnCf = model:GetPivot() + Vector3.new(math.random(-100, 100)/100, 2, math.random(-100, 100)/100);

            shared.modNpcs.spawn2{
                Name = "Zpiderling";
                CFrame = spawnCf;
                Properties = {
                    Level = math.max(1, (destructible.Config:GetAttribute("Level") :: number) or 1);
                    MoneyReward = NumberRange.new(5, 10);
                    BaseExperience = 2;
                    TargetableDistance = 4096;
                };
                BindSetup = function(npcClass: NpcClass)
                    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

                    if damageData.DamageBy and damageData.DamageBy.Character then
                        targetHandlerComp:AddTarget(damageData.DamageBy.Character);
                        
                    else
                        local playerClassList = shared.modPlayers.listInRange(spawnCf.Position, 1024);
                        for a=1, #playerClassList do
                            local playerClass: PlayerClass = playerClassList[a];
                            if playerClass == nil or playerClass.HealthComp == nil or playerClass.HealthComp.IsDead then continue end;

                            targetHandlerComp:AddTarget(playerClass.Character);
                        end

                    end
                end;
            };
        end
    end)
end

return destructiblePackage;