local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Configurations = require(ReplicatedStorage.Library.Configurations)

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local treePackage = {
    LogicString = {
        ThrowTree = "HasEnemy & CanThrow & [Throw]";
        LeapTree = "HasEnemy & CanLeap & [Leap]";
        SpitFireTree = "HasEnemy & CanSpitFire & [SpitFire]";
        SleepTree = "ShouldSleep & [Sleep]";
        Default = "SleepTree | LeapTree | ThrowTree | SpitFireTree | ZombieBossDefaultTree";
    };
};

--==
function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end



function treePackage.CanThrow(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    if enemyTargetData.Distance > 25 then return false; end;
    if properties.ThrowPlayerCooldown and tick()-properties.ThrowPlayerCooldown <= 6 then return false; end;
    
    return true
end

function treePackage.Throw(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    modAudio.Play("ZombieAttack"..math.random(1, 3), npcClass.RootPart).Volume = 2;
    npcClass.Move:SetMoveSpeed("set", "throwstop", 0, 99, 2);

    if properties.ThrowPlayerCooldown == nil or tick()-properties.ThrowPlayerCooldown > 6 then
        properties.ThrowPlayerCooldown = tick();
        npcClass.PlayAnimation("ThrowPlayer", 0.05);

        local frostStatus = npcClass.StatusComp:GetOrDefault("FrostMod");
        local throwTargetComp = npcClass:GetComponent("ThrowTarget");

        local configMaxDamage = npcClass.Configurations.MaxDamage;
        throwTargetComp(enemyTargetData.HealthComp.CompOwner, 100, frostStatus and configMaxDamage*0.5 or configMaxDamage);
    end
end



function treePackage.CanLeap(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local rightLegDestructible: DestructibleInstance = bodyDestructiblesComp:Get("RightLeg");
    local leftLegDestructible: DestructibleInstance = bodyDestructiblesComp:Get("LeftLeg");

    if leftLegDestructible.HealthComp.IsDead and rightLegDestructible.HealthComp.IsDead then
        npcClass.Move:SetMoveSpeed("set", "default", 20);
        return false;
    end

    if properties.LeapCooldown and tick()-properties.LeapCooldown <= 4 then return false; end;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    if enemyTargetData.Distance <= 50 or npcClass.Move.IsMoving == false then return false; end;

    return true;
end

function treePackage.Leap(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    local enemyRootPart = enemyTargetData.Model.PrimaryPart;

    properties.LeapCooldown = tick();
    npcClass.Move:SetMoveSpeed("set", "leapstop", 0, 99, 0.8);
    npcClass.PlayAnimation("Leap", 0.3);

    task.delay(0.3, function()
        modAudio.Play(`ZombieAttack{math.random(1,3)}`, npcClass.RootPart).PlaybackSpeed = math.random(110, 140)/100;
        
        local frostStatus = npcClass.StatusComp:GetOrDefault("FrostMod");
        local leapPower = frostStatus and 170 or 200;

        local tarPos = enemyRootPart.CFrame.Position;
        npcClass.RootPart.AssemblyLinearVelocity = Vector3.new();
        npcClass.Move:Face(tarPos);
        task.wait();

        local leapDir = (tarPos-npcClass.RootPart.Position).Unit
        npcClass.RootPart.AssemblyLinearVelocity = leapDir * Vector3.new(leapPower, 0, leapPower);
        npcClass.Humanoid.Jump = true;

        task.wait(0.5);
        npcClass.StopAnimation("Leap", 0.4);
    end)
end



function treePackage.CanSpitFire(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local isHard = properties.HardMode;

    if isHard == false then return false; end;
    if properties.SpitFireCooldown and tick()-properties.SpitFireCooldown <= 10 then return false; end;

    return true;
end

function treePackage.SpitFire(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    properties.SpitFireCooldown = tick();

    local rpOffset = {
        Vector3.new(-3, 0, 0);
        Vector3.new(3, 0, 0);
        Vector3.new(0, 0, 3);
        Vector3.new(0, 0, -3);
    };
    local projTravelTime = 0.5;

	npcClass.Move:SetMoveSpeed("set", "spitfirestop", 0, 99, 5);
    
    npcClass.PlayAnimation("SplitFire");
    modAudio.Play("ZriceraFireBreath", npcClass.RootPart);

    local zriceraHelmet = npcClass.Character:FindFirstChild("Helmet");
    local fireLaunchPoint = zriceraHelmet:FindFirstChild("FireLaunchPoint");

    local targetDataList = npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetData)
        if targetData.HealthComp == nil or targetData.HealthComp.IsDead then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;
    
        local isTargettable = targetCharacterClass.HealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return false end;

        return true;
    end);

    if #targetDataList <= 0 then return end;
    wait(0.2);
    if npcClass.HealthComp.IsDead then return end;

    for a=1, 14 do
        local randomTarget = targetDataList[math.random(1, #targetDataList)];
        local targetModel = randomTarget.Model;
        local targetRootPart = targetModel.PrimaryPart;

        local targetPoint = targetRootPart.Position;
        local originCf = CFrame.lookAt(fireLaunchPoint.WorldPosition, targetPoint);
        
        npcClass.Move:Face(targetPoint);

        local rayWhitelist = {workspace.Environment; workspace.Terrain;};

        local playerCharacters = CollectionService:GetTagged("PlayerCharacters");
        for _, playerCharacter in pairs(playerCharacters) do
            table.insert(rayWhitelist, playerCharacter);
        end
        
        local configMaxDamage = npcClass.Configurations.MaxDamage;
        for b=1, 4 do
            local projectileInstance: ProjectileInstance = modProjectile.fire("liquidflame", {
                OriginCFrame = originCf;
            });
            projectileInstance.Properties.Damage = math.max(configMaxDamage/45, 1);
            projectileInstance.ArcTracer.Acceleration = Vector3.new(0, -100, 0);

            local velocity = projectileInstance.ArcTracer:GetVelocityByTime(
                originCf.Position, 
                targetPoint + rpOffset[b], 
                projTravelTime + math.random(-40, 40)/100
            );
            modProjectile.serverSimulate(projectileInstance, {
                RayWhitelist = rayWhitelist;
                Velocity = velocity;
            });
        end

        task.wait(0.3);
        if npcClass.HealthComp.IsDead then return end;
    end
    
end



function treePackage.ShouldSleep(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local isHard = properties.HardMode;

    if properties.SleepHealPool > 0 then return true end;
    if isHard == false then return false; end;

    if properties.SleepHealCooldown and tick()-properties.SleepHealCooldown <= 20 then return false; end;
    if npcClass.HealthComp.CurHealth <= npcClass.HealthComp.MaxHealth*0.045 then return false; end;
    if properties.SleepHealCount >= 5 then return false; end;

    return true;
end

function treePackage.Sleep(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local maxHp = npcClass.HealthComp.MaxHealth;
    local curHp = npcClass.HealthComp.CurHealth;

    if properties.SleepHealPool <= 0 then
        local healPool = ((maxHp/properties.SleepHealCount)-(maxHp*0.045));

        properties.SleepHealPool = healPool;

        properties.SleepHealCooldown = tick();
        
        npcClass.Move:SetMoveSpeed("set", "sleepstop", 0, 99, 5);
        npcClass.PlayAnimation("Sleep");

        properties.SleepHealCount = properties.SleepHealCount +1;

    else
        if properties.SleepHealTick == nil then
            properties.SleepHealTick = tick();
        end
        if tick()-properties.SleepHealTick >= 0.5 then
            properties.SleepHealTick = tick();

            local healAmt = (maxHp-curHp)*0.1;
            properties.SleepHealPool = properties.SleepHealPool -math.max(healAmt, 1);

            npcClass.HealthComp:TakeDamage(DamageData.new{
                Damage = -healAmt;
                DamageType = "Heal";
                TargetPart = npcClass.RootPart;
            });

            if properties.SleepHealPool <= 0 then
                npcClass.StopAnimation("Sleep");
            end
        end

    end
end

return treePackage;