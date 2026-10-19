local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local destructiblePackage = {
    Name = "Helicopter";
    DebrisName = "Helicopter";
    DisableDestroy = true;
};
--==

function destructiblePackage.BindNew(destructible: DestructibleInstance)
    local properties = destructible.Properties;
    local healthComp: HealthComp = destructible.HealthComp;

    healthComp:SetMaxHealth(1000);
    healthComp:Reset();

    healthComp.OnIsDeadChanged:Connect(function(isDead)
        if not isDead then return end;
        
        if properties.HpPanic then return end;
        properties.HpPanic = true;

        local model = destructible.Model;
        local primaryPart = model.PrimaryPart;
        local myPos = primaryPart.Position;

        local distractionPositionAtt = primaryPart:FindFirstChild("DistractionPositionAtt")
        if distractionPositionAtt then
            myPos = distractionPositionAtt.WorldPosition;
        end

        local fire = Instance.new("Fire");
        fire.Heat = 5;
        fire.Size = 5;
        fire.Parent = primaryPart;
        
        local snd = modAudio.Play("WarnAlarmLoop", primaryPart);
        Debugger.Expire(snd, 5);
        Debugger.Expire(fire, 5);

        local nearbyNpcClasses, nearbyDistances = shared.modNpcs.Octree:KNearestNeighborsSearch(myPos, 3, 65);

        for a=1, #nearbyNpcClasses do
            local npcClass: NpcClass = nearbyNpcClasses[a];
            if npcClass.HealthComp.IsDead then continue end;
            if npcClass.Properties.CanDistract ~= true then continue end;

            local targPos = npcClass:GetCFrame().Position;
            local heightDiff = math.abs(myPos.Y - targPos.Y);
            if heightDiff > 5 then continue end;

            npcClass.Properties.Distraction = {
                Tick = tick();
                Position = myPos;
            };
        end
    end)

end

function destructiblePackage.BindDestroy(destructible: DestructibleInstance, damageData, players)
    local burntTexture = game.ReplicatedStorage.Prefabs.Textures:WaitForChild("Burnt");

    local model = destructible.Model;

    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            if child.Transparency ~= 1 then
                for a=1, 6 do
                    if math.random(1, 2) ~= 1 then continue end;
                    local newBurntTexture: Texture = burntTexture:Clone();
                    newBurntTexture.Face = Enum.NormalId:FromValue(math.random(0, 5)) :: Enum.NormalId;
                    newBurntTexture.Parent = child;
                end
            end
        end
    end

end

return destructiblePackage;