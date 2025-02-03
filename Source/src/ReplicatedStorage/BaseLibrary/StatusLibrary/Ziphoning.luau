local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local localPlayer = game.Players.LocalPlayer;
--==
local statusPackage = {
    Id="Ziphoning";
    Icon="rbxassetid://15936793820";
    Name="Ziphoning";
    Description="Nekrosis heal from this pool of health. +$Amount hp/s";
    QuantityLabel="Pool";
    Buff=true;
    Cleansable=true;
};

function statusPackage.init()
    if RunService:IsClient() then return end;
    
    local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
    
	modOnGameEvents:ConnectEvent("OnNpcDamaged", function(player, damageSource)
        local playerClass = shared.modPlayers.Get(player);
        if playerClass == nil then return end;

        local statusId = statusPackage.Id;

        local statusClass = playerClass:GetStatus(statusId);
        if statusClass == nil then return end;
		
		local damage = damageSource.Damage;
		local npcModule = damageSource.NpcModule;
		local maxHealth = npcModule.Humanoid.MaxHealth;
		
		local humanoid = playerClass.Humanoid;
		
		local ratio = math.clamp(damage/maxHealth, 0.1, 1);
		statusClass.Pool = math.clamp(math.round(statusClass.Pool + ratio*5), 0, humanoid.MaxHealth);
		
        playerClass:SyncStatus(statusId);
	end)

end

function statusPackage:OnApply()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local statusList = playerClass:ListStatus();
    for a=1, #statusList do
        local statusClass = statusList[a];
        
        if statusClass.Buff == true then continue end;
		if statusClass.Cleansable ~= true then continue end;
			
        statusClass.Expires = modSyncTime.GetTime();
        playerClass:SyncStatus(statusClass.Id);
    end
    
end

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    if tickPack.ms1000 ~= true then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
		
    local humanoid = playerClass.Humanoid;
    
    local hpPerTick = 1;
    
    local ampMulti = playerClass:GetBodyEquipment("NekrosisAmpMulti") or 0;
    hpPerTick = hpPerTick + (hpPerTick * ampMulti);
    self.Amount = hpPerTick;
    
    if self.Pool >= hpPerTick then
        self.Pool = math.clamp(math.round(self.Pool - hpPerTick), 0, humanoid.MaxHealth);
        
        playerClass:TakeDamagePackage(modDamagable.NewDamageSource{
            Damage=hpPerTick;
            TargetPart=playerClass.RootPart;
            DamageType="Heal";
        })

        return true; -- sync;
    end

    return;
end

return modStatusClass.new(statusPackage);