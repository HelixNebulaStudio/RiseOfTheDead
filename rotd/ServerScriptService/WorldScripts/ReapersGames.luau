local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeCoop = shared.require(game.ServerScriptService.ServerLibrary.GameModeCoop);
    modMatchMakingService = shared.require(game.ServerScriptService.ServerLibrary.MatchMakingServiceRotd);

    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

WorldCore.Garbage = modGarbageHandler.new();
WorldCore.MapCache = {};

WorldCore.Storages = {};
WorldCore.ScoreTable = {};

local GAME_MODE, GAME_STAGE = "Special", "ReapersGames";
local STORAGE_ID = "reapersrewards";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeCoop.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.EnemiesList = {};

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    
    for _, snd in pairs(game.ServerStorage:WaitForChild("MapAudio"):GetChildren()) do
        if not snd:IsA("Sound") then continue end;
        modAudio.Load(snd);
    end

    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
        if profile == nil then return end;

        Debugger:Warn(`{player.Name} has joined the world!`);

        local curTime = os.time();
        local playerClass: PlayerClass = shared.modPlayers.get(player);


        local joinData = player:GetJoinData();
        local teleportData = joinData.TeleportData;
        Debugger:Warn("teleportData", teleportData);
        Debugger:Warn("LobbyInfo", teleportData and teleportData.LobbyInfo);
        

        if WorldCore.GameStartTime == nil then
            WorldCore.GameStartTime = curTime + 10;
        end;

        if curTime > WorldCore.GameStartTime then
            local lateStartTime = WorldCore.GameStartTime+3;
            for a=1, 3, 0.5 do
                profile:GuiAction("reapergames_starttimedown", lateStartTime);
                task.wait(0.5);
            end
        end
        while os.time() < WorldCore.GameStartTime do
            profile:GuiAction("reapergames_starttimedown", WorldCore.GameStartTime);
            task.wait(0.5);
        end

        WorldCore:InitReapersGames();
        -- Debugger:Warn(`Spawn player`);
        -- playerClass:Spawn();
    end, 999);

    shared.modEngineCore:ConnectOnPlayerRemoved(script, function(player: Player)
        for a=#WorldCore.Profiles, 1, -1 do
            local profile = WorldCore.Profiles[a];
            if profile.Player ~= player then continue end;

            table.remove(WorldCore.Profiles, a);
        end
    end);


    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);
end

function fadeOutSound(snd)
    TweenService:Create(snd, TweenInfo.new(3), {Volume=0}):Play();
end

--MARK: Broadcast
function WorldCore:Broadcast(title, desc, arg3)
    local continueTime;
    if arg3 == "votecontinue" then
        workspace:SetAttribute("VoteContinueWait", true);
        continueTime = workspace:GetServerTimeNow() + 30;
    end

    for _, profile in pairs(self.Profiles) do
        profile.Cache.VoteContinueReapersGames = false;

        task.spawn(function() 
            profile:GuiAction("reapergames_announce", title, desc, arg3, continueTime);
        end)
    end

    if arg3 == "votecontinue" then
        self:Timer(continueTime);

        for a=30, 1, -1 do
            task.wait(1);

            local continueVoted = true;
            local voteDict = {};

            for _, profile in pairs(self.Profiles) do
                voteDict[profile.Player.Name] = profile.Cache.VoteContinueReapersGames == true;

                if profile.Cache.VoteContinueReapersGames == false then
                    continueVoted = false;

                    task.spawn(function() 
                        profile:GuiAction("reapergames_announce", title, desc, arg3, continueTime);
                    end)
                end
            end

            if continueVoted then break; end;
            Debugger:StudioLog(`Waiting for votes`, voteDict);
        end

        for _, profile in pairs(self.Profiles) do
            profile.Cache.VoteContinueReapersGames = nil;
        end
        workspace:SetAttribute("VoteContinueWait", false);
        self:Timer();
        task.wait(1);
        
    end
end

function WorldCore:BoardcastKill(player)
    for _, profile in pairs(self.Profiles) do
        local p = profile.Player;
        if p == player then continue end;

        task.spawn(function()
            profile:GuiAction("reapergames_kia", player);
        end)
    end

    local remoteLiveFeedRemote = modRemotesManager:Get("LiveFeedRemote") :: UnreliableRemoteEvent;
    remoteLiveFeedRemote:FireAllClients({
        Content={
            {Text="Jack Reap"; Image="rbxassetid://84182291936531";};
            {Type="KillSym";};
            {Text=player.DisplayName; Avatar=player.UserId;};
        };
        Preset={Type="Kill"; Killer="Jack Reap"; Victim=player.Name};
    });
end

function WorldCore:Timer(t, yield)
    local curTimer = t;

    while curTimer == nil or workspace:GetServerTimeNow() < curTimer do
        for _, profile in pairs(self.Profiles) do
            task.spawn(function() 
                profile:GuiAction("reapergames_starttimedown", curTimer);
            end)
        end

        if curTimer == nil then return end;
        if yield ~= true then return end;
        task.wait(0.5);
    end
end

function WorldCore:TimerText(txt, duration)
    for _, profile in pairs(self.Profiles) do
        task.spawn(function() 
            profile:GuiAction("reapergames_timedowntext", txt, duration);
        end)
    end
end

function WorldCore:RefreshProfiles()
    local players: {Player} = game.Players:GetPlayers();
    local profiles: {ProfileRotd} = {};

    for _, player in pairs(players) do
        local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
        table.insert(profiles, profile);
    end
    self.Profiles = profiles;
end

function WorldCore:SpawnCharacters()
    self:RefreshProfiles();
    
    local charsList = {};
    local expectedSpawnCount = 0;

    local disconnSpawnSig = shared.modPlayers.OnPlayerSpawn:Connect(function(playerClass, character)
        for c=0, 5, 1/30 do
            task.wait();
            if workspace:IsAncestorOf(character) then
                break;
            end
        end

        if not workspace:IsAncestorOf(character) then return end;
        table.insert(charsList, playerClass);
    end)
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if not game.Players:IsAncestorOf(player) then continue end;

        local playerClass = shared.modPlayers.get(player);
        if playerClass == nil then continue end;

        expectedSpawnCount += 1;
        playerClass:Spawn();
    end

    for a=0, 5, 1/30 do
        task.wait();
        if #charsList >= expectedSpawnCount then
            break;
        end
    end

    disconnSpawnSig();

    Debugger:Warn(`SpawnCharacters`, #charsList);
    return charsList;
end

local envSceneFolder = workspace.Environment:WaitForChild("Scene");
local envGameFolder = workspace.Environment:WaitForChild("Game");

function WorldCore:AddScore(player, amt)
    local scoreTable = WorldCore.ScoreTable[player];
    if scoreTable == nil then
        Debugger:Warn(`Missing score table for ({player})`)
        return;
    end
    amt = amt or 0;
    if amt <= 0 then return end;


    scoreTable.Score += amt;
end

function WorldCore:GetSortedScore()
    local list = {};

    for player, scoreTable in pairs(WorldCore.ScoreTable) do
        table.insert(list, {
            Player = player;
            Score = scoreTable.Score or 0;
        })
    end

    table.sort(list, function(a, b)
        return a.Score > b.Score;
    end)
    return list;
end

function WorldCore:LoadMap(name)
    local mapCache = self.MapCache[name];

    if mapCache == nil then
        local map = envSceneFolder[name];
        map.Parent = script;

        mapCache = map;
        self.MapCache[name] = mapCache;
    end

    local new = mapCache:Clone();
    new.Parent = envSceneFolder;

    return new;
end



--MARK: InitReapersGames
function WorldCore:InitReapersGames()
    if WorldCore._init then return end;
    WorldCore._init = true;

    Debugger:Warn(`InitReapersGames`);

    self:RefreshProfiles();
    for _, profile in pairs(self.Profiles) do
        local player = profile.Player;

        WorldCore.ScoreTable[player] = {Score=0;};

        task.spawn(function() 
            profile:GuiAction("reapergames_intro");
        end)
    end
    
    task.wait(5);

    local GAMESLIST = { --MARK: GAMESLIST
        {Id="BlackFriday"};
        {Id="PlatformMatch"};
        {Id="DropDead";};
        {Id="SewerRun"};
    }

    self.GameIndex = 0;
    for a=1, #GAMESLIST do
        self.GameIndex += 1;
        
        self.Garbage:Destruct();

        local gameInfo = GAMESLIST[a];
        Debugger:Warn(`Starting game {gameInfo.Id}`);

        local ok, err = pcall(self[`Game_{gameInfo.Id}`], self);
        if not ok then
            Debugger:Warn(`Game {gameInfo.Id} aborted`, err);

            for _, playerClass in pairs(shared.modPlayers.listPlayerClasses()) do
                if playerClass.StatusComp == nil then continue end;
                playerClass.StatusComp:Apply("Stun", nil);
                playerClass.StatusComp:Apply("AttachedCamera", nil);
            end
        end

        self.Garbage:Destruct();

        task.wait(1);
    end







    Debugger:Warn(`End game`);
    shared.Notify(game.Players:GetPlayers(), `Reaper's Games ended!`, "Inform");

    --MARK: End Reaper's Games
    local sortedScoreboard = self:GetSortedScore();
    Debugger:Warn(`Respawn players to leave`);

    modConfigurations.Set("DisableGearMods", false);
    modConfigurations.Set("CanClientEquipAndUnequip", true);
    game.Players:SetAttribute("AutoRespawn", true);

    task.wait(2);
    
    for _, profile in pairs(self.Profiles) do
        task.spawn(function() 
            profile:GuiAction("reapergames_endgame", sortedScoreboard);
        end)
    end

    workspace:SetAttribute("ReapersGamesEnded", true);
    task.spawn(function()
        workspace:WaitForChild("Event"):WaitForChild("HalloweenCaudronSpawn"):SetAttribute("Disabled", false);
    end)

    for _, profile in pairs(self.Profiles) do
        local player = profile.Player;
        if player == nil or not game.Players:IsAncestorOf(player) then continue end;

        local cachedStorages = profile:GetCacheStorages();
        
        local storage: Storage = self.Storages[player];
        if storage == nil then
            storage = shared.modStorage.new(STORAGE_ID, "rewardcrate", player, "Reaper's Rewards");
            storage.Properties.ItemSpawn = true;

            storage:SetPermissions("CanRemove", false);
            self.Storages[player] = storage;
        end

        cachedStorages[STORAGE_ID] = storage;

        local scoreTableIdx;
        for a=1, #sortedScoreboard do
            if sortedScoreboard[a].Player ~= player then continue end;
            
            scoreTableIdx = a;
            break;
        end 

        local playerScore = sortedScoreboard[scoreTableIdx].Score;

        local rewardQty = 1;
        if scoreTableIdx == 1 then
            rewardQty = 3;
        elseif scoreTableIdx == 2 then
            rewardQty = 2;
        end

        storage:Add("slaughterfestcandybag", {Quantity=rewardQty});
    end

    local cratePallet = game.ServerStorage.Prefabs.Objects.Crates.CratePallet;
	local cratePrefab = cratePallet:Clone();
	cratePrefab.Name = "RewardCrate";
	cratePrefab:PivotTo(envGameFolder.RewardCrateSpawn.WorldCFrame);

	local interactConfig = modInteractables.createInteractable("StorageRotd");
	interactConfig:SetAttribute("StorageId", STORAGE_ID);
	interactConfig:SetAttribute("StorageName", "Reaper's Rewards");
	interactConfig:SetAttribute("StoragePresetId", "rewardcrate");
	interactConfig.Parent = cratePrefab;
	
	local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
    for _, profile in pairs(self.Profiles) do
        local player = profile.Player;
        if player == nil or not game.Players:IsAncestorOf(player) then continue end;
		interactable:SetUserPermissions(player.Name, "CanInteract", true);
	end

	cratePrefab.Parent = workspace.Interactables;

    modAudio.Play("Soundtrack:GhostTrain", workspace);
end









--MARK: Game_DropDead
function WorldCore:Game_DropDead()
    local map = self:LoadMap("SpiralChamber");
    local spawnAttList = map:WaitForChild("Spawns"):GetChildren();
    local killBox: BasePart = map:WaitForChild("Game"):WaitForChild("_KillBox");

    local unstablePlatforms = map:WaitForChild("Game"):WaitForChild("UnstablePlatforms");
    unstablePlatforms:Destroy();

    local pistonsFolder = map:WaitForChild("Game"):WaitForChild("Pistons");
    local pistonCFrameValues = {};
    for _, model in pairs(pistonsFolder:GetChildren()) do
        if model.Name ~= "piston" then continue end;

        local rootPart = model:WaitForChild("Root");
        model.PrimaryPart = rootPart;

        for _, p in pairs(model:GetChildren()) do
            if not p:IsA("BasePart") then continue end;
            if p == rootPart then continue end;

            local wc = Instance.new("WeldConstraint");
            wc.Part0 = rootPart;
            wc.Part1 = p;
            wc.Parent = rootPart;
            p.Anchored = false;
        end

        local cfV = Instance.new("CFrameValue");
        cfV.Parent = model;

        cfV.Value = rootPart.CFrame;
        cfV:SetAttribute("DefaultCFrame", cfV.Value);
        cfV:GetPropertyChangedSignal("Value"):Connect(function()
            model:PivotTo(cfV.Value);
        end)

        table.insert(pistonCFrameValues, cfV);
    end

    local startTime = workspace:GetServerTimeNow() + 6;

    local playerClasses: {PlayerClass} = self:SpawnCharacters();

    self.Garbage:Tag(shared.modPlayers.OnPlayerDied:Connect(function(playerClass)
        local idx = table.find(playerClasses, playerClass);
        if idx == nil then return end;
        table.remove(playerClasses, idx);
        
        local diedPlayer = playerClass:GetInstance();

        local timeSurvived = math.clamp( math.floor(workspace:GetServerTimeNow() - startTime), 1, 59);
        self:AddScore(diedPlayer, timeSurvived);

        self:BoardcastKill(diedPlayer);
    end))

    killBox.Touched:Connect(function(hitPart)
        local charList = shared.modPlayers.listCharacters();
        for a=1, #charList do
            if not charList[a]:IsAncestorOf(hitPart) then continue end;
            
            local playerClass = shared.modPlayers.getByModel(charList[a]);
            if playerClass then
                Debugger:StudioLog(`Touch kill {charList[a]}`);
                playerClass:Kill();
            end
            
            break;
        end
    end)


    for _, playerClass in pairs(playerClasses) do
        local pickSpawnAtt = table.remove(spawnAttList, math.random(1, #spawnAttList));
        playerClass:SetCFrame(pickSpawnAtt.WorldCFrame);

        playerClass.StatusComp:Apply("Stun", {});
    end

    self:Broadcast(`Game {self.GameIndex}: Dropping Platforms`, `Stay on the platform!`, `votecontinue`);
    self:Timer(startTime, true);

    for _, playerClass in pairs(playerClasses) do
        playerClass.StatusComp:Apply("Stun", nil);
        playerClass.WieldComp:Equip{
			ItemId = "pushtool";
			ProxyEquip = true;
		};
    end

    local gameStartTime = workspace:GetServerTimeNow();
    local roundTime = 60;
    
    self:Timer(gameStartTime + roundTime);
    self:TimerText(`Survive!`);

    local gameMusic = modAudio.Play("Soundtrack:SweetScare", workspace);
    self.Garbage:Tag(gameMusic);

    while #playerClasses > 0 do
        task.wait(1);

        local curTick = workspace:GetServerTimeNow();

        for a=1, #pistonCFrameValues do
            local pCfV = pistonCFrameValues[a];

            local fmod = a%4;

            local tCd = pCfV:GetAttribute("tCd");
            if tCd and curTick < tCd then continue end;

            local pScale = pCfV:GetAttribute("S") or 1;
            if curTick-gameStartTime > 10 then
                if fmod == 0 then
                    pScale = math.random(0, 6);
                else
                    pScale += math.random(0, 1 *fmod *100)/100;
                end
                pCfV:SetAttribute("S", pScale);
            end


            local dCf = pCfV:GetAttribute("DefaultCFrame");
            local newY = -math.random(0, 4 + pScale)
            local newCf = dCf * CFrame.new(0, newY, 0);

            tCd = curTick + pScale;

            if pScale <= -18 then
                tCd = 300;
            end
            pCfV:SetAttribute("tCd", tCd);


            TweenService:Create(
                pCfV,
                TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), 
                {Value=newCf}
            ):Play();
        end
        Debugger:Log(`# playerClasses alive: {#playerClasses}`);

        if #playerClasses <= 0 or curTick-gameStartTime > roundTime then
            break;
        end
    end

    fadeOutSound(gameMusic);
    self:Timer();
    
    for _, playerClass in pairs(shared.modPlayers.listPlayerClasses()) do
        playerClass:Despawn();
    end

    if #playerClasses == 0 then
        self:Broadcast(nil, `Nobody survived..`, 1);
        task.wait(5);

    elseif #playerClasses == 1 then
        local winnerPlayerClass = playerClasses[1];
        local winnerPlayer = winnerPlayerClass:GetInstance();

        self:Broadcast(nil, `Only {winnerPlayer.DisplayName} survived!`, 3);
        self:AddScore(winnerPlayerClass:GetInstance(), 60 + (#self.Profiles * 10));
        task.wait(7);

    else
        for a=1, #playerClasses do
            local survivorPlayerClass = playerClasses[a];
            self:AddScore(survivorPlayerClass:GetInstance(), roundTime + (#self.Profiles * 5));
        end

        self:Broadcast(nil, `Survivors earns bonus points..`, 3);
        task.wait(7);

    end

    Debugger.Expire(map);
end













--MARK: Game_DeadlySnatch
function WorldCore:Game_BlackFriday()
    local map = self:LoadMap("CandyRoom");
    local spawnAttList = map:WaitForChild("Spawns"):GetChildren();
    local fans: BasePart = map:WaitForChild("Game"):WaitForChild("Fans");

    local candiesTemplate = envGameFolder:WaitForChild("Candies"):GetChildren();

    local candyLaunchPoints = {};
    for _, fanPart in pairs(fans:GetChildren()) do
        if fanPart.Name ~= "fan" or not fanPart:IsA("BasePart") then continue end;
        
        local cf = fanPart.CFrame;
        local dir = -cf.RightVector;

        table.insert(candyLaunchPoints, CFrame.lookAlong(cf * (dir * 1.5), dir));
    end

    local startTime = workspace:GetServerTimeNow() + 6;
    local roundTime = 30;

    local playerClasses: {PlayerClass} = self:SpawnCharacters();

    local roundScore = {};
    
    for _, playerClass in pairs(playerClasses) do
        local pickSpawnAtt = table.remove(spawnAttList, math.random(1, #spawnAttList));
        playerClass:SetCFrame(pickSpawnAtt.WorldCFrame);

        local scoreTable = {
            PlayerClass = playerClass;
            Score = 0;
        }
        table.insert(roundScore, scoreTable);

        playerClass.StatusComp:Apply("Stun", {});

        if playerClass.Humanoid then
            self.Garbage:Tag(playerClass.Humanoid.Touched:Connect(function(hitPart)
                if not hitPart:HasTag("BlackFridayScore") then return end;
                hitPart:RemoveTag("BlackFridayScore");

                hitPart:Destroy();
                scoreTable.Score += 1;

                Debugger:Log(`RoundScore ({playerClass.Name}) +1 = {scoreTable.Score}`);
            end))
        end 
    end

    self:Broadcast(`Game {self.GameIndex}: Deadly Snatch`, `Grab as much as you can!`, `votecontinue`);
    self:Timer(startTime, true);

    for _, playerClass in pairs(playerClasses) do
        playerClass.StatusComp:Apply("Stun", nil);
        playerClass.WieldComp:Equip{
			ItemId = "pushtool";
			ProxyEquip = true;
		};
    end

    local gameStartTime = workspace:GetServerTimeNow();
    self:Timer(gameStartTime + roundTime);
    self:TimerText(`Start collecting!`);

    local gameMusic = modAudio.Play("Soundtrack:FastPacedHalloween", workspace);
    self.Garbage:Tag(gameMusic);

    local spreadRandom = Random.new();
    local function spread(direction, maxSpreadAngle)
        maxSpreadAngle = math.clamp(maxSpreadAngle, 0, 90);
        local deflection = math.rad(maxSpreadAngle);
        
        local mSpread = spreadRandom:NextNumber(-0.5, 0.5);
        
        if math.sign(mSpread) == -1 then
            mSpread = -1 * (math.abs(mSpread)^1.4) + 0.5;
        else
            mSpread = mSpread^1.4 + 0.5;
        end
        
        deflection = deflection * mSpread;
        
        local cf = CFrame.new(Vector3.new(), direction);
        
        cf = cf*CFrame.Angles(0, 0, math.pi*2); -- roll cframe
        cf = cf*CFrame.Angles(deflection, 0, 0); --pitch cframe;
        
        return cf.lookVector;
    end


    while #playerClasses > 0 do
        task.wait(1);
        local curTick = workspace:GetServerTimeNow();
                
        local spawnCount = math.round(modMath.gaussianRandom()+3);
        for a=1, spawnCount do
            local newCandy: BasePart = candiesTemplate[math.random(1, #candiesTemplate)]:Clone();
            local newLaunchCf = candyLaunchPoints[math.random(1, #candyLaunchPoints)];
            local dir = spread(newLaunchCf.LookVector, 90);

            newCandy.CFrame = CFrame.lookAlong(newLaunchCf.Position, dir);
            newCandy:AddTag("BlackFridayScore");

            local light: PointLight = Instance.new("PointLight");
            light.Shadows = false;
            light.Color = BrickColor.Random().Color;
            light.Range = 8;
            light.Parent = newCandy;

            newCandy.Parent = map.Game;
            newCandy.Anchored = false;

            task.defer(function()
                newCandy:SetNetworkOwner(nil);
                newCandy:ApplyImpulse(dir * 12_000);
            end)
        end

        Debugger:Log(`# playerClasses alive: {#playerClasses}`);
        if #playerClasses <= 0 or curTick-gameStartTime > roundTime then
            break;
        end
    end

    self:Timer();
    
    for _, playerClass in pairs(shared.modPlayers.listPlayerClasses()) do
        playerClass:Despawn();
    end

    table.sort(roundScore, function(a, b)
        return a.Score > b.Score;
    end);
    Debugger:Log("RoundScore", roundScore);
    
    for a=1, #roundScore do
        local scoreInfo = roundScore[a];
        local playerClass = scoreInfo.PlayerClass;
        local score = scoreInfo.Score;

        local player = playerClass:GetInstance();
        
        if a == 1 then
            local secondStr = ``;
            local secondPlaceScoreInfo = roundScore[2];
            if secondPlaceScoreInfo then
                local secondPlayer = secondPlaceScoreInfo.PlayerClass:GetInstance();
                secondStr = `With {
                    secondPlayer and secondPlayer.DisplayName or "someone"
                } coming second with {
                    secondPlaceScoreInfo.Score
                } candies!`;
            end

            self:Broadcast(`{player.DisplayName} won with {score} candies!`, secondStr, 3);
            self:AddScore(playerClass:GetInstance(), (score*3) + (#self.Profiles * 10));
        else
            self:AddScore(playerClass:GetInstance(), (score*3));
        end
    end

    fadeOutSound(gameMusic);
    task.wait(7);

    Debugger.Expire(map);
end















--MARK: Game_SewerRun
function WorldCore:Game_SewerRun()
    local map = self:LoadMap("SewerRunProc");

    local spawnAttList = map:WaitForChild("Spawns"):GetChildren();

    local startSegment = map:WaitForChild("Game"):WaitForChild("StartSegment");
    local endSegment = map:WaitForChild("Game"):WaitForChild("EndSegment");

    local tileSegmentFolder: Folder = map:WaitForChild("Game"):WaitForChild("Segments");
    tileSegmentFolder.Parent = script;
    self.Garbage:Tag(tileSegmentFolder);

    local segmentTemplates = {};

    for _, segmentModel in pairs(tileSegmentFolder:GetChildren()) do
        if not segmentModel:IsA("Model") then continue end;

        local idx = segmentModel:GetAttribute("Index");
        if idx then
            segmentTemplates[idx] = segmentModel;
        else
            table.insert(segmentTemplates, segmentModel);
        end
    end

    -- Normalize to a dense array so random selection is reliable.
    local denseTemplates = {};
    for _, template in pairs(segmentTemplates) do
        table.insert(denseTemplates, template);
    end
    segmentTemplates = denseTemplates;

    local camOffset = CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-54), 0, 0);

    local startPointAtt = startSegment:WaitForChild("StartPoint");
    local camEndPointAtt = startSegment:WaitForChild("CameraEndPoint");
    local endPointAtt = startSegment:WaitForChild("EndPoint");

    local camAttachment = map:WaitForChild("CameraAtt");
    camAttachment.Name = "CameraAtt";
    camAttachment.WorldCFrame = startPointAtt.WorldCFrame * camOffset;

    TweenService:Create(camAttachment, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
        WorldCFrame = camEndPointAtt.WorldCFrame * camOffset;
    }):Play();


    local startTime = workspace:GetServerTimeNow() + 6;
    local roundTime = 60;

    local playerClasses: {PlayerClass} = self:SpawnCharacters();
    local cameraPlayers: {PlayerClass} = {};

    for _, playerClass in pairs(playerClasses) do
        local pickSpawnAtt = table.remove(spawnAttList, math.random(1, #spawnAttList));
        playerClass:SetCFrame(pickSpawnAtt.WorldCFrame);

        playerClass.StatusComp:Apply("Stun", {});
        playerClass.StatusComp:Apply("AttachedCamera", {
            Values = {
                CameraAtt = camAttachment;
            };
        });

        table.insert(cameraPlayers, playerClass);
    end

    self:Broadcast(`Game {self.GameIndex}: Sewer Run`, `Run for your life!`, `votecontinue`);
    self:Timer(startTime, true);

    for _, playerClass in pairs(playerClasses) do
        playerClass.StatusComp:Apply("Stun", nil);
    end

    self.Garbage:Tag(shared.modPlayers.OnPlayerDied:Connect(function(playerClass)
        local idx = table.find(playerClasses, playerClass);
        if idx == nil then return end;
        table.remove(playerClasses, idx);
        
        local diedPlayer = playerClass:GetInstance();

        local timeSurvived = math.max( math.floor(workspace:GetServerTimeNow() - startTime), 1);
        self:AddScore(diedPlayer, timeSurvived);

        self:BoardcastKill(diedPlayer);
    end))

    local gameStartTime = workspace:GetServerTimeNow();
    local gameEndTime = gameStartTime + roundTime;
    self:Timer(gameEndTime);
    self:TimerText(`Go!`);

    local gameMusic = modAudio.Play("Soundtrack:ToxicCauldron", workspace);
    self.Garbage:Tag(gameMusic);

    --MARK: SewerRun procedural generation
    local SEGMENT_AHEAD = 2;          -- segments kept generated ahead of the camera
    local BASE_SPEED = 18;            -- studs/sec at the start of the run
    local MAX_SPEED = 25;             -- studs/sec at the end of the run (slightly above sprint)
    local SPEED_CURVE = 1.34;         -- >1 = slow start, fast finish
    local KILL_DISTANCE = 30;         -- studs behind the camera before a player dies
    local KILL_GRACE_TIME = 4;        -- seconds after the run starts before kills begin
    local TICK_RATE = 0.05;           -- update interval
    local CLEANUP_BEHIND = 3;         -- nodes kept behind the camera before being destroyed

    local function findAttachment(model: Instance, name: string): Attachment?
        local att = model:FindFirstChild(name, true);
        if att and att:IsA("Attachment") then
            return att;
        end
        return nil;
    end

    local function quadraticBezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
        local u = 1 - t;
        return u*u*p0 + 2*u*t*p1 + t*t*p2;
    end

    local function quadraticBezierTangent(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
        return 2*(1-t)*(p1-p0) + 2*t*(p2-p1);
    end

    local function buildPathNode(startCF: CFrame, finishCF: CFrame, pivotCF: CFrame?): any
        local startPos = startCF.Position;
        local finishPos = finishCF.Position;
        local straightDist = (finishPos - startPos).Magnitude;

        local turnAngle = math.deg(math.acos(math.clamp(startCF.LookVector:Dot(finishCF.LookVector), -1, 1)));

        if pivotCF == nil or turnAngle < 12 or straightDist < 0.01 then
            return {
                Start = startCF;
                Finish = finishCF;
                Length = math.max(straightDist, 0.01);
            };
        end

        local control = Vector3.new(
            pivotCF.Position.X,
            (startPos.Y + finishPos.Y) * 0.5,
            pivotCF.Position.Z
        );

        local length = 0;
        local prev = startPos;
        local samples = 12;
        for i=1, samples do
            local p = quadraticBezier(startPos, control, finishPos, i/samples);
            length += (p - prev).Magnitude;
            prev = p;
        end

        return {
            Start = startCF;
            Finish = finishCF;
            Control = control;
            Length = math.max(length, 0.01);
        };
    end

    local function evaluatePathNode(node, alpha: number): (CFrame, Vector3)
        alpha = math.clamp(alpha, 0, 1);
        local cf = node.Start:Lerp(node.Finish, alpha);

        if node.Control == nil then
            return cf, node.Finish.Position - node.Start.Position;
        end

        local pos = quadraticBezier(node.Start.Position, node.Control, node.Finish.Position, alpha);
        local tangent = quadraticBezierTangent(node.Start.Position, node.Control, node.Finish.Position, alpha);
        return CFrame.new(pos) * cf.Rotation, tangent;
    end

    local function connectSegment(template: Instance, targetCF: CFrame): Instance?
        local clone = template:Clone();
        clone.Parent = map.Game;

        local clip = clone:WaitForChild("Clip");
        clip.Transparency = 1;

        local startAtt = findAttachment(clone, "StartPoint");
        if startAtt == nil then
            clone:Destroy();
            return nil;
        end

        local pivot = (clone :: any):GetPivot();
        local relStart = pivot:Inverse() * startAtt.WorldCFrame;
        (clone :: any):PivotTo(targetCF * relStart:Inverse());

        for _, part in pairs(clone:GetChildren()) do
            if part.Name ~= "_KillBox" then continue end;

            part.Touched:Connect(function(hitPart)
                local charList = shared.modPlayers.listCharacters();
                for a=1, #charList do
                    if not charList[a]:IsAncestorOf(hitPart) then continue end;
                    
                    local playerClass = shared.modPlayers.getByModel(charList[a]);
                    if playerClass then
                        Debugger:StudioLog(`Touch kill {charList[a]}`);
                        playerClass:Kill();
                    end
                    
                    break;
                end
            end)
        end

        return clone;
    end

    local pathNodes = {};
    local nodeIndex = 1;
    local nodeAlpha = 0;
    local cleanupCursor = 1;

    local startNode = buildPathNode(camEndPointAtt.WorldCFrame, endPointAtt.WorldCFrame, startSegment:GetPivot());
    startNode.Model = startSegment;
    table.insert(pathNodes, startNode);

    local lastEndCF = endPointAtt.WorldCFrame;
    local lastTemplate: Model? = nil;
    local generationFinished = false;
    local endSegmentAttached = false;

    local function pickSegmentTemplate(): Model?
        if #segmentTemplates == 0 then return nil end;

        local totalWeight = 0;
        for _, template in pairs(segmentTemplates) do
            local chance = template:GetAttribute("SpawnChance") or 1;
            if chance <= 0 then
                chance = 0;
            end
            totalWeight += chance;
        end

        if totalWeight <= 0 then
            return segmentTemplates[math.random(1, #segmentTemplates)];
        end

        local roll = math.random() * totalWeight;
        local accumulated = 0;
        for _, template in pairs(segmentTemplates) do
            local chance = template:GetAttribute("SpawnChance") or 1;
            if chance <= 0 then
                chance = 0;
            end
            accumulated += chance;
            if roll <= accumulated then
                return template;
            end
        end

        return segmentTemplates[#segmentTemplates];
    end

    local function generateNextSegment(): boolean
        if #segmentTemplates == 0 then return false end;

        local template = pickSegmentTemplate();
        if template == nil then return false end;

        if #segmentTemplates > 1 and template == lastTemplate then
            template = pickSegmentTemplate() or template;
        end

        local clone = connectSegment(template, lastEndCF);
        if clone == nil then return false end;

        local cloneStart = findAttachment(clone, "StartPoint");
        local cloneEnd = findAttachment(clone, "EndPoint");
        if cloneStart == nil or cloneEnd == nil then
            clone:Destroy();
            return false;
        end

        local node = buildPathNode(cloneStart.WorldCFrame, cloneEnd.WorldCFrame, (clone :: any):GetPivot());
        node.Model = clone;
        table.insert(pathNodes, node);

        lastEndCF = cloneEnd.WorldCFrame;
        lastTemplate = template;

        return true;
    end

    local function attachEndSegment()
        if endSegmentAttached then return end;
        endSegmentAttached = true;

        local clone = connectSegment(endSegment, lastEndCF);
        if clone == nil then return end;

        local cloneStart = findAttachment(clone, "StartPoint");
        local cloneEnd = findAttachment(clone, "EndPoint");
        if cloneStart == nil or cloneEnd == nil then
            clone:Destroy();
            return;
        end

        local node = buildPathNode(cloneStart.WorldCFrame, cloneEnd.WorldCFrame, (clone :: any):GetPivot());
        node.Model = clone;
        table.insert(pathNodes, node);

        lastEndCF = cloneEnd.WorldCFrame;
    end

    local killEnabledAt = gameStartTime + KILL_GRACE_TIME;
    local lastTick = workspace:GetServerTimeNow();

    while true do
        local now = workspace:GetServerTimeNow();
        local dt = math.clamp(now - lastTick, 0, 0.25);
        lastTick = now;

        for a=#playerClasses, 1, -1 do
            local playerClass = playerClasses[a];
            if playerClass.HealthComp == nil or playerClass.HealthComp.IsDead then
                table.remove(playerClasses, a);
            end
        end

        if #playerClasses == 0 then break end;

        if not generationFinished and now >= gameEndTime then
            generationFinished = true;
            attachEndSegment();
        end

        if not generationFinished then
            local generated = 0;
            while (#pathNodes - nodeIndex) < SEGMENT_AHEAD and generated < 8 do
                if not generateNextSegment() then break end;
                generated += 1;
            end
        end

        local progress = math.clamp((now - gameStartTime) / roundTime, 0, 1);
        local speed = BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (progress ^ SPEED_CURVE);

        local remaining = speed * dt;
        local iterations = 0;
        while remaining > 0 and iterations < 64 do
            iterations += 1;

            local node = pathNodes[nodeIndex];
            if node == nil then break end;

            local distLeft = (1 - nodeAlpha) * node.Length;
            if remaining < distLeft then
                nodeAlpha += remaining / node.Length;
                remaining = 0;
            else
                remaining -= distLeft;
                nodeIndex += 1;
                nodeAlpha = 0;

                if pathNodes[nodeIndex] == nil then
                    nodeIndex = #pathNodes;
                    nodeAlpha = 1;
                    remaining = 0;
                end
            end
        end

        local cleanupIndex = nodeIndex - CLEANUP_BEHIND;
        while cleanupCursor <= cleanupIndex do
            local oldNode = pathNodes[cleanupCursor];
            if oldNode and oldNode.Model then
                oldNode.Model:Destroy();
                oldNode.Model = nil;

                if math.random(1, 4) == 1 then
                    local roarSnd = modAudio.Play(math.random(1,2) == 1 and "ChargeRoar" or "AggressiveRoar", camAttachment.RoarSndAtt);
                    roarSnd.PlaybackSpeed = math.random(90, 120)/100;
                end
            end
            cleanupCursor += 1;
        end

        local node = pathNodes[nodeIndex];
        if node == nil then break end;

        local pathCF, tangent = evaluatePathNode(node, nodeAlpha);
        camAttachment.WorldCFrame = pathCF * camOffset;

        if now >= killEnabledAt then
            local flatTangent = Vector3.new(tangent.X, 0, tangent.Z);
            if flatTangent.Magnitude < 0.001 then
                flatTangent = Vector3.new(0, 0, -1);
            else
                flatTangent = flatTangent.Unit;
            end

            local pathPos = pathCF.Position;
            for a=#playerClasses, 1, -1 do
                local playerClass = playerClasses[a];
                local rootPart = playerClass.RootPart;
                if rootPart == nil then continue end;

                local forwardDist = (rootPart.Position - pathPos):Dot(flatTangent);
                if forwardDist < -KILL_DISTANCE then
                    table.remove(playerClasses, a);
                    playerClass.StatusComp:Apply("AttachedCamera", nil);
                    playerClass:Kill("SewerRun");
                end
            end
        end

        if generationFinished and nodeIndex >= #pathNodes and nodeAlpha >= 1 then
            break;
        end

        task.wait(TICK_RATE);
    end
    



    for _, playerClass in pairs(cameraPlayers) do
        if playerClass.StatusComp then
            playerClass.StatusComp:Apply("AttachedCamera", nil);
        end
    end
    for _, playerClass in pairs(shared.modPlayers.listPlayerClasses()) do
        playerClass:Despawn();
    end

    fadeOutSound(gameMusic);
    self:Timer();

    if #playerClasses == 0 then
        self:Broadcast(nil, `Nobody survived..`, 1);
        task.wait(5);

    elseif #playerClasses == 1 then
        local winnerPlayerClass = playerClasses[1];
        local winnerPlayer = winnerPlayerClass:GetInstance();

        self:Broadcast(nil, `Only {winnerPlayer.DisplayName} survived!`, 3);
        self:AddScore(winnerPlayerClass:GetInstance(), roundTime + (#self.Profiles * 10));
        task.wait(7);

    else
        for a=1, #playerClasses do
            local survivorPlayerClass = playerClasses[a];
            self:AddScore(survivorPlayerClass:GetInstance(), roundTime + (#self.Profiles * 5));
        end

        self:Broadcast(nil, `Survivors earns bonus points..`, 3);
        task.wait(7);

    end

    Debugger.Expire(map);
end





--MARK: Game_PlatformMatch
function WorldCore:Game_PlatformMatch()
    local map = self:LoadMap("SpiralChamber");
    local spawnAttList = map:WaitForChild("Spawns"):GetChildren();
    local killBox: BasePart = map:WaitForChild("Game"):WaitForChild("_KillBox");

    local pistonsFolder = map:WaitForChild("Game"):WaitForChild("Pistons");
    pistonsFolder:Destroy();

    local unstablePlatforms = map:WaitForChild("Game"):WaitForChild("UnstablePlatforms");

    local screens = {};
    local symbols = {"Δ"; "Ψ"; "Σ"; "Ω"};

    for _, obj in pairs(unstablePlatforms:GetChildren()) do
        local surfaceTextLabel = obj:FindFirstChild("SurfaceTextLabel", true);
        if surfaceTextLabel then
            table.insert(screens, surfaceTextLabel);

            if obj.Name == "Platform" then
                local cfV = Instance.new("CFrameValue");
                cfV.Parent = obj;

                cfV.Value = obj:GetPivot();
                cfV:SetAttribute("DefaultCFrame", cfV.Value);
                cfV:GetPropertyChangedSignal("Value"):Connect(function()
                    obj:PivotTo(cfV.Value);
                end)

                surfaceTextLabel:SetAttribute("PlatformInstance", cfV);
            end
        end
    end

    local startTime = workspace:GetServerTimeNow() + 6;
    local roundTime = 45;

    local playerClasses: {PlayerClass} = self:SpawnCharacters();

    self.Garbage:Tag(shared.modPlayers.OnPlayerDied:Connect(function(playerClass)
        local idx = table.find(playerClasses, playerClass);
        if idx == nil then return end;
        table.remove(playerClasses, idx);
        
        local diedPlayer = playerClass:GetInstance();

        local timeSurvived = math.clamp( math.floor(workspace:GetServerTimeNow() - startTime), 1, 59);
        self:AddScore(diedPlayer, timeSurvived);

        self:BoardcastKill(diedPlayer);
    end))
    
    for _, playerClass in pairs(playerClasses) do
        local pickSpawnAtt = table.remove(spawnAttList, math.random(1, #spawnAttList));
        playerClass:SetCFrame(pickSpawnAtt.WorldCFrame);

        playerClass.StatusComp:Apply("Stun", {});
    end

    killBox.Touched:Connect(function(hitPart)
        local charList = shared.modPlayers.listCharacters();
        for a=1, #charList do
            if not charList[a]:IsAncestorOf(hitPart) then continue end;
            
            local playerClass = shared.modPlayers.getByModel(charList[a]);
            if playerClass then
                Debugger:StudioLog(`Touch kill {charList[a]}`);
                playerClass:Kill();
            end
            
            break;
        end
    end)

    self:Broadcast(`Game {self.GameIndex}: Platform Match`, `Match the symbols to survive!`, `votecontinue`);
    self:Timer(startTime, true);

    for _, playerClass in pairs(playerClasses) do
        playerClass.StatusComp:Apply("Stun", nil);
        playerClass.WieldComp:Equip{
			ItemId = "pushtool";
			ProxyEquip = true;
		};
    end

    local gameStartTime = workspace:GetServerTimeNow();
    self:Timer(gameStartTime + roundTime);

    local gameMusic = modAudio.Play("Soundtrack:SpookyPartyNights", workspace);
    self.Garbage:Tag(gameMusic);

    local activeSymbol = "Δ";

    local function setScreensSymbol(str)
        for a=1, #screens do
            screens[a].Text = str;
        end
    end

    while #playerClasses > 0 do
        task.wait(2);
        local curTick = workspace:GetServerTimeNow();

        for a=1, 8 do
            task.wait(0.5);
            modAudio.Play("IncorrectBuzz", workspace).PlaybackSpeed = 2;
            activeSymbol = symbols[math.random(1, 4)];
            setScreensSymbol(activeSymbol);
        end

        task.wait(0.5);
        modAudio.Play("IncorrectBuzz", workspace).PlaybackSpeed = 1;

        local platformToDropList = {};
        local alivePlatformScreens = {};
        local activeSymbolHeld = false;

        for a=1, #screens do
            local platform = screens[a]:GetAttribute("PlatformInstance");
            if platform == nil then continue end;
            if platform:Get() == nil then continue end;

            table.insert(alivePlatformScreens, a);

            local offset = math.random(1, 4);
            local rngSymbol = symbols[((a + offset)%4) +1];
            screens[a].Text = rngSymbol;

            if rngSymbol ~= activeSymbol then
                table.insert(platformToDropList, platform);
            else
                activeSymbolHeld = true;
            end
        end

        if not activeSymbolHeld and #alivePlatformScreens > 0 then
            local savedScreenIndex = alivePlatformScreens[math.random(1, #alivePlatformScreens)];
            local savedPlatform = screens[savedScreenIndex]:GetAttribute("PlatformInstance");

            screens[savedScreenIndex].Text = activeSymbol;

            local dropIndex = table.find(platformToDropList, savedPlatform);
            if dropIndex then
                table.remove(platformToDropList, dropIndex);
            end
        end
        Debugger:Log("Active Symbol", activeSymbol);

        task.wait(2);

        for a=1, #platformToDropList do
            local platformCfValueIH: InstanceHandle = platformToDropList[a];
            if platformCfValueIH == nil then continue end;

            local platformCfValue = platformCfValueIH:Get();
            if platformCfValue == nil then continue end;

            local defaultCf = platformCfValue:GetAttribute("DefaultCFrame");

            local tween = TweenService:Create(
                platformCfValue, 
                TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.In), 
                {
                    Value = defaultCf * CFrame.new(0, -28, 0);
                }
            );
            tween.Completed:Connect(function()
                task.wait(1);
                if math.random(1, 3) == 1 then 
                    platformCfValue:Destroy();
                    return 
                end;

                TweenService:Create(platformCfValue, 
                    TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In), 
                    {
                        Value = defaultCf;
                    }
                ):Play();
            end)
            tween:Play();
        end

        task.wait(2);

        Debugger:Log(`# playerClasses alive: {#playerClasses}`);
        if #playerClasses <= 0 or curTick-gameStartTime > roundTime then
            break;
        end
    end

    fadeOutSound(gameMusic);
    self:Timer();
    
    for _, playerClass in pairs(shared.modPlayers.listPlayerClasses()) do
        playerClass:Despawn();
    end

    if #playerClasses == 0 then
        self:Broadcast(nil, `Nobody survived..`, 1);
        task.wait(5);

    elseif #playerClasses == 1 then
        local winnerPlayerClass = playerClasses[1];
        local winnerPlayer = winnerPlayerClass:GetInstance();

        self:Broadcast(nil, `Only {winnerPlayer.DisplayName} survived!`, 3);
        self:AddScore(winnerPlayerClass:GetInstance(), roundTime + (#self.Profiles * 10));
        task.wait(7);

    else
        for a=1, #playerClasses do
            local survivorPlayerClass = playerClasses[a];
            self:AddScore(survivorPlayerClass:GetInstance(), roundTime + (#self.Profiles * 5));
        end

        self:Broadcast(nil, `Survivors earns bonus points..`, 3);
        task.wait(7);

    end

    Debugger.Expire(map);

end



return WorldCore;