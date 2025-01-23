local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
--==
local statusPackage = {
    Id="MaxHeal";
    Icon="rbxassetid://2770153676";
    Name="Healing From Healer";
    Description="Heals 10% of max health per second.";
    Buff=true;
};

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    if tickPack.ms500 == false then return end;
    
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end

    if playerClass.Humanoid == nil or playerClass.IsAlive ~= true then
        self.Expires = modSyncTime.GetTime();
        return true;
    end

    local healthPool = playerClass.Humanoid.MaxHealth;
    local armorPool = playerClass.Properties.MaxArmor;

    local rate = self.Rate or 0.1;

    local totalHeal = 0;

    if math.ceil(playerClass.Humanoid.Health)+5 <= self.InitHealth then
        self.Expires = modSyncTime.GetTime();
        return true;
    end

    local healAmount = (playerClass.Humanoid.MaxHealth * rate);
    healAmount = math.clamp(healAmount, 0, playerClass.Humanoid.MaxHealth-playerClass.Humanoid.Health);

    if healAmount > 0 and healthPool > 0 then
        playerClass:TakeDamagePackage(modDamagable.NewDamageSource{
            Damage=healAmount;
            TargetPart=playerClass.RootPart;
            DamageType="Heal";
        })
        healthPool = healthPool - healAmount;
        
        totalHeal = totalHeal + healAmount;
    end;
    
    
    if playerClass.Properties.Armor < playerClass.Properties.MaxArmor then
        local regenAmount = (playerClass.Properties.MaxArmor * (rate or 0.1));
        
        regenAmount = math.max(regenAmount, 1);
        regenAmount = math.clamp(regenAmount, 0, playerClass.Properties.MaxArmor-playerClass.Properties.Armor);
        
        if regenAmount > 0 and armorPool > 0 then
            playerClass.Properties.Armor = playerClass.Properties.Armor + regenAmount;
            
            armorPool = armorPool - regenAmount;
            totalHeal = totalHeal + regenAmount;
        end
    end

    if totalHeal <= 0 then
        self.Expires = modSyncTime.GetTime();
        return true;
    end

    return;
end

return modStatusClass.new(statusPackage);