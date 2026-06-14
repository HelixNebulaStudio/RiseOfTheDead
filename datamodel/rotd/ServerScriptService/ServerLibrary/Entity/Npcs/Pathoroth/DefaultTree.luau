local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local treePackage = {
    LogicString = {
        MorphTree = "HasEnemy & ShouldMorph & [MimicMorph]";

        IsMimicTree = "IsMimic & (EquipWeapon & PickActiveTarget & AlertTree | IdleTree)";
        AlertTree = "IsUsingMelee & MeleeTree | RangeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";

        IdleTree = "SelfHealTree | [RandomFollow]";
        SelfHealTree = "IsHurt & & CanHeal [SelfHeal]";

        TransformLargeTree = "ShouldTransformLarge & [TransformLarge]";
        InLargeTree = "IsLargePathoroth & (ChargeTree | ZombieDefaultTree)";

        ChargeTree = "HasEnemy & CanCharge & [Charge]";

        Default = "MorphTree | TransformLargeTree | IsMimicTree | InLargeTree";
    };
};

local GOOP_TWEENINFO = TweenInfo.new(1.66);
local TRANSFORM_TWEENINFO = TweenInfo.new(5);
--==
function treePackage.onRequire()
    GOOP = script.Parent:WaitForChild("Goop");
end


function treePackage.HasEnemy(npcClass: NpcClass)
    npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

--MARK: MorphTree
function treePackage.ShouldMorph(npcClass: NpcClass)
    local properties = npcClass.Properties;
    
    if properties.IsLargePathoroth then return false; end;
    if tick() - properties.MorphTimer <= properties.MorphCooldown then return false; end;

    return true;
end


function treePackage.MimicMorph(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local character = npcClass.Character;
    local rootPart = npcClass.RootPart;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local targetEntityClass: EntityClass = enemyTargetData.HealthComp.CompOwner;

    properties.MorphTimer = tick();
    if targetEntityClass.ClassName ~= "PlayerClass" then return; end;
    if properties.MorphTarget == targetEntityClass.Character then return; end;

    local morphTarget = targetEntityClass.Character;
    properties.MorphTarget = morphTarget;

    local horrorParticle = properties.HorrorParticle;
    horrorParticle.Enabled = true;

    npcClass.Move:Stop();
    npcClass.Move:SetMoveSpeed("set", "morphstop", 0, npcClass.Move.MoveSpeedPriority.Action, 6.5);
    task.wait(0.2);
    if npcClass.HealthComp.IsDead then return end;

    local pos = rootPart.Position + Vector3.new(0, -2.2, 0);
    local new = GOOP:Clone();
    new:SetPrimaryPartCFrame(CFrame.new(pos));

    local goop1 = new:WaitForChild("goop1");
    local goop2 = new:WaitForChild("goop2");
    local goop3 = new:WaitForChild("goop3");
    local rootPos1 = goop1.Position;
    local rootPos2 = goop2.Position;
    local rootPos3 = goop3.Position;

    goop1.Position = goop1.Position + Vector3.new(0, -10, 0);
    goop2.Position = goop2.Position + Vector3.new(0, -10, 0);
    goop3.Position = goop3.Position + Vector3.new(0, -10, 0);

    new.Parent = character;

    TweenService:Create(goop1, GOOP_TWEENINFO, {Position = rootPos1}):Play();
    task.wait(1.66);
    TweenService:Create(goop2, GOOP_TWEENINFO, {Position = rootPos2}):Play();
    task.wait(1.66);
    TweenService:Create(goop3, GOOP_TWEENINFO, {Position = rootPos3}):Play();
    task.wait(1.66);
    if npcClass.HealthComp.IsDead then return end;

    for _, obj in pairs(character:GetChildren()) do
        if obj:IsA("BasePart") then
            obj.Color = Color3.fromRGB(211, 190, 150);
        end
    end
    
    local morphAccessories = properties.MorphAccessories;
    for a=1, #morphAccessories do
        game.Debris:AddItem(morphAccessories[a], 0);
    end
    table.clear(morphAccessories);
    task.wait(0.1);
    if npcClass.HealthComp.IsDead then return end;

    for _, obj in pairs(morphTarget:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") then
            
            local clone = obj:Clone();
            for _, obj in pairs(clone:GetDescendants()) do
                if obj:IsA("JointInstance") or obj:IsA("LuaSourceContainer") then
                    obj:Destroy();
                end
            end
            table.insert(morphAccessories, clone);
            
        elseif obj:IsA("BasePart") then
            local part = morphTarget:FindFirstChild(obj.Name);
            if part then
                part.Color =  obj.Color;
            end
            
        end
    end

    for _, obj in pairs(character:GetChildren()) do
        if not obj:IsA("BasePart") then continue end;
        local matchPart = morphTarget:FindFirstChild(obj.Name);
        if matchPart then
            if obj:GetAttribute("DefaultColor") then
                obj:SetAttribute("DefaultColor", obj.Color);
            end
            obj.Color = matchPart.Color;
        end
    end
    for a=1, #morphAccessories do
        if morphAccessories[a].Name == "face" then
            morphAccessories[a].Parent = npcClass.Head;
            
        else
            game.Debris:AddItem(character:FindFirstChild(morphAccessories[a].Name), 0);
            morphAccessories[a].Parent = character;
            
        end
    end
    
    task.wait(1);
    if npcClass.HealthComp.IsDead then return end;
    
    npcClass.Move:SetMoveSpeed("set", "default", 16, 0);
    
    goop1.Anchored = false;
    goop2.Anchored = false;
    goop3.Anchored = false;
    horrorParticle.Enabled = false;
    
    game.Debris:AddItem(new, 0.3);
end

--MARK: TransformLargeTree
function treePackage.ShouldTransformLarge(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local healthComp = npcClass.HealthComp;
    
    return healthComp.CurHealth <= healthComp.MaxHealth*0.5 and properties.IsLargePathoroth == false;
end


function treePackage.TransformLarge(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local character = npcClass.Character;
    local humanoid = npcClass.Humanoid;
    local rootPart = npcClass.RootPart;

    properties.Immortal = 1;
    task.delay(5, function()
        properties.Immunity = 0.5;
        properties.Immortal = nil;
    end)
    properties.IsLargePathoroth = true;

    npcClass.AnimationController:Stop("Running")
    npcClass.AnimationController:Play("Transform", {Speed=0.25;});
    
    local horrorParticle = properties.HorrorParticle;
    horrorParticle.Enabled = true;
    horrorParticle.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 10),
        NumberSequenceKeypoint.new(1, 10)
    };

    if npcClass.WieldComp.ItemId then
        npcClass.WieldComp:Unequip();
    end
    
    local scaling1 = Instance.new("NumberValue");
    scaling1.Name = "BodyDepthScale";
    scaling1.Value = 1;
    scaling1.Parent = npcClass.Humanoid;
    local scaling2 = Instance.new("NumberValue");
    scaling2.Name = "BodyHeightScale";
    scaling2.Value = 1;
    scaling2.Parent = npcClass.Humanoid;
    local scaling3 = Instance.new("NumberValue");
    scaling3.Name = "BodyWidthScale";
    scaling3.Value = 1;
    scaling3.Parent = npcClass.Humanoid;
    
    npcClass.Move:Stop();
    npcClass.Move:SetMoveSpeed("set", "transformstop", 0, npcClass.Move.MoveSpeedPriority.Action, 5);
    
    npcClass.Humanoid.AutomaticScalingEnabled = true;
    
    local sBodyParts = {};
    for _, obj in pairs(character:GetChildren()) do
        if obj:IsA("BasePart") then
            if obj:GetAttribute("DefaultColor") then
                obj.Color = obj:GetAttribute("DefaultColor");
            end
            table.insert(sBodyParts, obj);
        end
    end

    local scaleAccessories = {};
    local morphAccessories = properties.MorphAccessories;
    for a=1, #morphAccessories do
        if morphAccessories[a]:IsA("Accessory") and morphAccessories[a]:FindFirstChild("Handle") then
            table.insert(scaleAccessories, morphAccessories[a]);
        end
    end

    TweenService:Create(scaling1, TRANSFORM_TWEENINFO, {Value = 2}):Play();
    TweenService:Create(scaling2, TRANSFORM_TWEENINFO, {Value = 2}):Play();
    TweenService:Create(scaling3, TRANSFORM_TWEENINFO, {Value = 2}):Play();
    for a=1, #scaleAccessories do
        local accessory = scaleAccessories[a];
        local handle = accessory:FindFirstChild("Handle");
        local weld = handle and handle:FindFirstChild("AccessoryWeld");
        if weld and weld.Part1 == npcClass.Head then
            game.Debris:AddItem(accessory, 0);
            continue;
        end

        local accessoryScaler = Instance.new("NumberValue");
        accessoryScaler.Name = accessory.Name;
        accessoryScaler.Value = 1;
        accessoryScaler.Parent = npcClass.Humanoid;

        local defaultSize = handle.Size;
        accessoryScaler:GetPropertyChangedSignal("Value"):Connect(function()
            handle.Size = defaultSize * accessoryScaler.Value;
        end)

        TweenService:Create(accessoryScaler, TRANSFORM_TWEENINFO, {Value = 2}):Play();
    end

    local head = npcClass.Head;
    local headMesh = head:FindFirstChild("Mesh");
    if headMesh then
        local tween: Tween = TweenService:Create(headMesh, TRANSFORM_TWEENINFO, {Scale = headMesh.Scale *1.75});
        tween.Completed:Connect(function(playbackState)
            if playbackState ~= Enum.PlaybackState.Completed then return end;
            local newHead = script.Parent.Head:Clone();
            newHead.Parent = npcClass.Character;

            newHead.Color = head.Color;
            newHead.CFrame = head.CFrame;

            local motor = Instance.new("Motor6D");
            motor.Name = "Neck";
            motor.Parent = newHead;
            motor.Part0 = newHead;
            motor.Part1 = head;
            motor.C0 = CFrame.new(0, -0.1, 0.3);
            
            head.Transparency = 1;
            head.Size = Vector3.zero;

            if properties.FaceDecal then
                properties.FaceDecal:Destroy();
            end
        end)
        tween:Play();
    end

    task.wait(4);
    if npcClass.HealthComp.IsDead then return end;

    npcClass.AnimationController:Stop("Transform");

    horrorParticle.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(1, 1)
    };
    
    npcClass.Move:SetMoveSpeed("set", "default", 10, 0);
end

--MARK: IsMimicTree
function treePackage.IsMimic(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.MorphTarget ~= nil and properties.IsLargePathoroth == false;
end

function treePackage.PickActiveTarget(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    if properties.HordeAggression
    and enemyTargetData
    and enemyTargetData.HealthComp
    and enemyTargetData.HealthComp.CompOwner
    and enemyTargetData.HealthComp.CompOwner.ClassName == "PlayerClass" then
        properties.ActiveTargetData = enemyTargetData;
        
        return properties.ActiveTargetData ~= nil;
    end

    local allyTargetData: NpcTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil or targetData.HealthComp.IsDead then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetCharacterClass == npcClass then return false; end;
        if targetCharacterClass.ClassName == "PlayerClass" then return false; end;
        if targetCharacterClass.HumanoidType ~= "Zombie" then return false; end;
        if targetCharacterClass.Properties.BasicEnemy ~= true then return false; end;
        if targetData.HealthComp.CurHealth >= targetData.HealthComp.MaxHealth then return false; end;

        return true;
    end)

    local newActiveTargetData = allyTargetData;
    
    local recentlyDamaged = (workspace:GetServerTimeNow()-npcClass.HealthComp.LastDamageTaken) <= 5
    if enemyTargetData 
    and enemyTargetData.HealthComp.CompOwner.ClassName == "PlayerClass" 
    and (enemyTargetData.Distance <= 32 or recentlyDamaged) then
        newActiveTargetData = enemyTargetData;
    end
    
    local oldActiveTargetData = properties.ActiveTargetData;
    if oldActiveTargetData then
        if oldActiveTargetData ~= newActiveTargetData or oldActiveTargetData.HealthComp.IsDead then
            npcClass.WieldComp.Controls.Mouse1Down = false;
        end
    end
    properties.ActiveTargetData = newActiveTargetData;

    if properties.ActiveTargetData == nil then
        npcClass.Move:Follow();
    end

    return properties.ActiveTargetData ~= nil;
end

function treePackage.EquipWeapon(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.IsHealing and tick()-properties.IsHealing <= 5 then return false; end;

    local wieldComp: WieldComp = npcClass.WieldComp;
    local equipmentClass: EquipmentClass? = wieldComp.EquipmentClass;
    if equipmentClass and (equipmentClass.Class == "Gun" or equipmentClass.Class == "Melee") then 
        return true;
    end;

    local targetHealthComp: HealthComp? = modHealthComponent.getByModel(properties.MorphTarget);
    if targetHealthComp == nil then return false; end;
    
    local targetEntityClass: EntityClass = targetHealthComp.CompOwner;
    
    local targetPlayerClass: PlayerClass = (targetEntityClass :: PlayerClass);
    local primaryWeaponItemId = targetPlayerClass and targetPlayerClass.WieldComp.ItemId or "p250";

    wieldComp:Equip{
        ItemId = primaryWeaponItemId;
        OnSuccessFunc = npcClass.Binds.EquipSuccessFunc;
    };

    return true;
end

function treePackage.IsUsingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then return true end;
    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local targetData = npcClass.Properties.ActiveTargetData;
    return targetData.Distance <= (npcClass.Properties.IsLargePathoroth and 20 or 10);
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local targetData = properties.ActiveTargetData;
    local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, 2, 5);
    npcClass.Move:Follow(targetCharacterClass.RootPart, 2);
end


function treePackage.SwingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    local targetData = npcClass.Properties.ActiveTargetData;
    local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(targetCharacterClass.RootPart, 2);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

function treePackage.CanFireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false end;
    if (wieldComp.EquipmentClass.Properties.Ammo :: number) <= 0 then return false end;

    return true;
end

function treePackage.RunToFireRange(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetData = npcClass.Properties.ActiveTargetData;
    local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 14, 2, 5);
    npcClass.Move:Follow(targetCharacterClass.RootPart, 16, 24);

    return true;
end

function treePackage.FireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    
    local tagetData = npcClass.Properties.ActiveTargetData;

    local targetHealthComp: HealthComp = tagetData.HealthComp;
    local targetCharacterClass: CharacterClass = targetHealthComp.CompOwner :: NpcClass;

    npcClass.Move:Face(targetCharacterClass.RootPart, nil, 0.5);
    npcClass.Move:HeadTrack(targetCharacterClass.Head, 2);

    local shootDirection = (targetCharacterClass:GetCFrame().Position - npcClass:GetCFrame().Position).Unit;
    
    local equipmentClass: EquipmentClass? = wieldComp.EquipmentClass;
    if equipmentClass then
        local configurations: ConfigVariable = equipmentClass.Configurations;
        if equipmentClass.Class == "Gun" then
            local modifier: ItemModifierInstance? = configurations:GetModifier("PathorothGun") :: ItemModifierInstance;
            if modifier then
                local firerate = 60/configurations.Rpm;
                modifier.SetValues.Damage = 5 * firerate;
                modifier.SetValues.PreModDamage = 5 * firerate;
            end
        end
    end

    wieldComp:InvokeToolAction(
        "PrimaryFireRequest", 
        shootDirection, 
        targetCharacterClass.Humanoid
    );
end

function treePackage.RunToCover(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local tagetData = npcClass.Properties.ActiveTargetData;
    local targetCharacterClass: CharacterClass = tagetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, 2, 5);
    npcClass.Move:Follow(targetCharacterClass.RootPart, 24, 32);

    return true;
end

function treePackage.ReloadGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return end;
    
    if wieldComp.EquipmentClass.Class == "Gun" 
    and (wieldComp.EquipmentClass.Properties.MaxAmmo :: number) <= 0 then

        wieldComp:Equip{
            ItemId = "machete";
            OnSuccessFunc = npcClass.Binds.EquipSuccessFunc;
        };
        return;
    end

    wieldComp:InvokeToolAction("ReloadRequest");
end

function treePackage.IsHurt(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;
    
    local isHurt = healthComp.CurHealth < healthComp.MaxHealth;

    if not isHurt then
        properties.IsHealing = nil;
    end
    return isHurt;
end

function treePackage.CanHeal(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.HealCooldown and tick() < properties.HealCooldown then return false; end;

    return true;
end

function treePackage.SelfHeal(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.IsHealing = tick();

    npcClass.Move:Stop();

    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil or wieldComp.EquipmentClass.ItemId ~= "medkit" then
        wieldComp:Equip{
            ItemId = "medkit";
        };
        
    elseif wieldComp.EquipmentClass.ItemId == "medkit" then
        wieldComp:InvokeToolAction("UseRequest");
        properties.HealCooldown = tick() + math.random(10, 20);
    end
end

function treePackage.RandomFollow(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local rootPart = npcClass.RootPart;

    if npcClass.Move.IsMoving then return end;
    
    local pickAlly = nil;
    local entitiesFolder = workspace.Entity:GetChildren();
    if #entitiesFolder then
        local closestEntity = nil;
        local closestDist = math.huge;
        for a=1, 5 do
            local entityModel = table.remove(entitiesFolder, math.random(1, #entitiesFolder));
            local entityPos = entityModel:GetPivot().Position;
            local dist = (entityPos - npcClass.RootPart.Position).Magnitude;
            if dist < closestDist then
                closestEntity = entityModel;
                closestDist = dist;
            end
        end
        if closestDist <= 30 then
            pickAlly = closestEntity;
        end
    end

    local rngVec = (modVector.RandomUnitVector(3) * 20);
    local targetPos = pickAlly and pickAlly:GetPivot().Position or rootPart.Position + Vector3.new(rngVec.X, 0, rngVec.Z);

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, 2, 2);
    npcClass.Move:MoveTo(targetPos);
end

--MARK: InLargeTree
function treePackage.IsLargePathoroth(npcClass: NpcClass)
    return npcClass.Properties.IsLargePathoroth == true;
end

function treePackage.ZombieDefaultTree(npcClass: NpcClass)
    if npcClass.WieldComp.ItemId then
        npcClass.WieldComp:Unequip();
    end
    return npcClass.BehaviorTree:RunTree("ZombieDefaultTree", false);
end

--MARK: ChargeTree
function treePackage.CanCharge(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.ChargeCooldown and tick() <= properties.ChargeCooldown then return false; end;
    
    return true;
end

function treePackage.Charge(npcClass: NpcClass)
    local properties = npcClass.Properties;

    properties.ChargeCooldown = tick()+15;
    npcClass.Move:Stop();

    task.wait(0.1);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: CharacterClass = enemyTargetData.HealthComp.CompOwner :: CharacterClass;

    npcClass.Move:Face(enemyNpcClass.RootPart, nil, 2);
    npcClass.PlayAnimation("ChargeBegin", nil, nil, 2);
    task.wait(2);

    local targetPosition = enemyNpcClass.RootPart.Position + Vector3.new(0, 0.3, 0);
    local targetDir = (targetPosition-npcClass.RootPart.Position).Unit;
    targetPosition = targetPosition + targetDir * 6;

    local targetDistance = math.max(npcClass:DistanceFrom(targetPosition), 16);
    local speed = 200;
    local duration = math.clamp(targetDistance/speed, 0.01, 3);

    npcClass.PlayAnimation("Charging");

    local targetCharClasses = {};
    npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetCharNpc: EntityClass)
        local targetHealthComp: HealthComp = targetCharNpc.HealthComp;
        if targetHealthComp == nil or targetHealthComp.IsDead then return end;
        if targetCharNpc.ClassName == "Destructible" then return end;

        local isTargettable = targetHealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return end;

        table.insert(targetCharClasses, targetHealthComp.CompOwner :: CharacterClass);
    end)

    local hitNpcClassDebounce = {};

    npcClass.Move:MoveTo(targetPosition);
    npcClass.Move:Face(targetPosition);

    local throwTargetComp = npcClass:GetComponent("ThrowTarget");
    
    modAudio.Play("ChargeRoar", npcClass.RootPart);
    
    npcClass.Move:Fly({
        Velocity = targetDir * speed;
        Direction = targetDir;
    }, duration, function(index, trajPoint)
        task.spawn(function()
            while npcClass.Move.IsFlying do
                RunService.PostSimulation:Wait();
                for a=1, #targetCharClasses do
                    local targetCharClass: CharacterClass = targetCharClasses[a];
                    local targetRootPart = targetCharClass.RootPart;

                    local distance = npcClass:DistanceFrom(targetRootPart.Position);
                    local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(targetRootPart.CFrame);
                    local absAngle = math.abs(math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z)));

                    if absAngle <= 35 and distance <= 7 then
                        if hitNpcClassDebounce[targetCharClass] then continue end;
                        hitNpcClassDebounce[targetCharClass] = true;
                        throwTargetComp(targetCharClass, 100, 20);
                    end
                end
            end
        end)
    end)
    table.clear(hitNpcClassDebounce);

    task.wait(1);
    npcClass.StopAnimation("Charging");
end

return treePackage;