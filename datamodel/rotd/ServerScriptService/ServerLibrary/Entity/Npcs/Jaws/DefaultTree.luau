local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local treePackage = {
    LogicString = {
        StrikeTree = "HasEnemy & CanStrike & [Strike]";
        Default = "StrikeTree | Idle";
    };
};

local defaultC0 = CFrame.new(0, 0, 0);
local HEAD_TWEENINFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In);
--==

--MARK: StrikeTree
function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.CanStrike(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if tick() > properties.LastStrikeCooldown then
        return true;
    end
    return false;
end

local diameter = 22;
local function flashCylinder(cframe)
    local newCylinder = modAoeHighlight.newCylinder(1);
    newCylinder.CFrame = cframe
    newCylinder.Size = Vector3.new(2, 2, 1);
    newCylinder.Parent = workspace.Entities;

    TweenService:Create(newCylinder, TweenInfo.new(0.45), {Size = Vector3.new(diameter, diameter, 1)}):Play();
    task.wait(0.45);
    TweenService:Create(newCylinder, TweenInfo.new(0.45), {Size = Vector3.new(2, 2, 1)}):Play();
    task.wait(0.45);
end
function treePackage.Strike(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local configurations = npcClass.Configurations;
    local character = npcClass.Character;
    local head = npcClass.Head;
    local rootPart = npcClass.RootPart;

    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    local enemyCharClass: CharacterClass = enemyTargetData.HealthComp.CompOwner;
    local targetRootPart = enemyCharClass.RootPart;

    local jawModels = properties.JawModels;
    local jawMotors = properties.JawMotors;

    if not properties.IsJawOpen then
        local isPlayerCaught = enemyTargetData.Distance <= configurations.AttackRange;
        
        for a=1, #jawMotors do
            local motor = jawMotors[a];

            TweenService:Create(motor, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                C0=(motor.Name == "RJawMotor" 
                    and defaultC0 * CFrame.Angles(0, 0, math.rad(90))
                    or defaultC0 * CFrame.Angles(0, 0, math.rad(-90)));
            }):Play();
        end
        properties.IsJawOpen = true;

        task.wait(1);
        if isPlayerCaught then
            modAudio.Play("Burp", rootPart).PlaybackSpeed = math.random(8, 10)/10;
            
        end
    end

    if npcClass.Head.Parent == npcClass.Character then
        TweenService:Create(npcClass.Head, HEAD_TWEENINFO, {CFrame=npcClass.Head.CFrame * CFrame.new(0, -5, 0)}):Play();
    end
    
    head.Parent = nil;
    for a=1, #jawModels do
        jawModels[a].Parent = nil;
    end
    
    modAudio.Play("RisingRumble", rootPart);
    if enemyCharClass.ClassName == "PlayerClass" then
        local targetPlayer: Player = (enemyCharClass :: PlayerClass):GetInstance();
        shared.modPlayers.cameraShakeAndZoom(targetPlayer, 2, 2, 5, 0.01);
    end
    task.wait(0.5);
    
    local groundCframe;
    for a=1, 3 do
        groundCframe = modAoeHighlight:Ray(targetRootPart.Position + Vector3.yAxis*4, Vector3.new(0, -16, 0));
    
        if groundCframe then
            flashCylinder(groundCframe);
        end
        if npcClass.HealthComp.IsDead then
            break;
        end
    end
    
    groundCframe = modAoeHighlight:Ray(targetRootPart.Position + Vector3.yAxis*4, Vector3.new(0, -16, 0));
    if groundCframe == nil then return end;
    
    
    local baseCf = CFrame.new(groundCframe.Position) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);
    
    local newCylinder = modAoeHighlight.newCylinder(2.3);
    newCylinder.CFrame = groundCframe
    newCylinder.Size = Vector3.new(2, 2, 1);
    newCylinder.Parent = workspace.Entities;
    
    TweenService:Create(newCylinder, TweenInfo.new(0.4), {Size = Vector3.new(diameter, diameter, 1)}):Play();
    task.wait(0.5);
    
    character:PivotTo(baseCf);
    head.CFrame = baseCf * CFrame.new(0, -6, 0);
    
    head.Parent = character;
    for a=1, #jawModels do
        jawModels[a].Parent = character;
    end
    
    modAudio.Play("JawsChomp", rootPart).PlaybackSpeed = math.random(85, 95)/100;
    if enemyCharClass.ClassName == "PlayerClass" then
        local targetPlayer: Player = (enemyCharClass :: PlayerClass):GetInstance();
        shared.modPlayers.cameraShakeAndZoom(targetPlayer, 10, 5, 1, 0.01);
    end
    task.wait(0.1);

    TweenService:Create(head, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {CFrame=baseCf * CFrame.new(0, 1, 0)}):Play();
    task.wait(0.15);
    
    for a=1, #jawMotors do
        local motor = jawMotors[a];
        
        motor.C0 = (motor.Name == "RJawMotor"
            and defaultC0 * CFrame.Angles(0, 0, math.rad(90))
            or defaultC0 * CFrame.Angles(0, 0, math.rad(-90)));
        
        TweenService:Create(motor, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            C0=defaultC0;
        }):Play();
    end
    
    task.delay(0.2, function()
        head.CFrame = baseCf * CFrame.Angles(0, math.rad(0.05), 0);
    end)

    properties.IsJawOpen = false;
    local distanceFromJaws = enemyTargetData.Distance;

    if distanceFromJaws < configurations.AttackRange then
        local dmgRange = math.pow((1-math.clamp(distanceFromJaws/configurations.AttackRange, 0, 1)), 1/2);
        local dmgData: DamageData = DamageData.new{
            Damage = dmgRange * 70;
            DamageBy = npcClass;
        };
        enemyCharClass.HealthComp:TakeDamage(dmgData);
        
    else
        task.wait(0.35);
        for a=1, #jawMotors do
            local motor = jawMotors[a];

            TweenService:Create(motor, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                C0=(motor.Name == "RJawMotor" 
                    and defaultC0 * CFrame.Angles(0, 0, math.rad(45))
                    or defaultC0 * CFrame.Angles(0, 0, math.rad(-45)));
            }):Play();
        end

        task.wait(5);
    end
    task.wait(1);
end

function treePackage.Idle(npcClass: NpcClass)
end

return treePackage;