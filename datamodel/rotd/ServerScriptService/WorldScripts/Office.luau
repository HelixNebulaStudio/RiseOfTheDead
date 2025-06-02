local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponents = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--=

function WorldCore.onRequire()
    if RunService:IsClient() then return end;

    modGameModeManager.StudioData = {
        GameMode={
            Type="Raid";
            Stage="Office";
            Room={
                MaxPlayers=1;
                Players={};
                IsHard=false;
            };
        };
    };

    local waitingforFirstPlayer = true;
    local gameModeStart = false;
    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        if RunService:IsStudio() or modBranchConfigs.CurrentBranch.Name == "Dev" then
            local lobbyPlayers = modGameModeManager.StudioData.GameMode.Room.Players;
            for _, player in pairs(game.Players:GetPlayers()) do
                table.insert(lobbyPlayers, {Name=player.Name; UserId=player.UserId});
            end
            Debugger:Warn("LobbyPlayers", lobbyPlayers);
        end
        
        if waitingforFirstPlayer then
            waitingforFirstPlayer = false;

            task.wait(3);
            gameModeStart = true;
            for _, p in pairs(game.Players:GetPlayers()) do
		        modGameModeManager:OnPlayerJoin(p);
            end

        elseif gameModeStart then
		    modGameModeManager:OnPlayerJoin(player);
        end
    end)

    task.spawn(function()
        local touchHandler = modTouchHandler.new("BarbedFence", 1);
        local woodenBarb = workspace.Debris:WaitForChild("woodenBarb");
        local hitbox = woodenBarb:WaitForChild("Hitbox");

        touchHandler:AddObject(hitbox);
        function touchHandler:OnHumanoidTouch(humanoid, basePart, hitPart)
            local targetModel = hitPart.Parent;
            if targetModel == nil or not targetModel:IsA("Model") then return end;

            local healthComp: HealthComp = modHealthComponents.getByModel(targetModel);
            if healthComp == nil or healthComp.CompOwner.ClassName ~= "NpcClass" then return end;

            local npcClass: NpcClass = healthComp.CompOwner :: NpcClass;

            local damage = math.clamp(healthComp.MaxHealth * 0.001, 10, math.huge);
            healthComp:TakeDamage(DamageData.new{
                Damage = damage;
                TargetPart = hitPart;
            });

            local statusComp: StatusComp = npcClass.StatusComp;

            statusComp:Apply("BarbSlow", {
                Expires = workspace:GetServerTimeNow() + 2;
                Values = {
                    SlowValue = 2;
                }
            });
        end
    end)
end

return WorldCore;