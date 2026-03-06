local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;

local modifierPackage = {
	Name = "Ricochet Rifling";
	
	Tags = {};
	Binds = {};
};
--==
function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
    if RunService:IsClient() then return end;
    local modToolService = shared.require(game.ServerScriptService.ServerLibrary.ToolService);
    
    local hitInfo = packet.HitInfo;
    if packet.Index ~= packet.EndIndex then return end;
    if packet.RicochetCount and packet.RicochetCount <= 0 then return end;

    local wieldComp: WieldComp? = modifier.WieldComp;
    if wieldComp == nil then return end;

    local characterClass: CharacterClass = wieldComp.CompOwner :: CharacterClass;
    if characterClass == nil then return end;

    local equipmentClass = modifier.EquipmentClass;
    if equipmentClass == nil then return end;

    local storageItem: StorageItem = equipmentClass.StorageItem;
    local toolHandler: ToolHandlerInstance = wieldComp:GetToolHandler(storageItem.ID, storageItem.ItemId);

    local configurations = equipmentClass.Configurations;
    local bulletRicochetCount = configurations.BulletRicochetCount or 1;
    local bulletRicochetDistance = configurations.BulletRicochetDistance or 64;

    local shotDirection = packet.ShotDirection;
    local hitPosition = hitInfo.Position;
    local hitNormal = hitInfo.Normal;

    local raycastParam = RaycastParams.new();
    raycastParam.IgnoreWater = true;
    raycastParam.FilterType = Enum.RaycastFilterType.Include;

    overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");
    overlapParams.MaxParts = math.max(5, bulletRicochetCount*2);

    local function ricochet(ricochetOrigin)
        local rootParts = workspace:GetPartBoundsInRadius(ricochetOrigin, bulletRicochetDistance, overlapParams);
    
        local closestRpDist = math.huge;
        local direction;

        for a=1, #rootParts do
            local targetRootPart = rootParts[a];
            local targetModel = targetRootPart.Parent;
            local targetHealthComp: HealthComp? = modHealthComp.getByModel(targetModel);

            if targetHealthComp == nil or not targetHealthComp:CanTakeDamageFrom(characterClass) then continue end
            if targetHealthComp.IsDead then continue end

            local targetPosition = targetRootPart.Position;
            local targetDirection = (targetPosition-ricochetOrigin).Unit;

            local shotRange = bulletRicochetDistance * 2;
            
            raycastParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain; targetRootPart;};
            local rayResult = workspace:Raycast(ricochetOrigin, targetDirection * shotRange, raycastParam);
            if rayResult == nil or rayResult.Instance ~= targetRootPart then continue end;

            local dist = (targetRootPart.Position-ricochetOrigin).Magnitude;
            if dist > 3 and dist <= closestRpDist then
                closestRpDist = dist;
                direction = targetDirection;
            end
        end

        if direction == nil then
            direction = shotDirection - 2 * shotDirection:Dot(hitNormal) * hitNormal;
        end

        -- local ray = Ray.new(ricochetOrigin, direction*128);
        -- local dbPoint = Debugger:Ray(ray);
        -- dbPoint.Color = BrickColor.random().Color;
        -- dbPoint.Parent = workspace.Debris;
        -- game.Debris:AddItem(dbPoint, 20);

        local firePacket = {
            StorageItem = storageItem;
            ToolHandler = toolHandler;

            ShotBy = characterClass;

            ShotOriginPos = ricochetOrigin;
            ShotDirection = direction;

            ReplicateToShotOwner = true;
            RicochetCount = packet.RicochetCount or bulletRicochetCount;

            ToolModel = packet.ToolModel;
			TargetableTags = table.clone(toolHandler.WieldComp.TargetableTags);
        };
        
        if packet.FocusCharge then
            firePacket.FocusCharge = packet.FocusCharge;
        end
        
        modToolService.PrimaryFireWeapon(firePacket);
    end

    task.delay(0.1, ricochet, hitPosition);
end

return modifierPackage;