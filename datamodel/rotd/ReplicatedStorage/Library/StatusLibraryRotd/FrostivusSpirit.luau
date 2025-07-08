local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
--==
local statusPackage = {
    Id = "FrostivusSpirit";
    Icon = "rbxassetid://4534155688";
    Name = "Frostivus Spirit";
    Description = "Buff adds +$Amount bonus damage. For every kill you get, increases bonus damage by 20. You lose 20 damage every 3 seconds. (Max Stacks: 10'000 damage)";
    QuantityLabel = "Amount";
    Buff = true;
    PresistUntilExpire = {"Duration"; "Amount"};
};

function statusPackage.init()
    if RunService:IsServer() then
        local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
        modOnGameEvents:ConnectEvent("OnZombieDeath", function(zombieNpcModule)
            local playerTags = modDamageTag:Get(zombieNpcModule.Prefab, "Player");
            for _, playerTag in pairs(playerTags) do
                local player = playerTag.Player;

		        local playerClass: PlayerClass = shared.modPlayers.get(player);
                if playerClass == nil then continue end;

                local statusClass: StatusClassInstance = playerClass.StatusComp:GetOrDefault(statusPackage.Id);
                if statusClass == nil then continue end;

                statusClass.Values.Amount = math.min(statusClass.Values.Amount +20, 10000);

                local modifier = statusClass.Values.Modifier;
                if modifier then
                    modifier.SumValues.Damage = statusClass.Values.Amount;
                end

                statusClass:Sync();
            end
        end)
    end
end

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    local modifier: ItemModifierInstance = characterClass.Configurations:GetModifier(statusPackage.Id);
    if modifier == nil then
        modifier = characterClass.Configurations.newModifier(statusPackage.Id);

        modifier.Tags.Gun = true;
        modifier.SumValues.Damage = statusClass.Values.Amount;
    end

    characterClass.Configurations:AddModifier(modifier);
    statusClass.Values.Modifier = modifier;
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    if characterClass == nil then return end;

    characterClass.Configurations:RemoveModifier(statusPackage.Id);
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 == false then return end

    if statusClass.Values.LastTick == nil then
        statusClass.Values.LastTick = tick();
    end

    if tick()-statusClass.Values.LastTick >= 3 then
        statusClass.Values.LastTick = tick();

        if statusClass.Values.Amount > 0 then
            statusClass.Values.Amount = math.max(statusClass.Values.Amount-20, 0);

            local modifier = statusClass.Values.Modifier;
            if modifier then
                modifier.SumValues.Damage = statusClass.Values.Amount;
            end

            return true;
        end
    end

    return;
end

return modStatusClass.new(statusPackage);