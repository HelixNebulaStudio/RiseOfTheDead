local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService");

local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Bandit Pilot";
    HumanoidType = "Bandit";
    
	Configurations = {
        MaxHealth = 100;
    };
    Properties = {
        Smart = true;
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 256;

        Level = 1;
        ExperiencePool = 1000;
        MoneyReward = NumberRange.new(3700, 4300);

        KnockbackResistant = 1;
        SkipMoveInit = true;

        State = "Circle";
        StateChangedTick = tick();

        HelicopterInstance = nil;

        GunmenSpawned = false;
        GunmenNpcClasses = {};
        HeavyBanditsNpcClasses = {};

        DespawnGunmen = Debugger.func;
        DespawnHeavyBandits = Debugger.func;
    };
    Audio={
        Hurt=false;
    };

    AddComponents = {
        "TargetHandler";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };
    
    ThinkCycle = 0.3;
};

function npcPackage.onRequire()
    baseHelicopterRig = game.ServerStorage.Prefabs.Objects.BanditHelicopterRig;
    hardHelicopterRig = game.ServerStorage.Prefabs.Objects.HardBanditHelicopterRig;
end

--MARK: createHelicopter
function npcPackage.createHelicopter(isHard: boolean, spawnPoint: Vector3)
    local heliModel = (isHard and hardHelicopterRig or baseHelicopterRig):Clone();

    local heliBase: BasePart = heliModel:WaitForChild("Root");
    local animator: Animator = heliModel:WaitForChild("AnimationController"):WaitForChild("Animator");
    
    local animationsFolder = heliModel:WaitForChild("Animations");

    local bodyPosition = heliBase:WaitForChild("BodyPosition");
    local bodyGyro = heliBase:WaitForChild("BodyGyro");

    local self = {
        Model = heliModel;
        PrimaryPart = heliBase;
        BodyPosition = bodyPosition;
        BodyGyro = bodyGyro;

        WorldRotationY = math.rad(0);
        Speed = 50;

        RotRoll = 0;
        RotYaw = 0;
        RotPitch = 0;

        Altitude = 60;
        IsBodyColliding = false;
        CollisionAltitudeOffset = 0;

        Position = spawnPoint;
        CirclingPoint = spawnPoint;
        LastPosition = spawnPoint;

        MoveState = "TransitionToCircle";
        State = "Idle";
        DoorsOpen = nil;
        
        CirclingRadius = 100;

        Animations = {
            OpenDoors = animator:LoadAnimation(animationsFolder:WaitForChild("OpenDoors"));
        };
        
        Destructibles = {};
    };
	
    local circleRad = -math.pi/2;
    local circlingRate = math.pi/(360*2.5);
    local invertCircling = true;
    local flipCirclingTimer = tick();
    local heliCollisionScanTick = tick()+5;

    function self:ToggleDoors(v)
        if self.DoorsOpen == v then return end

        self.DoorsOpen = v;

        if self.DoorsOpen then
            if self.Animations.OpenDoors.IsPlaying then return end;
            self.Animations.OpenDoors:Play();
        else
            if not self.Animations.OpenDoors.IsPlaying then return end;
            self.Animations.OpenDoors:Stop();
        end
    end

    function self:Step()
        if tick() > heliCollisionScanTick then
            heliCollisionScanTick = tick()+1;

            local overlapParams = OverlapParams.new();
            overlapParams.FilterType = Enum.RaycastFilterType.Include;
            overlapParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
            local hitParts = workspace:GetPartBoundsInRadius(heliModel:GetPivot().Position, 10, overlapParams);
            self.IsBodyColliding = #hitParts > 0;
        end

        self.CollisionAltitudeOffset = math.max(self.CollisionAltitudeOffset + (self.IsBodyColliding and 0.2 or -0.2), 0);

        local altitudeVec = Vector3.new(0, self.Altitude + self.CollisionAltitudeOffset, 0);
        local worldDir = modVector.CleanUnitVec(heliBase.Position, bodyPosition.Position);

        if self.MoveState == "TransitionToCircle" then
            local cf = CFrame.new(self.CirclingPoint + altitudeVec) 
                    * CFrame.Angles(0, circleRad, 0) 
                    * CFrame.new(self.CirclingRadius, 0, 0);
            
            local targetPoint = cf.Position;

            local origin = heliBase.Position;
            local displace = (origin-targetPoint);
            local dir = displace.Unit;
            local dist = displace.Magnitude;

            self.WorldRotationY = math.atan2(dir.Z, -dir.X);
            
            if dist < 8 then
                self.MoveState = "Circle";

            elseif dist < 100 then
                bodyPosition.Position = origin:Lerp(targetPoint, 0.2);

            elseif dist < 200 then
                bodyPosition.Position = origin:Lerp(targetPoint, 0.1);
                
            elseif dist < 400 then
                bodyPosition.Position = origin:Lerp(targetPoint, 0.05);

            end;
            
            self.WorldRotationY = math.atan2(worldDir.Z, -worldDir.X);
            self.LastPosition = heliBase.Position;

        elseif self.MoveState == "Target" and self.TargetPoint then
            local targetPoint = self.TargetPoint + altitudeVec;

            local origin = self.TargetStartPoint;
            local displace = (origin-targetPoint);
            local dir = displace.Unit;
            local dist = displace.Magnitude;

            local timeLapsed = math.max(tick()-self.TargetPointSetTick, 0);
            local travelTime = dist/self.Speed;

            local lerpAlpha = math.clamp(timeLapsed/travelTime, 0, 1);
            
            self.WorldRotationY = math.atan2(dir.Z, -dir.X);
            
            if lerpAlpha >= 0.99 then
                self.IsAtTarget = true;
                self.TargetPoint = nil;
                self.MoveState = "Idle";
                Debugger:Warn(`IsAtTarget`);

            else
                bodyPosition.Position = self.TargetStartPoint:Lerp(targetPoint, lerpAlpha);
                
            end;

            self.WorldRotationY = math.atan2(worldDir.Z, -worldDir.X);
            self.LastPosition = heliBase.Position;

        elseif self.MoveState == "Circle" then
            local cf = CFrame.new(self.CirclingPoint + altitudeVec) 
                    * CFrame.Angles(0, circleRad, 0) 
                    * CFrame.new(self.CirclingRadius, 0, 0);
            circleRad = circleRad + circlingRate * (invertCircling and 1 or -1);

            if tick()-flipCirclingTimer > 35 then
                flipCirclingTimer = tick();
                invertCircling = not invertCircling;
            end
            
            bodyPosition.Position = cf.p;
            
            local rotRoll, rotYaw, rotPit;
            if self.State == "RocketSpam" then
                rotRoll = 0.05 * (invertCircling and -1 or 1);
                rotYaw = 1.4 * (invertCircling and 1 or -1);
                rotPit = -0.5;
                
            else
                rotRoll = 0.5 * (invertCircling and -1 or 1);
                rotYaw = 0.6 * (invertCircling and 1 or -1);
                rotPit = 0;
                
            end

            self.RotRoll = modMath.Lerp(self.RotRoll, rotRoll, 0.1);
            self.RotYaw = modMath.Lerp(self.RotYaw, rotYaw, 0.1);
            self.RotPitch = modMath.Lerp(self.RotPitch, rotPit, 0.1);

            self.WorldRotationY = math.atan2(worldDir.Z, -worldDir.X);
            self.LastPosition = heliBase.Position;

        else
            bodyPosition.Position = self.LastPosition;

            self.RotRoll = modMath.Lerp(self.RotRoll, 0, 0.1);
            self.RotYaw = modMath.Lerp(self.RotYaw, 0, 0.1);
            self.RotPitch = modMath.Lerp(self.RotPitch, 0, 0.1);
        end
        
        local swayRot = CFrame.Angles(math.sin(tick()/2)/4, 0, math.sin(tick()/2)/4); -- Roll, Yaw, Pitch
        local midAng, maxAng = math.rad(-90), math.rad(90);
        local rotZ = -math.clamp(math.atan(worldDir.Z)/2, midAng, maxAng);
        local rotX = math.clamp(math.atan(worldDir.X)/2, midAng, maxAng);
        bodyGyro.CFrame = CFrame.Angles(rotZ, 0, rotX) 
            * CFrame.Angles(0, self.WorldRotationY, 0) 
            * CFrame.Angles(self.RotRoll, self.RotYaw, self.RotPitch)
            * swayRot;
    end

    function self:Move(targetPoint: Vector3)
        if self.TargetPoint and self.TargetPoint:FuzzyEq(targetPoint, 1) then return end;

        self.IsAtTarget = false;
        self.TargetPoint = targetPoint;
        self.TargetStartPoint = heliBase.Position;
        self.TargetPointSetTick = tick();
        self.MoveState = "Target";
    end

    heliModel.Name = "Helicopter";

    local newSpawnCf = CFrame.new(
        spawnPoint.X, 
        spawnPoint.Y + self.Altitude + 60,
        spawnPoint.Z - 300
    )

	heliModel:PivotTo(newSpawnCf);
    local heliParts = heliModel:GetChildren();
    for a=1, #heliParts do
        local heliPartGroup = heliParts[a];
        if not heliPartGroup:IsA("Model") then continue end;

        local newDestructInfo;

        local groupName = heliPartGroup.Name;
        if groupName == "TopCover" then
            newDestructInfo = {
                Health = isHard and 25000 or 10000;
            };

        elseif groupName == "FrontTip" then
            newDestructInfo = {
                Health = isHard and 50000 or 10000;
            };

        elseif groupName == "TailPart" then
            newDestructInfo = {
                Health = isHard and 25000 or 25000;
            };

        elseif groupName == "LeftLauncher" or groupName == "RightLauncher" then
            newDestructInfo = {
                Health = isHard and 40000 or 40000;
            };

        elseif groupName == "ScrapPlating" then
            newDestructInfo = {
                Name = "ScrapPlating";
                Health = isHard and 10000 or 5000;
            };
        end

        if newDestructInfo then
            local destructibleConfig = modDestructibles.createDestructible(newDestructInfo.Name);
            destructibleConfig.Parent = heliPartGroup;

            local destructibleInstance: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
            destructibleInstance.Properties.DestroyModel = false;

            destructibleInstance.HealthComp:SetMaxHealth(newDestructInfo.Health);
            destructibleInstance.HealthComp:Reset();

            destructibleInstance:SetupHealthbar{
                Size = UDim2.new(1.2, 0, 0.25, 0);
                Distance = 128;
                OffsetWorldSpace = Vector3.new(0, 1, 0);
                ShowLabel = false;
            };
            destructibleInstance:SetHealthbarEnabled(true);

            destructibleInstance.OnDestroy:Connect(function()
                local parts = {};
                for _, obj in pairs(destructibleInstance.Model:GetChildren()) do
                    if not obj:IsA("BasePart") then continue end;

				    obj.Color = Color3.fromRGB(25, 25, 25);
                    table.insert(parts, obj);
                end
                if #parts <= 0 then return end;

                local part = parts[math.random(1, #parts)];
                if part == nil then return end;

				local smoke = Instance.new("Smoke");
				smoke.Color = Color3.fromRGB(0, 0, 0);
				smoke.Size = 5;
				smoke.RiseVelocity = 10;
				smoke.Opacity = 1;
				smoke.Parent = part;

				local fire = Instance.new("Fire");
				fire.Heat = 15;
				fire.Size = 10;
				fire.Parent = part;
				
				modAudio.Play("VechicleExplosion", part).PlaybackSpeed = math.random(90,110)/100;
            end)

            table.insert(self.Destructibles, destructibleInstance);
        end
    end

    return self;
end


--MARK: Spawning
function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp = npcClass.HealthComp;

    local npcChar = npcClass.Character;

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    if isHard then
        configurations.BaseValues.MaxHealth = math.max(960000 + 10000*level, 100);
        configurations.BaseValues.MaxArmor = 1000;
        properties.Immunity = 1;

    else
        configurations.BaseValues.MaxHealth = math.max(320000 + 4000*level, 100);
        configurations.BaseValues.MaxArmor = 1000;
    end

    local heliInstance = npcPackage.createHelicopter(isHard, npcClass.SpawnPoint.Position);
    local heliModel = heliInstance.Model;
    heliInstance.Model.Parent = npcChar;

    local helicopterTag = Instance.new("ObjectValue");
    helicopterTag.Name = "Helicopter";
    helicopterTag.Value = heliModel;
    helicopterTag.Parent = npcClass.Character;

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    healthComp.OnArmorChanged:Connect(function(newArmor, oldArmor, damageData)
        if newArmor > oldArmor then return end;

        if newArmor <= 0 then
            heliModel:SetAttribute("EntityParent", true);
        end
    end)

    for a=1, #heliInstance.Destructibles do
        local destructibleInstance: DestructibleInstance = heliInstance.Destructibles[a];
        local destructModel = destructibleInstance.Model;
        bodyDestructiblesComp:Add(destructModel.Name, destructibleInstance);

        if destructModel.Name == "ScrapPlating" then 
            local debrisParts = {};
            for _, part in pairs(destructibleInstance.Model:GetChildren()) do
                if part.Name ~= "DebrisParts" then continue end;
                table.insert(debrisParts, part);
            end
            
            destructibleInstance.HealthComp.OnHealthChanged:Connect(function(curHealth, oldHealth, damageData)
                if curHealth > oldHealth then return end;
                healthComp:TakeDamage(DamageData.new{
                    Damage = 1;
                    DamageBy = damageData.DamageBy;
                });

                local total = #debrisParts;
                local alive = 0;
                for a=1, #debrisParts do
                    if debrisParts[a].Transparency == 1 then continue end;
                    alive = alive +1;
                end
                Debugger:Warn(`Immunity update {alive}/{total}`);
                properties.Immunity = math.clamp(alive/total, 0.1, 1);
            end)


        else
            destructibleInstance.HealthComp.OnHealthChanged:Connect(function(curHealth, oldHealth, damageData)
                if curHealth > oldHealth then return end;
                local properties = destructibleInstance.Properties;

                healthComp:TakeDamage(DamageData.new{
                    Damage = 20;
                    DamageBy = damageData.DamageBy;
                });

                if properties.LastExplosionTick and tick()-properties.LastExplosionTick < 1.5 then return end;
                properties.LastExplosionTick = tick();

                local snd = modAudio.Play("VechicleExplosion", destructModel.PrimaryPart);
                snd.Volume = snd.Volume * 0.5;
                snd.PlaybackSpeed = math.random(100,115)/100;
            end)

            destructibleInstance.OnDestroy:Connect(function()
                shared.modPlayers.cameraShakeAndZoom(npcClass.NetworkOwners, 30, 0, 2, 2, true);

                if destructModel.Name == "TopCover" then
                    healthComp:TakeDamage(DamageData.new{
						Damage = 400;
						TargetPart = destructModel.PrimaryPart;
					});
					
					heliInstance.Altitude = 50;

                elseif destructModel.Name == "TailPart" then
                    healthComp:TakeDamage(DamageData.new{
						Damage = 300;
						TargetPart = destructModel.PrimaryPart;
					});

                elseif destructModel.Name == "FrontTip" then
                    healthComp:TakeDamage(DamageData.new{
						Damage = 300;
						TargetPart = destructModel.PrimaryPart;
					});

                elseif destructModel.Name == "LeftLauncher" or destructModel.Name == "RightLauncher" then

                    if destructModel.Name == "LeftLauncher" then
                        heliInstance.LeftLaunchers = nil;
                    else
                        heliInstance.RightLaunchers = nil;
                    end
                    destructModel:BreakJoints();

                    if properties.State == "RocketSpam" then
                        properties.State = "Molotov";
                        properties.StateChangedTick = tick();
                    end

                end
            end)

            if destructModel.Name == "LeftLauncher" then
                heliInstance.LeftLaunchers = {};
                for _, obj in pairs(destructModel:WaitForChild("LLauncherBase"):GetChildren()) do
                    if obj.Name == "LauncherPoint" then
                        table.insert(heliInstance.LeftLaunchers, obj);
                    end
                end

            elseif destructModel.Name == "RightLauncher" then
                heliInstance.RightLaunchers = {};
                for _, obj in pairs(destructModel:WaitForChild("RLauncherBase"):GetChildren()) do
                    if obj.Name == "LauncherPoint" then
                        table.insert(heliInstance.RightLaunchers, obj);
                    end
                end

            end

        end;
    end
    properties.HelicopterInstance = heliInstance;

end


--MARK: Spawned
function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    npcClass.Character:SetAttribute("EntityHudHealth", true);

    local heliInstance = properties.HelicopterInstance;
    local heliModel = heliInstance.Model;
    local heliRoot = heliInstance.PrimaryPart;

    local dropAttachments = {};

    local deployRopes = {};
    properties.DeployRopes = deployRopes;
    local deploySeats = {};
    properties.DeploySeats = deploySeats;

    for _, heliPart in pairs(heliModel:GetChildren()) do
        if not heliPart:IsA("BasePart") then continue end;

        if heliPart.Name == "RopePoint" then
            heliPart:SetNetworkOwner(nil);

        elseif heliPart.Name == "DeploySeatL" or heliPart.Name == "DeploySeatR" then
            table.insert(deploySeats, heliPart);

        end
    end

    for _, obj in pairs(heliRoot:GetChildren()) do
        if obj.Name == "DropOrigin" then
            table.insert(dropAttachments, obj);
            
        elseif obj.Name == "DropdownRope" or obj.Name == "RopePointJoint" then
            table.insert(deployRopes, obj);
            
        end
    end

    heliInstance.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
    heliInstance.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge);

    npcClass:Sit(heliModel:WaitForChild("PSeat1"));

    
    --========MARK: Gunmen Mechanics
    heliInstance.GunmenSeats = {heliModel:WaitForChild("Seat7"); heliModel:WaitForChild("Seat8");};

    local gunmenNpcClasses = {};
    properties.GunmenNpcClasses = gunmenNpcClasses;

    local raycastParams = RaycastParams.new();
    raycastParams.FilterType = Enum.RaycastFilterType.Include;
    raycastParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
    raycastParams.IgnoreWater = true;

    npcClass.OnThink:Connect(function()
        local playerRootParts = CollectionService:GetTagged("PlayerRootParts");

        for a=1, #dropAttachments do
            local dropAtt: Attachment = dropAttachments[a];
            local seatId = dropAtt:GetAttribute("Seat");
            local spotLight = dropAtt:FindFirstChild("SpotLight");
            local spotLightGlare = dropAtt:FindFirstChild("SpotLightGlare");

            local spotTargetTag = dropAtt:FindFirstChild("SpotTarget");
            if spotTargetTag == nil then
                spotTargetTag = Instance.new("ObjectValue");
                spotTargetTag.Name = "SpotTarget";
                spotTargetTag.Parent = dropAtt;
            end

            if spotLight then
                spotLight.Enabled = heliInstance.DoorsOpen;
            end
            if spotLightGlare then
                spotLightGlare.Enabled = heliInstance.DoorsOpen;
            end

            if not heliInstance.DoorsOpen then
                spotTargetTag.Value = nil;

            else
                local lookDir = dropAtt.WorldCFrame.LookVector;
                local lightRange = 120;

                local rayResult = workspace:Raycast(dropAtt.WorldPosition, lookDir*lightRange, raycastParams);
                local lightPoint = rayResult and rayResult.Position or dropAtt.WorldPosition + lookDir*lightRange;

                local closestPlayerClass = nil;
                local closestPlayerDist = math.huge;
                for b=1, #playerRootParts do
                    local playerRootPart = playerRootParts[b];
                    local dist = modVector.DistanceSqrd(playerRootPart.Position, lightPoint);
                    if dist < closestPlayerDist then
                        local playerChar = playerRootPart.Parent;
                        if playerChar == nil then continue end;

                        local player = game.Players:GetPlayerFromCharacter(playerChar);
                        if player == nil then continue end;

                        local playerClass: PlayerClass = shared.modPlayers.get(player);
                        if playerClass == nil or not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then continue end;

                        closestPlayerDist = dist;
                        closestPlayerClass = playerClass;
                    end
                end
                
                local closestDir = (closestPlayerClass:GetCFrame().Position - dropAtt.WorldPosition).Unit;
                local dot = lookDir:Dot(closestDir);

                if closestPlayerClass == nil or dot <= 0.3 or closestPlayerDist > 14000 then
                    spotTargetTag.Value = nil;

                else
                    targetHandlerComp:AddTarget(closestPlayerClass.Character);

                    spotTargetTag.Value = closestPlayerClass.RootPart;
                    
                    local gunmenNpcClass = seatId == "Seat7" and gunmenNpcClasses[1] or gunmenNpcClasses[2];
                    if gunmenNpcClass then
                        gunmenNpcClass.Properties.SpotlightTarget = spotTargetTag;
                    end
                end

            end
        end

        for a=1, #heliInstance.GunmenSeats do
            local seatPart: Seat = heliInstance.GunmenSeats[a];
            if seatPart.Occupant == nil then continue end;
            
            local seatWeld = seatPart:FindFirstChild("SeatWeld");
            if seatWeld == nil or seatWeld:GetAttribute("Debug") then continue end;

            local flip = a == 1 and 1 or -1;
            if heliInstance.DoorsOpen then
                seatWeld.C0 = CFrame.new(0, 2, 1) * CFrame.Angles(-(math.pi/2), 0, 0);
            else
                seatWeld.C0 = CFrame.new(0, 2, 1) * CFrame.Angles(-(math.pi/2), 0, (math.pi/2) * flip);
            end
        end

        if #gunmenNpcClasses <= 0 and properties.State == "Circle" and properties.GunmenSpawned then
            properties.DespawnGunmen();
            properties.State = "Molotov";
            properties.StateChangedTick = tick();
        end
    end)

    function properties.DespawnGunmen()
        for _, gunmenNpcClass: NpcClass in pairs(gunmenNpcClasses) do
            if gunmenNpcClass.HealthComp.IsDead then continue end;
            gunmenNpcClass:Kill();
        end
        table.clear(gunmenNpcClasses);

        properties.GunmenSpawned = false;
    end
    npcClass.Garbage:Tag(properties.DespawnGunmen);
    --========


    --========MARK: Heavy Bandits Mechanics
    local heavyBanditsNpcClasses = {};
    properties.HeavyBanditsNpcClasses = heavyBanditsNpcClasses;

    function properties.DespawnHeavyBandits()
        for _, heavyBanditNpcClass: NpcClass in pairs(heavyBanditsNpcClasses) do
            if heavyBanditNpcClass.HealthComp.IsDead then continue end;
            heavyBanditNpcClass:Kill();
        end
        table.clear(heavyBanditsNpcClasses);
    end
    npcClass.Garbage:Tag(properties.DespawnHeavyBandits);
    --========

    
    --========MARK: Molotov mechanics
    local molotovModel = Instance.new("Model");
    molotovModel.Name = `Molotovs`;
    molotovModel.Parent = npcClass.Character;
    properties.MolotovModel = molotovModel;
    npcClass.Garbage:Tag(molotovModel);

    function properties.DropMolotovs()
        for _, dropOriginAtt in pairs(dropAttachments) do
            local originCf = dropOriginAtt.WorldCFrame;
            local projectileInstance: ProjectileInstance = modProjectile.fire("molotov", {
                OriginCFrame = originCf;
            });
            projectileInstance.Part.Parent = properties.MolotovModel;

            modProjectile.serverSimulate(projectileInstance, {
                RayWhitelist = {workspace.Environment; workspace.Terrain};
                Velocity = originCf.LookVector * 20;
            });
        end

        shared.modPlayers.cameraShakeAndZoom(npcClass.NetworkOwners, 10, 0, 1, 2, true);
    end

    local molotovDistTrack = 0;
    npcClass.OnThink:Connect(function()
        if not properties.DropMolotovActive then
            molotovDistTrack = 0;
            return;
        end;

        local heliCf = heliModel:GetPivot();

        if properties.LastHeliPoint == nil then
            properties.LastHeliPoint = heliCf.Position;
        end
        local lastHeliPoint = properties.LastHeliPoint;

        local heliMovedDist = (heliCf.Position - lastHeliPoint).Magnitude;
        properties.LastHeliPoint = heliCf.Position;

        if molotovDistTrack < 20 then
            molotovDistTrack = molotovDistTrack + heliMovedDist;
            return;
        end

        molotovDistTrack = 0;
        properties.DropMolotovs();
    end)
    --========


    --========MARK: Altitude Calculations
    npcClass.OnThink:Connect(function()
        local avgPosition = nil;
        local avgAltitude = nil;

        targetHandlerComp:MatchTargets(function(targetData: NpcTargetData)
            local characterClass = targetData.HealthComp.CompOwner;
            if characterClass == nil or characterClass.ClassName ~= "PlayerClass" then return end;

            local cf = characterClass:GetCFrame();
            if avgAltitude == nil then
                avgAltitude = cf.Position.Y;
            else
                avgAltitude = (avgAltitude + cf.Position.Y)/2;
            end

            if avgPosition == nil then
                avgPosition = cf.Position;
            else
                avgPosition = (avgPosition + cf.Position)/2;
            end
        end)
        
        if avgPosition then
            local dist = (avgPosition - heliInstance.CirclingPoint).Magnitude;
            if dist > 60 and properties.State == "Circle" then
                heliInstance.CirclingPoint = avgPosition;
                heliInstance.MoveState = "TransitionToCircle";
                Debugger:Warn("New circling point", avgPosition, "dist", dist);
            end
        end
        heliInstance.Altitude = avgAltitude and (avgAltitude+60) or 60;
    end)
    --========

    npcClass.OnThink:Connect(function()
        Debugger:Warn(properties.HardMode == true and "H" or "", 
            "State", properties.State, 
            "MoveState", heliInstance.MoveState,
            "DeployState", properties.DeployState,
            "MolotovState", properties.MolotovState
        );
    end)

    --MARK: Death Effects
    npcClass.Garbage:Tag(function()
        table.clear(properties.DeployRopes);
        table.clear(properties.DeploySeats);

        local heliRootPos = heliRoot.Position;
        Debugger.Expire(heliRoot);

        local explosion = Instance.new("Explosion");
        explosion.BlastRadius = 16;
        explosion.DestroyJointRadiusPercent = 0;
        explosion.BlastPressure = 0;
        explosion.Position = heliRootPos;
        explosion.Parent = workspace;
        Debugger.Expire(explosion, 1);

        modAudio.Play("VechicleExplosion", heliRootPos);
        modAudio.Play("Explosion4", heliRootPos);

        local heliParts = heliModel:GetDescendants();
        for _, obj in pairs(heliParts) do
            if not obj:IsA("BasePart") or obj.Transparency == 1 then continue end;
            obj.CollisionGroup = "Debris";
            obj.Anchored = false;
            obj.CanCollide = true;
            obj.Velocity = modVector.CleanUnitVec(obj.Position, heliRootPos) * 100;
            obj:BreakJoints();

            if math.random(1, 5) == 1 then
                local smoke = Instance.new("Smoke");
                smoke.Color = Color3.fromRGB(0, 0, 0);
                smoke.Size = math.random(2, 5);
                smoke.RiseVelocity = math.random(12, 20);
                smoke.Opacity = 1;
                smoke.Parent = obj;
                Debugger.Expire(smoke, math.random(4, 7));
            end
        end
            
        Debugger.Expire(heliModel, 10);
    end);

    for _, obj in pairs(npcClass.Character:GetDescendants()) do
        if not obj:IsA("BasePart") then continue end;
        obj.CollisionGroup = "CollisionOff";
    end

    task.spawn(function()
        while not npcClass.HealthComp.IsDead do
            if heliRoot:CanSetNetworkOwnership() then
                heliRoot:SetNetworkOwner(nil);
            end
            
            heliInstance.State = properties.State;
            heliInstance:Step();

            task.wait();
        end
    end)
    
end

return npcPackage;