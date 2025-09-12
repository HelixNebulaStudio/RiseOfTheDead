local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);

end

local DEADBODY_ID = 1;
local GIFT_SPAWNCF = CFrame.new(689.499939, 69.1379852, -74.0011292, 1, 0, 0, 0, 1, 0, 0, 0, 1);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()

    if RunService:IsServer() then --MARK: IsServer
        local DEADBODY_MODEL = script:WaitForChild("Deadbody");

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            if player.UserId == DEADBODY_ID then
                DEADBODY_MODEL.Parent = game.ServerStorage;
            end

            WorldCore:SpawnGift(player, "sundaysGift", GIFT_SPAWNCF);
            WorldCore:SpawnPlayerNpc(player, "Wilson");
            WorldCore:LoadPlayerMissions(player, profile);

        end, 999);

        shared.modEngineCore:ConnectOnPlayerRemoved(script, function(player: Player)
            if player.UserId == DEADBODY_ID then
                DEADBODY_MODEL.Parent = workspace.Entity;
            end
        end)
        DEADBODY_MODEL.Parent = workspace.Entity;
        modAudio.Play("Flies", DEADBODY_MODEL.PrimaryPart, true);

        -- Safehouse 1
        shared.modNpcs.spawn2{Name="Russell";};
        shared.modNpcs.spawn2{Name="Stephanie";};
        shared.modNpcs.spawn2{Name="Dr. Deniski";};
        shared.modNpcs.spawn2{Name="Nick";};
        shared.modNpcs.spawn2{Name="Jefferson";};

        -- Safehouse 2
        shared.modNpcs.spawn2{Name="Carlos";};
        shared.modNpcs.spawn2{Name="Frank";};
        shared.modNpcs.spawn2{Name="Jane";};
        shared.modNpcs.spawn2{Name="Michael";};
        
        modGameModeManager:Initialize("Raid", "Tombs");

    elseif RunService:IsClient() then --MARK: IsClient

        task.spawn(function()
            local modData = shared.require(localPlayer:WaitForChild("DataModule"));
            local bloxmartGate = workspace.Environment:WaitForChild("BloxmartGate", 60);
            repeat until modData.GameSave and modData.GameSave.Missions or not RunService.Heartbeat:Wait();

            local openGates = false;

            local missionData = modData:GetMission(7);
            if missionData then
                if missionData.Type == 3 or (missionData.Type == 1 and missionData.ProgressionPoint > 5) then
                    openGates = true;
                end
            end

            if not openGates then
                bloxmartGate:WaitForChild("Base", 60);
                bloxmartGate:SetPrimaryPartCFrame(CFrame.new(286.61203, 60.7738342, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));
            end
        end)

    end
end

function WorldCore:LoadPlayerMissions(player: Player, profile: ProfileRotd)
	local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
	local missionsProfile: MissionsProfile = gameSave and gameSave.Missions;

    -- MARK: Mission 6
    local missionFirstRescue = missionsProfile:Get(6);
    if missionFirstRescue == nil or missionFirstRescue.Type < 3 then
        local barricade = game.ReplicatedStorage.Prefabs:WaitForChild("Objects"):WaitForChild("bloxmartBlockage"):Clone();
        modReplicationManager.ReplicateIn(player, barricade, workspace.Environment);
        
        local destructible: DestructibleInstance = modDestructibles.getOrNew(barricade:WaitForChild("Destructible"));
        destructible.NetworkOwners = {player};
        destructible:SetEnabled(false);
    end
    
    -- MARK: Mission 7
    player.CharacterAdded:Connect(function()
        local missionThePrisoner = missionsProfile:Get(7);
        if missionThePrisoner and missionThePrisoner.Type == 3 then
            local gateModel = workspace.Environment:FindFirstChild("BloxmartGate");
            if gateModel then
                gateModel:PivotTo(CFrame.new(286.61203, 69.4899445, 103.898018, 1, 0, 0, 0, 1, 0, 0, 0, 1));
            end
        end
    end)

    -- MARK: Mission 12
    local missionFactoryRaid = missionsProfile:Get(12);
    if missionFactoryRaid == nil or (missionFactoryRaid.Type < 3 and missionFactoryRaid.ProgressionPoint < 4) then
        Debugger:Warn("New factory blockade for "..player.Name);

        local serverPrefabs = game.ServerStorage:WaitForChild("Prefabs"):WaitForChild("Objects");
        local blockadeFolder = serverPrefabs:FindFirstChild("DefaultBlockades");
        
        local blockade = blockadeFolder.BlockadeSingle:Clone();
        blockade.Name = "FactoryBlockade";
        local hitbox = blockade:WaitForChild("PrimaryPart"):Clone();
        hitbox.Size = Vector3.new(7, 11, 2);
        hitbox.CanCollide = true;
        hitbox.Parent = blockade;
        blockade:PivotTo(CFrame.new(12.197, 60.155, 177.296) * CFrame.Angles(0, math.rad(90), 0));
        modReplicationManager.ReplicateIn(player, blockade, workspace.Environment);
        
        local destructible: DestructibleInstance = modDestructibles.getOrNew(blockade:WaitForChild("Destructible"));
        destructible.NetworkOwners = {player};
        destructible:SetEnabled(false);
        
        if missionFactoryRaid then
            missionFactoryRaid.Cache.Blockade = blockade;
            missionFactoryRaid.Changed:Fire(false, missionFactoryRaid);

        else
            missionsProfile.OnMissionChanged:Connect(function(mission)
                if mission and mission.Id == 12 and (mission.Type < 3 and mission.ProgressionPoint < 4) then 
                    mission.Cache.Blockade = blockade;
                end
            end)
        end
    end

    local jesseNpcClass = shared.modNpcs.getPlayerNpc(player, "Jesse");
    if jesseNpcClass == nil then                
        shared.modNpcs.spawn2{
            Name = "Jesse";
            Player = player;
            ReplicateOut = true;
        };
    end

end

return WorldCore;