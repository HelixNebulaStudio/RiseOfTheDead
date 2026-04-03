local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local modifierPackage = {
	Name = "BulletRecouper";
	
	Tags = {GunModifier=true;};
	Binds = {};
};
--==

if RunService:IsServer() then
    function modifierPackage.Binds.WeaponShotPreProcess(modifier: ItemModifierInstance, packet)
        local shotPacket = packet.ShotPacket;
        if shotPacket == nil then return end;

        local hitInfoList = shotPacket.HitInfoList;
        if hitInfoList == nil then return end;

        local equipmentClass: EquipmentClass = packet.EquipmentClass;
        if equipmentClass == nil then return end;
        if equipmentClass.Configurations.BulletMode ~= 1 then return end; -- Hitscan;

        local wieldComp = modifier.WieldComp;
        if wieldComp == nil then return end;

        local characterClass: CharacterClass = wieldComp.CompOwner :: CharacterClass;
        if characterClass == nil then return end;

        local overrideTable = packet.OverrideTable;
        local hitValidTarget = false;

        for a=1, #shotPacket.HitInfoList do
            local hitInfo: HitInfo = hitInfoList[a];
            if hitInfo.Part == nil then continue end;

            local targetPart = hitInfo.Part.Parent;

            local healthComp: HealthComp? = modHealthComp.getByModel(targetPart);
            if healthComp == nil or not healthComp:CanTakeDamageFrom(characterClass) then continue end;

            hitValidTarget = true;
        end

        if hitValidTarget then return end;
        if math.random(1, 2) ~= 1 then return end;

        overrideTable.AmmoCost = 0;
        wieldComp:SyncEquipmentProperties(equipmentClass.StorageItem.ID, {"Ammo"});
    end
end

return modifierPackage;