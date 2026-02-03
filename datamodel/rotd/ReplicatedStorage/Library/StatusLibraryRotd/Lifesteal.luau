local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

--==
local statusPackage = {
    Id="Lifesteal";
    Icon="rbxassetid://6129813061";
    Name="Lifesteal";
    Description="For every kill, you heal by +$Amount health.";
    Buff=true;
    Cleansable=true;
    PresistUntilExpire = {"Duration"; "Amount"};
};

function statusPackage.init()
    if RunService:IsServer() then
        shared.modEventService:OnInvoked("Npcs_BindDeath", function(eventPacket: EventPacket, ...)
            local npcClass: NpcClass = ...;
            if npcClass == nil or npcClass.HumanoidType ~= "Zombie" then return end;
        
            local playerTags = modDamageTag:Get(npcClass.Character, "Player");
            for a=1, #playerTags do
                local playerTag = playerTags[a];
                local player: Player = playerTag.Player;
                if player == nil or not game.Players:IsAncestorOf(player) then continue end;

                local playerClass: PlayerClass = shared.modPlayers.get(player);
                if playerClass == nil then continue end;

                local statusClass: StatusClassInstance = playerClass.StatusComp:GetOrDefault(statusPackage.Id);
                if statusClass == nil then continue end;

				local healAmount = statusClass.Values.Amount;

				local healthComp: HealthComp? = playerClass.HealthComp;
                if healthComp == nil then continue end;
                
                local dmgData = DamageData.new{
                    Damage = -healAmount;
                    DamageBy = player;
                    DamageType = "Heal";
                };
                
                healthComp:TakeDamage(dmgData);
            end
        end)
    end
end

return modStatusClass.new(statusPackage);
