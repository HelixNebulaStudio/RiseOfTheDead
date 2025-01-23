local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
--==
local statusPackage = {
    Id="FrostivusSpirit";
    Icon="rbxassetid://4534155688";
    Name="Frostivus Spirit";
    Description="Buff adds +$Amount bonus damage. For every kill you get, increases bonus damage by 20. You lose 20 damage every 3 seconds. (Max Stacks: 10'000 damage)";
    QuantityLabel="Amount";
    Buff=true;
};

function statusPackage.init()
    if RunService:IsServer() then
        local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
        modOnGameEvents:ConnectEvent("OnZombieDeath", function(zombieNpcModule)
    
            local playerTags = modDamageTag:Get(zombieNpcModule.Prefab, "Player");
            for _, playerTag in pairs(playerTags) do
                local player = playerTag.Player;
                
		        local classPlayer = shared.modPlayers.Get(player);
                if classPlayer == nil then continue end;

                local statusId = statusPackage.Id;

                local statusClass = classPlayer:GetStatus(statusId);
                if statusClass == nil then continue end;

                statusClass.Amount = math.min(statusClass.Amount +20, 10000);

                local modifier = statusClass.Modifier;
                if modifier then
                    modifier.AddValues.Damage = statusClass.Amount;
                end

                classPlayer:SyncStatus(statusId);
            end
        end)
    end
end

function statusPackage:OnApply()
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
    
    local modifier = playerClass.Configurations:GetModifier(statusPackage.Id);
    if modifier == nil then
        modifier = playerClass.Configurations.newModifier(statusPackage.Id);

        modifier.IsEquipmentModifier = true; 
        modifier.AddValues.Damage = self.Amount;
    end

    playerClass.Configurations:AddModifier(modifier);
    self.Modifier = modifier;
end

function statusPackage:OnExpire()
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    playerClass.Configurations:RemoveModifier(statusPackage.Id);
end

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    if tickPack.ms1000 == false then return end

    if self.LastTick == nil then
        self.LastTick = tick();
    end

    if tick()-self.LastTick >= 3 then
        self.LastTick = tick();

        if self.Amount > 0 then
            self.Amount = math.max(self.Amount-20, 0);

            local modifier = self.Modifier;
            if modifier then
                modifier.AddValues.Damage = self.Amount;
            end

            return true;
        end
    end

    return;
end

return modStatusClass.new(statusPackage);