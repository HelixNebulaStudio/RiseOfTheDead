local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);


local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;

local itemModifier = modItemModProperties.new(script);

if RunService:IsServer() then
    local modToolService = require(game.ServerScriptService.ServerLibrary.ToolService);

	function itemModifier:OnBulletHit(packet)
        if packet.Index ~= packet.EndIndex then return end;

        local toolModule = self.WeaponModule;
		local player = packet.Player;
        local hitInfo = packet.HitInfo;
        
        local configurations = toolModule.Configurations;
        local bulletRicochetCount = configurations.BulletRicochetCount or 1;
        local bulletRicochetDistance = configurations.BulletRicochetDistance or 64;

        local shotDirection = packet.ShotDirection;
        local hitPosition = hitInfo.Position;
        local hitNormal = hitInfo.Normal;

        local profile = shared.modProfile:Get(player);
        local equippedSiid = profile.EquippedTools and profile.EquippedTools.ID;
        if equippedSiid == nil then return end;

        local storageItem = shared.modStorage.FindIdFromStorages(equippedSiid, player);
        if storageItem == nil then return end;

        overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");
        overlapParams.MaxParts = math.max(5, bulletRicochetCount*2);

        local raycastParam = RaycastParams.new();
        raycastParam.IgnoreWater = true;
        raycastParam.FilterType = Enum.RaycastFilterType.Include;

        local function ricochet(ricochetOrigin)
            local rootParts = workspace:GetPartBoundsInRadius(ricochetOrigin, bulletRicochetDistance, overlapParams);
        
            local closestRpDist = math.huge;
            local direction;

            for a=1, #rootParts do
                local targetRootPart = rootParts[a];
                local targetModel = targetRootPart.Parent;
                local targetDamagable = modDamagable.NewDamagable(targetModel);

                if targetDamagable == nil then continue end;
                if not targetDamagable:CanDamage(player) then continue end;

                local targetPosition = targetRootPart.Position;
                local targetDirection = (targetPosition-ricochetOrigin).Unit;

                local shotRange = bulletRicochetDistance * 2;
                
                raycastParam.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain; targetRootPart;};
                local rayResult = workspace:Raycast(ricochetOrigin, targetDirection * shotRange, raycastParam);
                if rayResult == nil or rayResult.Instance ~= targetRootPart then continue end;

                local dist = (targetRootPart.Position-ricochetOrigin).Magnitude;
                if dist <= closestRpDist then
                    closestRpDist = dist;
                    direction = targetDirection;
                end
            end

            if direction == nil then
                direction = shotDirection - 2 * shotDirection:Dot(hitNormal) * hitNormal
            end

            local firePacket = {
                StorageItem = storageItem;
                ToolModel = packet.WeaponModel;
                ToolModule = toolModule;

                Player = player;

                ShotOrigin = ricochetOrigin;
                ShotDirection = direction;

                ReplicateToShotOwner = true;
                IsRicochet = true;

                Targetable = {
                    Zombie = true;
                    Bandit = true;
                    Cultist = true;
                    Rat = true;
                };
            };
            
            if packet.FocusCharge then
                firePacket.FocusCharge = packet.FocusCharge;
            end
            
            modToolService.PrimaryFireWeapon(firePacket);
        end

        task.wait();
        ricochet(hitPosition);
	end
end


return itemModifier;