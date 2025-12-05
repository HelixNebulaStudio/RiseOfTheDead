local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local treePackage = {
    LogicString = {
        MorphTree = "HasEnemy & ShouldMorph & [Morph]";

        InMorphTree = "IsInMorph & (EquipWeapon & HasAlly & AlertTree | IdleTree)";
        AlertTree = "IsUsingMelee & MeleeTree | RangeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";
        IdleTree = "SelfHealTree | [RandomFollow]";
        SelfHealTree = "IsHurt & [SelfHeal]";

        TransformLargeTree = "ShouldTransformLarge & [TransformLarge]";
        InLargeTree = "IsLargePathoroth & ZombieDefaultTree";

        Default = "MorphTree | TransformLargeTree | InMorphTree | InLargeTree";
    };
};

local GOOP_TWEENINFO = TweenInfo.new(1.66);
local TRANSFORM_TWEENINFO = TweenInfo.new(5);
--==
function treePackage.onRequire()
    GOOP = script.Parent:WaitForChild("Goop");
    LARGE_ROOT_JOINT = script.Parent:WaitForChild("LargeRootJoint");
    LARGE_PATHOROTH = script.Parent:WaitForChild("LargePath");
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


function treePackage.Morph(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local character = npcClass.Character;
    local rootPart = npcClass.RootPart;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    properties.MorphTimer = tick();
    if enemyNpcClass.ClassName ~= "PlayerClass" then return; end;
    if properties.MorphTarget == enemyNpcClass.Character then return; end;

    local morphTarget = enemyNpcClass.Character;
    properties.MorphTarget = morphTarget;

    local horrorParticle = properties.HorrorParticle;
    horrorParticle.Enabled = true;

    npcClass.Move:Stop();
    npcClass.Move:SetMoveSpeed("set", "morphstop", 0, npcClass.Move.MoveSpeedPriority.Action, 6.5);
    task.wait(0.2);

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

    for _, obj in pairs(morphTarget:GetChildren()) do
        if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") then
            
            local clone = obj:Clone();
            for _, obj in pairs(clone:GetDescendants()) do
                if obj:IsA("JointInstance") then
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

    local face = morphTarget:FindFirstChild("face", true);
    if face then 
        table.insert(morphAccessories , face:Clone());
        properties.FaceDecal.Transparency = 1;
    end;

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
    properties.IsLargePathoroth = true;

    properties.FaceDecal.Transparency = 0;

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
    
    local accessoryHandles = {};
    local sBodyParts = {};
    for _, obj in pairs(character:GetChildren()) do
        if obj:IsA("BasePart") then
            if obj:GetAttribute("DefaultColor") then
                obj.Color = obj:GetAttribute("DefaultColor");
            end
            table.insert(sBodyParts, obj);
        end
    end

    TweenService:Create(scaling1, TRANSFORM_TWEENINFO, {Value = 2}):Play();
    TweenService:Create(scaling2, TRANSFORM_TWEENINFO, {Value = 2}):Play();
    TweenService:Create(scaling3, TRANSFORM_TWEENINFO, {Value = 2}):Play();

    local headMesh = npcClass.Head:FindFirstChild("Mesh");
    if headMesh then
        TweenService:Create(headMesh, TRANSFORM_TWEENINFO, {Scale = headMesh.Scale *2}):Play();
    end

    task.wait(4);

    properties.Immortal = nil;
    npcClass.AnimationController:Stop("Transform");
    
    local new = LARGE_PATHOROTH:Clone();
    local ltLarge = nil;
    local motor = {};
    local parts = {};
    
    for _, obj in pairs(new:GetDescendants()) do
        if obj:IsA("Motor") then
            table.insert(motor, obj);
            obj.Enabled = false;
            
        elseif obj:IsA("BasePart") then
            table.insert(parts, obj);
            
            if obj.Name == "LowerTorsoLargeL" then
                ltLarge = obj;
            end
        end
    end
    
    scaling1.Value = 1;
    scaling2.Value = 1;
    scaling3.Value = 1;

    humanoid.HipHeight = 1.35;
    humanoid.AutomaticScalingEnabled = false;
    
    for _, obj in pairs(parts) do
        obj.Parent = character;
    end
    
    local newJoint = LARGE_ROOT_JOINT:Clone();
    newJoint.Parent = rootPart;
    newJoint.Part0 = rootPart;
    newJoint.Part1 = ltLarge;
    
    for _, obj in pairs(parts) do
        obj.Parent = character;
    end
    for _, obj in pairs(motor) do
        obj.Enabled = true;
    end
    for _, obj in pairs(sBodyParts) do
        obj.Transparency = 1;
        
        if obj.Name == "Head" then
            if obj:FindFirstChild("face") then
                obj.face.Transparency = 1;
            end
        end
    end

    local morphAccessories = properties.MorphAccessories;
    for a=1, #morphAccessories do
        game.Debris:AddItem(morphAccessories[a], 0);
    end
    npcClass.SetAnimation("Core", {script.Parent:WaitForChild("Core")});
    npcClass.SetAnimation("Running", {script.Parent:WaitForChild("Running")});
    npcClass.PlayAnimation("Core");
    
    horrorParticle.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.75),
        NumberSequenceKeypoint.new(1, 1)
    };
    
    npcClass.Move:SetMoveSpeed("set", "default", 10, 0);
end

--MARK: InMorphTree
function treePackage.IsInMorph(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.MorphTarget ~= nil and properties.IsLargePathoroth == false;
end

function treePackage.HasAlly(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local allyTargetData: NpcTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil or targetData.HealthComp.IsDead then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetCharacterClass == npcClass then return false; end;
        if targetCharacterClass.ClassName == "PlayerClass" then return false; end;
        if targetCharacterClass.HumanoidType ~= "Zombie" then return false; end;
        if targetData.HealthComp.CurHealth >= targetData.HealthComp.MaxHealth then return false; end;

        return true;
    end)

    local oldAllyTargetData = properties.AllyTargetData;
    if oldAllyTargetData then
        if oldAllyTargetData ~= allyTargetData or oldAllyTargetData.HealthComp.IsDead then
            npcClass.WieldComp.Controls.Mouse1Down = false;
        end
    end
    properties.AllyTargetData = allyTargetData;
    return allyTargetData ~= nil;
end

function treePackage.EquipWeapon(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.IsHealing and tick()-properties.IsHealing <= 5 then return false; end;

    local wieldComp: WieldComp = npcClass.WieldComp;
    local equipmentClass: EquipmentClass? = wieldComp.EquipmentClass;
    if equipmentClass and (equipmentClass.Class == "Gun" or equipmentClass.Class == "Melee") then 
        return true;
    end;

    local targetHealthComp: HealthComp = modHealthComponent.getByModel(properties.MorphTarget);
    local targetPlayerClass: PlayerClass = targetHealthComp and targetHealthComp.CompOwner;
    local primaryWeaponItemId = targetPlayerClass and targetPlayerClass.WieldComp.ItemId or nil;
    if primaryWeaponItemId == nil then return false end;

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
    local allyTargetData = npcClass.Properties.AllyTargetData;
    return allyTargetData.Distance <= 10;
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local allyTargetData = npcClass.Properties.EnemyTargetData;
    local allyNpcClass: NpcClass = allyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, 2, 5);
    npcClass.Move:Follow(allyNpcClass.RootPart, 2);
end


function treePackage.SwingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    local allyTargetData = npcClass.Properties.EnemyTargetData;
    local allyNpcClass: NpcClass = allyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(allyNpcClass.RootPart, 2);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

function treePackage.CanFireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false end;
    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then return false end;

    return true;
end

function treePackage.RunToFireRange(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local allyTargetData = npcClass.Properties.EnemyTargetData;
    local allyNpcClass: NpcClass = allyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 14, 2, 5);
    npcClass.Move:Follow(allyNpcClass.RootPart, 16, 24);

    return true;
end

function treePackage.FireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    
    local allyTargetData = npcClass.Properties.EnemyTargetData;

    local allyHealthComp: HealthComp = allyTargetData.HealthComp;
    local allyNpcClass: NpcClass = allyHealthComp.CompOwner;

    npcClass.Move:Face(allyNpcClass.RootPart, nil, 0.5);
    npcClass.Move:HeadTrack(allyNpcClass.Head, 2);

    local shootDirection = (allyNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
    
    wieldComp:InvokeToolAction(
        "PrimaryFireRequest", 
        shootDirection, 
        allyNpcClass.Humanoid
    );
end

function treePackage.RunToCover(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local allyTargetData = npcClass.Properties.EnemyTargetData;
    local allyNpcClass: NpcClass = allyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, 2, 5);
    npcClass.Move:Follow(allyNpcClass.RootPart, 24, 32);

    return true;
end

function treePackage.ReloadGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return end;
    
    if wieldComp.EquipmentClass.Class == "Gun" 
    and wieldComp.EquipmentClass.Properties.MaxAmmo <= 0 then

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

return treePackage;