local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

--==
local statusPackage = {
    Id="Lifesteal";
    Icon="rbxassetid://6129813061";
    Name="Lifesteal";
    Description="For every kill, you heal by +$Amount health.";
    Buff=true;
    Cleansable=true;
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

				local healAmount = statusClass.Amount;
				
				classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage = healAmount;
					Dealer = player;
					TargetPart = classPlayer.RootPart;
					DamageType = "Heal";
				});
            end
        end)
    end
end

return modStatusClass.new(statusPackage);