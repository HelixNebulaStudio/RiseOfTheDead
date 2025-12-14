local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modCutscene = shared.require(game.ReplicatedStorage.Library.Cutscene);

if RunService:IsServer() then
    modCrates = shared.require(game.ReplicatedStorage.Library.Crates);

    modNpcs = shared.require(game.ServerScriptService.ServerLibrary.Entity.Npcs);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

end
--==
function modWorldCoreClass.onRequire()
    if RunService:IsServer() then
        local function onDayChanged()
            task.spawn(function() 
                shared.waitForIgnition();
                modWorldCoreClass.updateWanderers();
            end)
        end

        if workspace:GetAttribute("DayOfYear") then onDayChanged(); end
        workspace:GetAttributeChangedSignal("DayOfYear"):Connect(onDayChanged);

        modConfigurations.Set("UseOldItemDrop.Spawn", true);

        modItemDrops.DefaultGlowBrightness = 1;
        modItemDrops.DefaultRayBrightness = 10;
        modItemDrops.DefaultGlowColor = Color3.fromRGB(255, 255, 255);
        modItemDrops.DefaultRayColor = Color3.fromRGB(255, 255, 255);
        modItemDrops.DefaultGlowSizeDivider = 1.4;
        modItemDrops.DefaultBillboardBrightness = 10;
        modItemDrops.DefaultMinGlowSize = 2.5;
        modItemDrops.DefaultMaxGlowSize = 5;

        if modConfigurations.SpecialEvent.Halloween then
            task.spawn(function()
                while wait(math.random(60, 180)) do
                    local soundName = `FarThunder{math.random(1, 2)}`;
                    
                    modAudio.Preload(soundName, 5);
                    local sound = modAudio.Play(soundName);
                    if sound then
                        sound.Volume = 0.6;
                    end
                    
                    spawn(function()
                        wait(math.random(200, 400)/1000);
                        game.Lighting.Ambient = Color3.fromRGB(121, 136, 181);
                        wait(0.05);
                        game.Lighting.Ambient = Color3.fromRGB(25, 25, 25);
                        wait(math.random(50, 100)/1000);
                        game.Lighting.Ambient = Color3.fromRGB(121, 136, 181);
                        wait(0.05);
                        game.Lighting.Ambient = Color3.fromRGB(25, 25, 25);
                        if math.random(1, 2) == 1 then
                            wait(math.random(50, 100)/1000);
                            game.Lighting.Ambient = Color3.fromRGB(121, 136, 181);
                            wait(0.05);
                            game.Lighting.Ambient = Color3.fromRGB(25, 25, 25);
                        end
                    end)
                end
            end)
        end

    elseif RunService:IsClient() then
    end
end

function modWorldCoreClass.updateWanderers()
    if modBranchConfigs.NavLinks == nil then return end;
    
    task.spawn(function()
        local day = workspace:GetAttribute("DayOfYear");
        local spawnWorldList = {};
        
        for worldId, worldNav in pairs(modBranchConfigs.NavLinks) do
            table.insert(spawnWorldList, {Id=worldId; Nav=worldNav});
        end
        
        local wandererList = {
            --"Icarus";
        };
        
        local spawnWorld = spawnWorldList[math.fmod(day, #spawnWorldList)+1];
        if modBranchConfigs.CurrentBranch.Name == "Dev" then
            spawnWorld = {Id=modBranchConfigs.GetWorld(); Nav=modBranchConfigs.NavLinks[modBranchConfigs.GetWorld()]};
        end
        
        if spawnWorld.Nav and #wandererList > 0 then
            local spawnWandererName = wandererList[math.fmod(day, #wandererList)+1];
            local spawnNavId = nil;
            
            for navLocation, info in pairs(spawnWorld.Nav) do
                if info.Safehouse == true then
                    spawnNavId = navLocation;
                    break;
                end
            end
            
            Debugger:Log("Wanderer (",spawnWandererName,") Spawn World:",spawnWorld.Id, " Spawn safehouse:", spawnWorld.Nav[spawnNavId]);
            
            for a=#modNpcs.ActiveNpcClasses, 1, -1 do
                local npcClass = modNpcs.ActiveNpcClasses[a];
                if npcClass and npcClass.WanderingTrader then
                    if npcClass.Prefab then
                        game.Debris:AddItem(npcClass.Prefab, 0);
                    end
                    npcClass:Destroy();
                end
            end
            
            if modBranchConfigs.IsWorld(spawnWorld.Id) then
                local doorInstance = workspace.Interactables:FindFirstChild(spawnWorld.Nav[spawnNavId].Entrance);
                
                local spawnCFrame = CFrame.new(doorInstance.Destination.WorldPosition + Vector3.new(0, 2.35, 0)) 
                    * CFrame.Angles(0, math.rad(doorInstance.Destination.WorldOrientation.Y-90), 0);
                
                modNpcs.spawn(spawnWandererName, spawnCFrame, function(npc, npcClass)
                    npcClass.CurrentNav = spawnNavId;
                    
                end, modNpcs.NpcBaseConstructors.WanderingTrader);
            end

            modBranchConfigs.Wanderer = {
                Name=spawnWandererName;
                WorldId=spawnWorld.Id;
            };
            
        end
    end)
end

function modWorldCoreClass:SpawnGift(player: Player, giftId: string, giftCf: CFrame)
    local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;

    local content = {};
    if modEvents:GetEvent(player, giftId) == nil then
        modEvents:NewEvent(player, {Id=giftId});
        content = modCrates.GenerateRewards(giftId);
    end

    profile.Garbage:Tag(modCrates.spawn(giftId, giftCf, {player}, content, true));
end


function modWorldCoreClass:SpawnPlayerNpc(player: Player, npcName: string)
    local npcClass = shared.modNpcs.getPlayerNpc(player, npcName);
    if npcClass == nil then
        npcClass = shared.modNpcs.spawn2{
            Name = npcName;
            Player = player;
        };
        if npcClass then
            modReplicationManager.ReplicateOut(player, npcClass.Character);
        end
    end
    return npcClass;
end


function modWorldCoreClass:InitGameWorld(gameMode, gameStage)
    local isHard = false;
    if RunService:IsStudio() then
        if workspace:GetAttribute("IsHard") == true then
            isHard = true;
        end
    end

    local studioLobbyData = {
        GameMode={
            Type=gameMode;
            Stage=gameStage;
            Room={
                MaxPlayers=1;
                Players={};
                IsHard=isHard;
            };
        };
    };
    modGameModeManager.StudioData = studioLobbyData;
    if workspace:GetAttribute("DisableGameMode") == true then
        modGameModeManager.StudioData = nil;
    end

    local waitingforFirstPlayer = true;
    local gameModeStart = false;
    local worldCoreInit = false;
    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        if RunService:IsStudio() or modBranchConfigs.CurrentBranch.Name == "Dev" then
            local lobbyPlayers = studioLobbyData.GameMode.Room.Players;
            for _, player in pairs(game.Players:GetPlayers()) do
                table.insert(lobbyPlayers, {Name=player.Name; UserId=player.UserId});
            end
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

        while shared.WorldCore == nil or shared.WorldCore.GameController == nil do task.wait() end;
        if worldCoreInit then return end;
        worldCoreInit = true;

        if shared.WorldCore.BindGameControllerInited then
            shared.WorldCore.BindGameControllerInited(shared.WorldCore.GameController);
        end
    end)
end

shared.coreBind(modWorldCoreClass, "_new", function(worldCoreClass)
    local worldScr = worldCoreClass.Script;

    local cutsceneScript = worldScr:FindFirstChild("CutsceneScript");
    if cutsceneScript then
        cutsceneScript.Name = worldScr.Name;
        cutsceneScript.Parent = modCutscene.Script;
    end
end)

return modWorldCoreClass;
