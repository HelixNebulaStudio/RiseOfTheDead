local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modHealthComponents = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSfxService = shared.require(game.ReplicatedStorage.Library.SfxService);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modGameModeRaid = shared.require(game.ServerScriptService.ServerLibrary.GameModeRaid);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modRailwaySystem = shared.require(game.ServerScriptService.ServerLibrary.RailwaySystem);

    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Raid", "Railways";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeRaid.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.Objective = {
        Id = "Objective";
        EnemyCap = 45;

        HordeCycle = 999999;
        HordeSpawnRate = 1;
        HordeTimerDeduction = NumberRange.new(25, 35);
    };

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Leaper"; Chance=15; Fmod=15;};
        {Name="Ticks"; Chance=10; Fmod=10;};
        {Name="Growler"; Chance=10; Fmod=10;};
        {Name="Heavy"; Chance=0.1; Fmod=10;};
    };

    task.spawn(function()
        newGameController:Load();
        WorldCore.InitMapLogic(newGameController);
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    
    modRailwaySystem.init();
    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);
end

function WorldCore.InitMapLogic(gameController)
    local gameEnvironment = workspace.Environment.Game;

    local trainPrefab = gameEnvironment:WaitForChild("TrainFrontCar");
    trainPrefab.Name = `Train`;
    trainPrefab:SetAttribute("EntityHudHealth", true);

    local templateTrainPrefab = trainPrefab:Clone();

    local trainObject = modRailwaySystem.Train.new(trainPrefab);
    local maxTrainSpeed = 60;

	trainObject.Enabled = false;
	modRailwaySystem:AddTrain(trainObject);

    local trainInteractable: InteractableInstance = modInteractables.getById("TrainControls");

    --MARK: Touch handler
    local touchHandler = modTouchHandler.new("TrainHurt", 1);
    function touchHandler:OnHumanoidTouch(humanoid, basePart, part)
        local healthComp: HealthComp? = modHealthComponents.getByModel(humanoid.Parent);
        if healthComp == nil or healthComp.IsDead then return end;

        if healthComp.CompOwner.ClassName ~= "NpcClass" then return end;
        if trainObject.Speed <= 0 or trainObject.Enabled == false then return end;

        local npcClass: NpcClass = healthComp.CompOwner :: NpcClass;

        local rootPart = npcClass.RootPart;
        rootPart.Velocity = basePart.CFrame.LookVector* trainObject.Speed*6
            + Vector3.new(0, 100, 0)
            + basePart.CFrame.RightVector * math.random(-trainObject.Speed, trainObject.Speed);

        if trainObject.Speed > 25 then
            healthComp:TakeDamage(DamageData.new{
                Damage = healthComp.MaxHealth+100;
            });
        end
    end
    touchHandler:AddObject(trainPrefab:WaitForChild("trainShield"));
    touchHandler:AddObject(trainPrefab:WaitForChild("trainKillBox"));



    --MARK: Train Collision Ray
    local rayInfo = RaycastParams.new(); 
    rayInfo.FilterType = Enum.RaycastFilterType.Include;
    rayInfo.FilterDescendantsInstances = {gameEnvironment.TrackDebris;};
    local trainFrontRay = trainPrefab:WaitForChild("frontRayOrigin");
    local scanRange = 128;

    function trainObject:OnStepped(delta)
        local rayOrigin = trainFrontRay.Position;
        local rayDir = trainFrontRay.CFrame.LookVector*scanRange;
        local rayResult = workspace:Raycast(rayOrigin, rayDir, rayInfo);

        if shared.gameConfig.DebugTrainRay == true then
            game.Debris:AddItem(Debugger:Ray(
                Ray.new(rayOrigin, rayDir), 
                rayResult and rayResult.Instance, 
                rayResult and rayResult.Position
            ), 0.1);
        end

        local rayHit = rayResult and rayResult.Instance;
        local rayPoint = rayResult and rayResult.Position or rayOrigin+rayDir;
        
        local distance = (rayOrigin-rayPoint).Magnitude;
        if distance <= 25 then
            self:SetSpeed(0);
            
            if distance <= 5 then
                trainObject.Enabled = false;
                trainPrefab.TrainConfig:SetAttribute("DebrisInTheWay", true);
                trainInteractable.Config:SetAttribute("IsActive", false);
            else
                trainPrefab.TrainConfig:SetAttribute("DebrisInTheWay", false);
            end

        else
            trainPrefab.TrainConfig:SetAttribute("DebrisInTheWay", false);
            local speed = distance/scanRange * maxTrainSpeed;
            self:SetSpeed(speed);
        end
    end



    local animatedTrainModel = gameEnvironment:WaitForChild("AnimatedTrains");
    local derailTrainDebris = gameEnvironment:WaitForChild("TrackDebris"):WaitForChild("DerailTrainDebris");
    local animatedTrainAnimator: Animator = animatedTrainModel:WaitForChild("AnimationController"):WaitForChild("Animator");
    local redTrainAnimation: AnimationTrack = animatedTrainAnimator:LoadAnimation(animatedTrainModel:WaitForChild("Main"));
    redTrainAnimation:Play();
    redTrainAnimation:AdjustSpeed(0);
    redTrainAnimation:GetMarkerReachedSignal("Pause"):Connect(function() 
        redTrainAnimation:AdjustSpeed(0);
    end)

    local hudPacket = {
        HeaderText = `Scavenge`;
        StatusText = `Make your way to the abandoned train container`;
        HookEntity = {trainPrefab};

        RaidMarker = {
            Target = Vector3.new(1706.703, 84.782, -773.85);
            Label = "Abandoned Train Container";
        };
    };

    local function sethud(packet)
        gameController:Hud(packet or hudPacket);
    end
    sethud();

    --MARK: Destructibles_BindDestroyed
    shared.modEventService:OnInvoked("Destructibles_BindDestroyed", function(event: EventPacket, ...)
        local destructible: DestructibleInstance = ...;

        local player = event.Player;
        local playerClass: PlayerClass? = player and shared.modPlayers.get(player) or nil;
        
        Debugger:Warn(`destructible {destructible.Name}({destructible.Id}) destroyed`);
        if destructible.Id == "StartBarricade1" or destructible.Id == "StartBarricade2" then
            Debugger:Warn(`Alert zombies`);

            if playerClass then
                task.delay(1, function()
                    shared.modNpcs.attractNpcs(playerClass.Character, 64, function(npcClass: NpcClass)
                        if npcClass.HumanoidType == "Zombie" then
                            npcClass.Properties.HordeAggression = true;
                        end
                    end);
                end)
            end

            local trainDestructibleConfig = modDestructibles.createDestructible("Scarecrow");
            trainDestructibleConfig:SetAttribute("_AttractRange", 128);
            trainDestructibleConfig:SetAttribute("_ExpiringDamageTick", false);
            trainDestructibleConfig:SetAttribute("_HordeAggression", true);
            trainDestructibleConfig:SetAttribute("DebrisName", "TrainDebris");
            trainDestructibleConfig.Parent = trainPrefab;
            local trainDestructibleInstance: DestructibleInstance = modDestructibles.getOrNew(trainDestructibleConfig);
            trainDestructibleInstance.BroadcastHealth = true;
            trainDestructibleInstance.HealthComp:SetCanBeHurtBy("!Player&!Human");
            trainDestructibleInstance.HealthComp:SetMaxHealth(10000);
            trainDestructibleInstance.HealthComp:Reset();

            trainDestructibleInstance.HealthComp.OnHealthChanged:Connect(function(newHealth, oldHealth, damageData)
                local damage = damageData.Damage;
                if damage == nil or damage <= 0 then return end;

                if trainObject.SpeedPenalty <= 0.25 then
                    trainObject.SpeedPenalty = 0.25;
                else
                    trainObject.SpeedPenalty = math.min(trainObject.SpeedPenalty + math.random(35, 65)/1000, 1);
                end
            end)

            trainDestructibleInstance:SetupHealthbar{
                Size = UDim2.new(10, 0, 2, 0);
                Distance = 256;
                OffsetWorldSpace = Vector3.new(0, 22, 0);
                ShowLabel = false;
            };

            sethud();
        end
    end)

    trainInteractable.Values.OnChanged:Connect(function(k, v, ov)
        if k == "IsActive" then
            if trainInteractable.Values.DebrisInTheWay then trainInteractable:Reset(); return end;
            if v == true then
				trainObject.Speed = 0;
				trainObject.Enabled = true;
				trainObject:SetSpeed(maxTrainSpeed);
            else
                trainObject.Enabled = false;
                trainObject:SetSpeed(0);

            end
        end
    end)

    --MARK: Generic_BindTrigger
    shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
        local triggerId: string, interactable: InteractableInstance = ...;
        local ZScript = shared.ZScript;

        Debugger:StudioLog(`BindTrigger`, triggerId);
        if triggerId == "RedTrain" then
            local isActive = interactable.Values.IsActive == true;

            if isActive then
                trainInteractable:Reset();
                redTrainAnimation:AdjustSpeed(1);
                local snd = modAudio.Play("TrainLoop", animatedTrainModel.RedTrainFront.PrimaryPart);
                task.delay(5.4, function()
                    snd:Destroy();

                    local surfaceSound = modSfxService.getSurfaceSound("HeavyMetal");
                    surfaceSound = surfaceSound:Clone();
                    surfaceSound.Parent = animatedTrainModel.RedTrainFront.PrimaryPart;
                    surfaceSound:Play();
                end)
                game.Debris:AddItem(derailTrainDebris, 5.2);
                shared.gameConfig.HordeTimer = tick();
            end

        elseif triggerId == "GateLever" then
            if not interactable.Values.IsActive then return end;

            local duration = 60;
            trainPrefab.TrainConfig:SetAttribute("TrainOffline", workspace:GetServerTimeNow()+duration);

            trainInteractable:Reset();
            trainInteractable:SetPermissions("CanInteract", false);
            shared.gameConfig.HordeTimer = tick();

            sethud({
                StatusText = `Defend the train while the gate opens!`;
            });
            interactable.Label = `Station gate is opening...`;
            interactable.CanInteract = false;
            interactable:Sync();


            local stationGateMotor: Motor6D = ZScript.findByName("StationGateMotor");
            local sndGateOpening = modAudio.Play("GateOpening", stationGateMotor);
            sndGateOpening.PlaybackSpeed = 0.5;
            sndGateOpening.Volume = 0;
            TweenService:Create(sndGateOpening, TweenInfo.new(2), {Volume=1;}):Play();
            TweenService:Create(stationGateMotor, TweenInfo.new(duration), {
                C1 = CFrame.new(19, 0, 0);
            }):Play();

            task.delay(duration-8, function()
                modAudio.Play("HangerGateOpen", stationGateMotor).PlaybackSpeed = 0.5;
            end)
            task.delay(duration, function()
                modAudio.Play("DustbinHorn", interactable.Part);

                trainPrefab.TrainConfig:SetAttribute("TrainOffline", nil);
                trainInteractable:SetPermissions("CanInteract", true);
                sethud();
                sndGateOpening:Stop();
                
                interactable.Label = `Train is ready to move!`;
                interactable.CanInteract = false;
                interactable:Sync();
            end)


        elseif triggerId == "EndLever" then
            if not interactable.Values.IsActive then return end;

            local duration = 60;
            trainPrefab.TrainConfig:SetAttribute("TrainOffline", workspace:GetServerTimeNow()+duration);

            trainInteractable:Reset();
            trainInteractable:SetPermissions("CanInteract", false);
            shared.gameConfig.HordeTimer = tick();

            sethud({
                StatusText = `Defend the train while the container opens!`;
            });
            interactable.Label = `Red container car is opening...`;
            interactable.CanInteract = false;
            interactable:Sync();

            local motorDoorA: Motor6D = ZScript.findByName("DoorA");
            local sndGateOpening = modAudio.Play("GateOpening", motorDoorA);
            sndGateOpening.PlaybackSpeed = 0.5;
            sndGateOpening.Volume = 0;
            TweenService:Create(sndGateOpening, TweenInfo.new(5), {Volume=1;}):Play();
            TweenService:Create(motorDoorA, TweenInfo.new(duration), {
                C1 = CFrame.new(0, 0, -5);
            }):Play();
            local motorDoorB: Motor6D = ZScript.findByName("DoorB");
            TweenService:Create(motorDoorB, TweenInfo.new(duration), {
                C1 = CFrame.new(0, 0, 5);
            }):Play();
            local motorDoorC: Motor6D = ZScript.findByName("DoorC");
            TweenService:Create(motorDoorC, TweenInfo.new(duration), {
                C1 = CFrame.new(0, 0, -5);
            }):Play();
            local motorDoorD: Motor6D = ZScript.findByName("DoorD");
            TweenService:Create(motorDoorD, TweenInfo.new(duration), {
                C1 = CFrame.new(0, 0, 5);
            }):Play();

            task.delay(duration-5, function()
                modAudio.Play("HangerGateOpen", motorDoorA).PlaybackSpeed = 2;
            end)
            task.delay(duration, function()
                modAudio.Play("DustbinHorn", interactable.Part);

                trainPrefab.TrainConfig:SetAttribute("TrainOffline", nil);
                trainInteractable:SetPermissions("CanInteract", true);

                sndGateOpening:Stop();
                local finalTrainClip = ZScript.findByName("FinalTrainClip");
                finalTrainClip:Destroy();
                interactable.Label = `Red container car is opened!`;
                interactable.CanInteract = false;
                interactable:Sync();
            end)

        elseif triggerId == "FinalCrate" then
            sethud({
                HeaderText = `Scavenge`;
                StatusText = `Complete!`;

                RaidMarker = false;
            });
            gameController:CompleteRaid();

        end;

    end)
end

return WorldCore;