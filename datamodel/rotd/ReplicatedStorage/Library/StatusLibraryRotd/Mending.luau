
local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
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
        local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

        modOnGameEvents:ConnectEvent("OnNpcDeath", function(npcModule)
            local playerTags = modDamageTag:Get(npcModule.Prefab, "Player");
            for a=1, #playerTags do
                local playerTag = playerTags[a];
                local player = playerTag.Player;

                local playerClass = shared.modPlayers.get(player);

                local statusId = statusPackage.Id;

                local statusComp = playerClass.StatusComp;
                if statusComp == nil then continue end;

                local statusClass = statusComp:GetStatus(statusId);
                if statusClass == nil then continue end;

                if playerClass.Properties.ArmorBreak == nil then continue end;

                local armorBreakStatus = playerClass.Properties.ArmorBreak;
                local t = statusClass.Values.Times;

                local timeRemaining = armorBreakStatus.Expires-workspace:GetServerTimeNow();
                timeRemaining = math.max(timeRemaining-t, 0);

                armorBreakStatus.Expires = workspace:GetServerTimeNow() + timeRemaining;
                armorBreakStatus.Delay = timeRemaining;

                playerClass:SyncProperty("ArmorBreak");
            end
        end)
    end
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsServer() then return end;
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

	statusClass.Visible = playerClass.Properties.ArmorBreak ~= nil;
end

return modStatusClass.new(statusPackage);