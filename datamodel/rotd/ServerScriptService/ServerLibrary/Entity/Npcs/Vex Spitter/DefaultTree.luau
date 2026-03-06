local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local treePackage = {
    LogicString = {
        Default = "HasEnemy & AggroTree | [Idle]";
        AggroTree = "UpdateTarget & CanShoot & [Shoot]";
    };
}

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetCharacterClass.ClassName ~= "PlayerClass" then return false; end
        
        local player: Player = (targetCharacterClass :: PlayerClass):GetInstance();

        if npcClass.NetworkOwners then
            local isNetOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
            if not isNetOwner then
                return false;
            end
        end

        local isAlive = targetCharacterClass.HealthComp.IsDead ~= true;
        if not isAlive then return false end;

        local isTargettable = targetCharacterClass.HealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return false end;

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

        return true;
    end);

    properties.EnemyTargetData = enemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.UpdateTarget(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData = properties.EnemyTargetData;
    if enemyTargetData then
        properties.TargetObj.Value = enemyTargetData:GetTargetPart();
    end

    return true;
end

function treePackage.CanShoot(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;
    if enemyTargetData == nil then return false end;

    if properties.ShotCooldown and tick() < properties.ShotCooldown then
        return false;
    end

    return true;
end

function treePackage.Shoot(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.ShotCooldown = tick() + math.random(2, 3);

    local targetPart = properties.TargetObj.Value;
    if targetPart == nil then return end;

    local originCf = npcClass.Head.CFrame;
    local targetPoint = targetPart.Position;

    local isInVision = npcClass:IsInVision(targetPart, 145);
    if not isInVision and math.random(1, 6) == 1 then 
        properties.ShotCooldown -= 1.5;
        return;
    end;

    local velocity = (targetPoint-originCf.Position).Unit * math.random(130, 150);

    local projectileInstance: ProjectileInstance = modProjectile.fire("eldervexspit", {
        OriginCFrame = originCf;
    });

	local rayWhitelist = {workspace.Environment; workspace.Terrain;};
	local charactersList = CollectionService:GetTagged("PlayerCharacters");
	if charactersList then
		for a=1, #charactersList do
			table.insert(rayWhitelist, charactersList[a]);
		end
	end

    modProjectile.serverSimulate(projectileInstance, {
        RayWhitelist = rayWhitelist;
        Velocity = velocity;
    });
end


function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.TargetObj.Value = nil;
    return false;
end

return treePackage;