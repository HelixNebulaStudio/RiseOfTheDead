local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local PathfindingService = game:GetService("PathfindingService");

local treePackage = {
    LogicString = {
        Default = "PreLogic | SinisterTree | ZombieDefaultTree";
        SinisterTree = "HasZombies & [ProtectZombies] | HasLinkedZombies & [FollowLinkedZombies]";
    };
};

--==
function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.HasZombies(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local configurations = npcClass.Configurations;

    if properties.SinisterScanTick and properties.SinisterScanTick > tick() then return false; end;
    properties.SinisterScanTick = tick() + configurations.SinisterScanCooldown;

    local maxRange = configurations.SinisterScanRange;
    local myPosition = npcClass.RootPart.Position;
    local zombieClasses: {NpcClass} = shared.modNpcs.listInRange(myPosition, maxRange, 16);

    if properties.LinkedUnits == nil then
        properties.LinkedUnits = {};
        npcClass.Garbage:Tag(properties.LinkedUnits);
    end

    local sortedNpcClasses = {};
    for a=1, #zombieClasses do
        local zNpcClass: NpcClass = zombieClasses[a];

        local validNpcClass = (zNpcClass ~= nil
            and zNpcClass ~= npcClass
            and not zNpcClass.HealthComp.IsDead
            and zNpcClass.HumanoidType == "Zombie"
            and zNpcClass.Properties.SinisterImmunity ~= true
            and zNpcClass.Properties.BasicEnemy == true
            and zNpcClass.Name ~= "Ticks");
        
        if not validNpcClass then continue end;
        local zCharacter = zNpcClass.Character;
        local zPosition = zCharacter:GetPivot().Position;
        
        if table.find(properties.LinkedUnits, zCharacter) == nil then
            table.insert(sortedNpcClasses, {
                NpcClass = zNpcClass;
                Distance = npcClass:DistanceFromCharacter(zPosition);
            });
        end
    end

    table.sort(sortedNpcClasses, function(a, b) return a.Distance < b.Distance; end);

    properties.SortedNpcClasses = sortedNpcClasses;

    return #sortedNpcClasses > 0;
end

function treePackage.ProtectZombies(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local configurations = npcClass.Configurations;

    local sortedNpcClasses = properties.SortedNpcClasses;
    if sortedNpcClasses == nil or #sortedNpcClasses <= 0 then return false; end;

    local maxRange = configurations.SinisterScanRange;

    local templateLinks = game.ReplicatedStorage.Prefabs.NpcAbilities:WaitForChild("DrSinisterVeins");
	local veinOptions = templateLinks:GetChildren();

    for a=1, #sortedNpcClasses do
        local zNpcClass: NpcClass = sortedNpcClasses[a].NpcClass;
        local zCharacter = zNpcClass.Character;
        
        if table.find(properties.LinkedUnits, zCharacter) then
            continue;
        end
        table.insert(properties.LinkedUnits, zCharacter);
        
        local waypointSpacing = 8;
        local linkingPath = PathfindingService:CreatePath({
            WaypointSpacing=waypointSpacing;
        });
        
        local linkActive = true;
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
        
        task.spawn(function()
            
            while linkActive do
                if npcClass.HealthComp.IsDead then return; end;
                
                local myPosition = npcClass.RootPart.Position;
                local prefabPosition = zCharacter:GetPivot().Position;
                local distance = (myPosition - prefabPosition).Magnitude;
                
                if distance <= maxRange then
                    linkingPath:ComputeAsync(myPosition, prefabPosition);
                end
                
                if distance <= maxRange and linkingPath.Status == Enum.PathStatus.Success then
                    local waypoints = linkingPath:GetWaypoints();
                    
                    -- link effect;
                    for a, waypoint in pairs(waypoints) do
                        if a == 1 then continue end;
                        
                        local part = veinOptions[math.random(1, #veinOptions)]:Clone();
                        Debugger.Expire(part, 1.2);
                        
                        local prevPos = waypoints[a-1].Position;
                        local pos = waypoint.Position;
                        
                        local center = (prevPos+pos)/2;
                        
                        part.CFrame = CFrame.new(center) * CFrame.lookAt(pos, prevPos).Rotation * CFrame.new(0, -0.8, 0);
                        part.Size = Vector3.new(0.6, 0.2, (prevPos-pos).Magnitude);
                        part.Parent = npcClass.Character;
                        
                    end
                    --
                    
                    for _, obj in pairs(zCharacter:GetChildren()) do
                        if obj:IsA("BasePart") then
                            if obj:GetAttribute("DefaultColor") == nil then
                                obj:SetAttribute("DefaultColor", obj.Color);
                            end
                            obj.Color = Color3.fromRGB(135, 67, 67);
                        end
                    end
                    
                    zNpcClass.Properties.SinisterImmunity = tick();
                    zNpcClass.Properties.Immunity = zNpcClass.Name ~= "Dr. Sinister" and 1 or 0.5;

                    task.delay(2, function()
                        if zNpcClass.Properties.SinisterImmunity == nil then return end;
                        if tick()-zNpcClass.Properties.SinisterImmunity >= 1.5 then
                            for _, obj in pairs(zCharacter:GetChildren()) do
                                if obj:IsA("BasePart") then
                                    obj.Color = obj:GetAttribute("DefaultColor") or Color3.fromRGB(211, 190, 150);
                                end
                            end

                            zNpcClass.Properties.SinisterImmunity = nil;
                            zNpcClass.Properties.Immunity = nil;
                        end
                    end)
                    
                end
                task.wait(1);
            end
        end)

        npcClass.Garbage:Tag(zCharacter.Destroying:Connect(function()
            linkActive = false;
            
            if properties.LinkedUnits == nil then return end;
            for a=#properties.LinkedUnits, 1, -1 do
                if properties.LinkedUnits[a] == zCharacter then
                    table.remove(properties.LinkedUnits, a);
                    break;
                end
            end
        end));
    end

    return;
end

function treePackage.HasLinkedZombies(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.LinkedUnits and #properties.LinkedUnits > 0;
end

function treePackage.FollowLinkedZombies(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local randomLinkedUnit = properties.LinkedUnits[math.random(1, #properties.LinkedUnits)];

    npcClass.Move:SetMoveSpeed("set", "walk", 10, 1);
    npcClass.Move:Follow(randomLinkedUnit.PrimaryPart);

    return;
end

function treePackage.ZombieDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieDefaultTree", false);
end

return treePackage;