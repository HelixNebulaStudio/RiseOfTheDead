local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
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

    healthComp:SetMaxHealth(500000);
    healthComp:Reset();

    local function setHpFire()
        if properties.HpFire then return end;
        properties.HpFire = true;

        local model = destructible.Model;

        local fire = Instance.new("Fire");
        fire.Heat = 15;
        fire.Size = 10;
        fire.Parent = model.PrimaryPart;

        if properties.PanicAlarmSnd then
            properties.PanicAlarmSnd.PlaybackSpeed = 1;
        end
    end

    local function setHpPanic()
        if properties.HpPanic then return end;
        properties.HpPanic = true;

        local model = destructible.Model;

        local snd = modAudio.Play("PanicAlarm", model.PrimaryPart);
        snd.PlaybackSpeed = 0.8;
        properties.PanicAlarmSnd = snd;
    end

    local function setHpSmoke()
        if properties.HpSmoke then return end;
        properties.HpSmoke = true;

        local model = destructible.Model;
        
        local smoke = Instance.new("Smoke");
        smoke.Color = Color3.fromRGB(0, 0, 0);
        smoke.Size = 5;
        smoke.RiseVelocity = 10;
        smoke.Opacity = 1;
        smoke.Parent = model.PrimaryPart;
    end

    healthComp.OnIsDeadChanged:Connect(function(isDead)
        if not isDead then return end;

        setHpFire();
        setHpPanic();
        setHpSmoke();
    end)

    healthComp.OnHealthChanged:Connect(function(curHealth, maxHealth)
        local model = destructible.Model;
        local hpRatio = curHealth/maxHealth;

        if hpRatio <= 0.15 then
            setHpFire();

            task.spawn(function()
                if properties.HpBurnOut then return end;
                properties.HpBurnOut = true;

                while task.wait(1) do
                    if healthComp.IsDead then return end;
                    if not workspace:IsAncestorOf(model) then return end;

                    local dmg = healthComp.MaxHealth*0.01;
                    healthComp:TakeDamage(DamageData.new{
                        Damage = dmg;
                        DamageType = "IgnoreArmor";
                    });
                end
            end)

        elseif hpRatio <= 0.30 then
            setHpPanic();

        elseif hpRatio <= 0.45 then
            setHpSmoke();

        end
    end)

end

function destructiblePackage.BindDestroy(destructible: DestructibleInstance, damageData, players)
    Debugger:Warn("Helicopter destroy");

    local burntTexture = game.ReplicatedStorage.Prefabs.Textures:WaitForChild("Burnt");

    local model = destructible.Model;
    local targetPart = damageData.TargetPart or model:FindFirstChildWhichIsA("BasePart");
    local targetPos = targetPart.Position;
    
    modAudio.Play("VechicleExplosion", targetPos);
    modAudio.Play("Explosion4", targetPos);

    local ex = Instance.new("Explosion");
    ex.DestroyJointRadiusPercent = 0;
    ex.BlastRadius = 16;
    ex.BlastPressure = 0;
    ex.Position = targetPos;
    ex.Parent = workspace;
    Debugger.Expire(ex, 1);
    
    local hitLayers = modExplosionHandler:Cast(targetPos, {
        Radius = 16;
    });

    modExplosionHandler:Process(targetPos, hitLayers, {
        ExplosionStun = 2;

        DamageOrigin = targetPos;
        OnPartHit = modExplosionHandler.GenericOnPartHit;

        BindDamageDataNew = function(dmgData: DamageData)
            local damageTo: EntityClass = dmgData.DamageTo :: EntityClass;

            if damageTo.ClassName == "NpcClass" then
                local npcClass: NpcClass = damageTo :: NpcClass;
                local isBasicEnemy = npcClass.Properties.BasicEnemy == true;
                dmgData.Damage = npcClass.HealthComp.MaxHealth * (isBasicEnemy and math.random(40, 60)/100 or math.random(10, 20)/100);
                
                if npcClass.Properties.HasElectronics then
                    npcClass.StatusComp:Apply("StrongRoot", {
                        Expires = workspace:GetServerTimeNow() + 5;
                        Duration = 5;
                    });
                end

            elseif damageTo.ClassName == "Destructible" then
                local destructible: DestructibleInstance = damageTo :: DestructibleInstance;
                dmgData.Damage = math.floor(destructible.HealthComp.MaxHealth * 0.334);

            elseif damageTo.ClassName == "PlayerClass" then
                dmgData.Damage = 100;

            end
        end;
    });

    for _, child in pairs(model:GetDescendants()) do
        if child:IsA("Seat") then
            child:Destroy();

        elseif child:IsA("BasePart") then
            if child.Transparency == 1 then
                child:Destroy();

            else
                for a=1, 6 do
                    if math.random(1, 2) ~= 1 then continue end;
                    local newBurntTexture: Texture = burntTexture:Clone();
                    newBurntTexture.Face = Enum.NormalId:FromValue(math.random(0, 5)) :: Enum.NormalId;
                    newBurntTexture.Parent = child;
                end

            end

        elseif child:IsA("Motor6D") then
            if math.random(1, 3) == 1 then 
                child:Destroy();
            end

        end
    end
end

return destructiblePackage;