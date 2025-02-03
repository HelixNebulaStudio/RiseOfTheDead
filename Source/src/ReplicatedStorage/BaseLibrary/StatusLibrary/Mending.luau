
local RunService = game:GetService("RunService");

local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
--==
local statusPackage = {
    Id="Mending";
    Icon="rbxassetid://16074211222";
    Name="Mending";
    Description="For every kill, reduce <b>Armor Break</b> duration by $Times.";
    Buff=true;
};

function statusPackage.init()
    if RunService:IsServer() then
        local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
    
        modOnGameEvents:ConnectEvent("OnNpcDeath", function(npcModule)
            local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");
            for a=1, #playerTags do
                local playerTag = playerTags[a];
                local player = playerTag.Player;
    
                local playerClass = shared.modPlayers.Get(player);
                
                local statusId = statusPackage.Id;

                local statusClass = playerClass:GetStatus(statusId);
                if statusClass == nil then return end;

                if playerClass.Properties.ArmorBreak == nil then continue end;
                
                local armorBreakStatus = playerClass.Properties.ArmorBreak;
                local t = statusClass.Time;
                
                local timeRemaining = armorBreakStatus.Expires-modSyncTime.GetTime();
                timeRemaining = math.max(timeRemaining-t, 0);
    
                armorBreakStatus.Expires = modSyncTime.GetTime() + timeRemaining;
                armorBreakStatus.Delay = timeRemaining;
    
                playerClass:SyncProperty("ArmorBreak");
            end
        end)
    end
end

function statusPackage:OnTick()
    if RunService:IsServer() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
    
	self.Visible = playerClass.Properties.ArmorBreak ~= nil;
end

return modStatusClass.new(statusPackage);