local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
--==
local statusPackage = {
    Id="WarmongerScales";
    Icon="rbxassetid://16084490297";
    Name="Warmonger's Scales";
    Description="For every percent damaged, temporary increases max health.";
    Buff=true;
};

function statusPackage.init()
    if RunService:IsServer() then
        local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
    
        modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
            if modBranchConfigs.IsWorld("Slaughterfest") then return end;
    
            local playerClass = shared.modPlayers.Get(player);
            if playerClass == nil then return end;
    
            local statusClass = playerClass:GetStatus("WarmongerScales");
            if statusClass == nil then return end;

            if playerClass.Properties.PacifistsAmulet then return; end -- disable if pacifists present;
    
            local damage = damageSource.Damage;
            local npcModule = damageSource.NpcModule;
            local maxHealth = npcModule.Humanoid.MaxHealth;
    
            local ratio = math.clamp(damage/maxHealth, 0.1, 1);
            local add = ratio * statusClass.HealthPerKill;
            
            local oldPool = (statusClass.Pool or 0);
            statusClass.Pool = math.clamp(oldPool + add, 0, statusClass.Max);
            statusClass.LastDeduct = tick()+1;
            
            if statusClass.Pool > oldPool then
                local dif = statusClass.Pool-oldPool;
                
                statusClass.Buffer = (statusClass.Buffer or 0) + dif;
            end
            
            playerClass:SyncStatus(statusClass.Id);
        end)
        
    end
end

function statusPackage:OnExpire()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local hoSrcs = playerClass.Properties.HealthOverchargeSources;
    hoSrcs[self.Id] = nil;
end

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    if tickPack.ms100 ~= true then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local timeSinceDoingDmg = workspace:GetServerTimeNow()-playerClass.LastDamageDealt;
    
    if timeSinceDoingDmg >= 20 and (self.Pool and self.Pool > 0) then
        self.Pool = math.max(self.Pool - 0.1, 0);
    end
    if self.Buffer and self.Buffer > 0 and playerClass.Humanoid.Health < playerClass.Humanoid.MaxHealth then
        playerClass.Humanoid.Health = playerClass.Humanoid.Health +self.Buffer;
        self.Buffer = 0;
    end
    
    local hoSrcs = playerClass.Properties.HealthOverchargeSources;
    hoSrcs[self.Id] = self.Pool;
    
    return true;
end

return modStatusClass.new(statusPackage);