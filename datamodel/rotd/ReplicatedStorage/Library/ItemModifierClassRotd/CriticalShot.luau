local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modPseudoRandom = shared.require(game.ReplicatedStorage.Library.PseudoRandom);

local casualRandom;

local modifierPackage = {
	Name = "Critical Shot";

	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
    if RunService:IsClient() then return end;
    if modifier.WieldComp == nil then return end;

    local equipmentClass;

    if modifier.Tags.StatusMod and damageData.StorageItem then
        equipmentClass = modifier.WieldComp:GetEquipmentClass(damageData.StorageItem.ID);
        
    elseif modifier.Tags.StatusMod ~= true then
        if modifier.EquipmentClass == nil then return end;
        if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
            return;
        end

        equipmentClass = modifier.EquipmentClass;
    end

    if equipmentClass == nil then return end;
    local configurations = equipmentClass.Configurations;

    local critChance = configurations.CritChance or 0;
    if critChance <= 0 then return end;

    if damageData.CriticalShotProcessed then 
        return;
    end;
    damageData.CriticalShotProcessed = true;

    if casualRandom == nil then
        casualRandom = modPseudoRandom.new();
    end
    local critProced = casualRandom:FairCrit(nil, critChance);
    if critProced == false then return end;

    local preModDamage = configurations.PreModDamage;
    if preModDamage == nil then return end;

    local multi = configurations.CritMulti or 1.5;
    local add = (preModDamage * multi);

    damageData.Damage = damageData.Damage + add;
    damageData.DamageType = "Crit";

    local toolHandler: ToolHandlerInstance? = damageData.ToolHandler;
    local toolModel = toolHandler and toolHandler.MainToolModel;
    if toolModel then
        local critSound = modAudio.Play("CritHit0"..math.random(1, 2) , toolModel.PrimaryPart);
        critSound.PlaybackSpeed = math.random(800, 1200)/1000;
        critSound.Volume = 1;
    end
end

return modifierPackage;