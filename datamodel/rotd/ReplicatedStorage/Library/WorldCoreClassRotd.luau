local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modCutscene = shared.require(game.ReplicatedStorage.Library.Cutscene);
local modDialogueService = shared.require(game.ReplicatedStorage.Library.DialogueService);

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
                while task.wait(math.random(60, 180)) do
                    local soundName = `FarThunder{math.random(1, 2)}`;
                    
                    modAudio.Preload(soundName, 5);
                    local sound = modAudio.Play(soundName);
                    if sound then
                        sound.Volume = 0.6;
                    end
                    
                    task.spawn(function()
                        task.wait(math.random(200, 400)/1000);
                        game.Lighting:SetAttribute("InvertAmbient", true);
                        task.wait(0.05);
                        game.Lighting:SetAttribute("InvertAmbient", false);
                        task.wait(math.random(50, 100)/1000);
                        game.Lighting:SetAttribute("InvertAmbient", true);
                        task.wait(0.05);
                        game.Lighting:SetAttribute("InvertAmbient", false);
                        if math.random(1, 2) == 1 then
                            task.wait(math.random(50, 100)/1000);
                            game.Lighting:SetAttribute("InvertAmbient", true);
                            task.wait(0.05);
                            game.Lighting:SetAttribute("InvertAmbient", false);
                        end
                    end)
                end
            end)
        end

    elseif RunService:IsClient() then
    end
end

function modWorldCoreClass.updateWanderers()
    task.spawn(function()
        local wandererList = {
            "Icarus";
        };

        local day = workspace:GetAttribute("DayOfYear");
        local spawnWorldList = {};
        
        for _, worldInfo in pairs(modBranchConfigurations.Worlds) do
            if worldInfo.OverWorldIndex == nil then continue end;
            spawnWorldList[worldInfo.OverWorldIndex] = worldInfo;
        end
        
        local spawnWorldInfo = spawnWorldList[math.fmod(day, #spawnWorldList)+1];
        if shared.gameConfig.BranchName == "Dev" then
            spawnWorldInfo = modBranchConfigurations.WorldInfo;
        end
        
        local spawnWandererName = wandererList[math.fmod(day, #wandererList)+1];
        Debugger:Log("Wanderer (",spawnWandererName,") Spawn World:",spawnWorldInfo);
        
        for a=#modNpcs.ActiveNpcClasses, 1, -1 do
            local npcClass: NpcClass = modNpcs.ActiveNpcClasses[a];
            if npcClass and npcClass.Properties.WanderingTrader then
                if npcClass.Character then
                    game.Debris:AddItem(npcClass.Character, 0);
                end
            end
        end

        modBranchConfigurations.Wanderer = {
            Name = spawnWandererName;
            WorldName = spawnWorldInfo.DisplayName;
        };

        if spawnWorldInfo.OverWorldIndex == nil then
            Debugger:Warn("Cancelled wanderer spawn, not overworld.");
            return;
        end;
        if modBranchConfigurations.WorldInfo ~= spawnWorldInfo then
            Debugger:Warn("Cancelled wanderer spawn, wrong world.");
            return;
        end

        local spawnsLib = modBranchConfigurations.SpawnLibrary[modBranchConfigurations.WorldName];
        local spawnPart = workspace:FindFirstChildWhichIsA("SpawnLocation");
        if spawnsLib then
            Debugger:Warn("Wanderer spawn, no spawn library.");
            local spawnLocationParts = {};
            for spawnName, _ in pairs(spawnsLib) do
                local spawnPart = workspace:FindFirstChild(spawnName);
                if spawnPart == nil then continue end;
                table.insert(spawnLocationParts, spawnPart); 
            end

            spawnPart = spawnLocationParts[math.random(1, #spawnLocationParts)];
        end;

        if spawnPart == nil then 
            Debugger:Warn(`Cancelled wanderer spawn, no spawn part ({spawnsLib}).`);
            return 
        end;

        local spawnSurfacePos = spawnPart.Position + Vector3.new(0, spawnPart.Size.Y/2, 0);
        local spawnCFrame = CFrame.new(spawnSurfacePos + Vector3.new(0, 2.35, 0)) 
            * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
        
        modNpcs.spawn2{
            Name = spawnWandererName;
            CFrame = spawnCFrame;
            PackageOverride = "WanderingTrader";
        };
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
    shared.gameConfig.Config:SetAttribute("GameMode", gameMode);
    shared.gameConfig.Config:SetAttribute("GameStage", gameStage);
    
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
        if RunService:IsStudio() or shared.gameConfig.BranchName == "Dev" then
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

    local dialoguesScript = worldScr:FindFirstChild("DialoguesScript");
    if dialoguesScript then
        local dialogueHandlers = shared.require(dialoguesScript);
        modDialogueService:LoadHandlers(dialogueHandlers);
    end
end)

return modWorldCoreClass;
