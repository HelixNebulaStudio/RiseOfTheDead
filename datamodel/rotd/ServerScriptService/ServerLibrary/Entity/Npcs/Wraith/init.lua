local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local npcPackage = {
    Name = "Wraith";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 10;
        AttackRange = 6;
        AttackSpeed = 2;

        MaxHealth = 100;
        WalkSpeed = 18;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;
        Detectable = false;
		WeakPointHidden = true;

        TargetableDistance = 50;
        LockOnExpireDuration = NumberRange.new(10, 20);

        Level = 1;
        ExperiencePool = 20;
        DropRewardId = "zombie";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };
};
--==

function npcPackage.onRequire()
    WRAITH_EYES = script:WaitForChild("WraithEyes");

    task.spawn(function()
        local loopActive = false;
        
        CollectionService:GetInstanceAddedSignal("WraithBlackoutLights"):Connect(function(lightPart)
            if lightPart:GetAttribute("WraithBlackoutTick") == nil then
                lightPart.Material = Enum.Material.Plastic;

                for _, obj in pairs(lightPart:GetDescendants()) do
                    if obj:IsA("Light") and obj:GetAttribute("DefaultEnabled") == true then
                        obj.Enabled = false;
                    end
                end
            end;

            lightPart:SetAttribute("WraithBlackoutTick", tick());
        end)
        
        while true do
            task.wait(1);
            
            local offLights = CollectionService:GetTagged("WraithBlackoutLights");
            if #offLights <= 0 then
                task.wait(20);
                continue;
            end

            for a=1, #offLights do
                local lightPart = offLights[a];

                if tick()-(lightPart:GetAttribute("WraithBlackoutTick") or 0) < 6 then
                    continue
                end
                
                lightPart.Material = Enum.Material.Neon;

                for _, obj in pairs(lightPart:GetDescendants()) do
                    if obj:IsA("Light") and obj:GetAttribute("DefaultEnabled") == true then
                        obj.Enabled = true;
                    end
                end
                
                task.delay(0.5, function()
                    lightPart:SetAttribute("WraithBlackoutTick", nil);
                    lightPart:RemoveTag("WraithBlackoutLights");
                    
                end)
            end
        end
    end)
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    
    local rootPart = npcClass.RootPart;
    local character = npcClass.Character;

    local level = math.max(properties.Level, 0);

    configurations.BaseValues.MaxHealth = 100 + math.max(20 + 100*level, 100);
    configurations.BaseValues.AttackDamage = 10 + 3*level;

    npcClass.Character:SetAttribute("Invisible", true);
            
    local wraithSmoke = game.ReplicatedStorage.Particles.WraithSmoke:Clone();
    wraithSmoke.Parent = rootPart;
    
    for _, obj in pairs(character:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
            obj.Transparency = 1;
            
        elseif obj:IsA("Shirt") then
            game.Debris:AddItem(obj, 0);

        elseif obj:IsA("Pants") then
            game.Debris:AddItem(obj, 0);
            
        end
    end
    
    local eyesPrefab = WRAITH_EYES:Clone();
    eyesPrefab.Parent = character;
    
    local faceDecal = character:FindFirstChild("face", true);
    if faceDecal then
        faceDecal.Transparency = 1;
    end

    local lastPosition = rootPart.Position;
    npcClass.OnThink:Connect(function()
        if (rootPart.Position - lastPosition).Magnitude < 4 then return end;

        lastPosition = rootPart.Position;
        
        local overlapParam = OverlapParams.new();
        overlapParam.FilterType = Enum.RaycastFilterType.Include;
        overlapParam.FilterDescendantsInstances = CollectionService:GetTagged("LightSourcePart");

        local hitParts = workspace:GetPartBoundsInRadius(lastPosition, 64, overlapParam);
        local hitList = {};
        
        for a=1, #hitParts do
            local lightPart = hitParts[a];
            
            if lightPart:IsA("BasePart") and lightPart.Material == Enum.Material.Neon then
                lightPart:AddTag("WraithBlackoutLights");
            end
        end
    end)
end


return npcPackage;