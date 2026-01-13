local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local TierDamageLibrary = {
    ["Pistol"] = {
        0.5;
        0.55;
        0.6;
    };
    ["Submachine gun"] = {
        0.5;
        0.55;
        0.6;
        0.65;
    };
    ["Shotgun"] = {
        0.3;
        0.35;
        0.4;
        0.45;
    };
    ["Rifle"] = {
        0.3;
        0.35;
        0.4;
        0.45;
    };
    ["Sniper"] = {
        0.2;
        0.25;
        0.3;
    };
    ["Heavy machine gun"] = {
        0.5;
        0.55;
        0.6;
    };
    ["Pyrotechnic"] = {
        0.3;
        0.35;
        0.4;
    };
    ["Explosive"] = {
        0.2;
        0.25;
        0.3;
    };
    ["Bow"] = {
        0.2;
        0.25;
        0.3;
    };
};
--== 

function modItemModifierClass.onRequire()
    for _, ms in pairs(script:GetChildren()) do
        if not ms:IsA("ModuleScript") then continue end;
        ms.Parent = modItemModifierClass.Script;
        if ms:GetAttribute("__AutoRequire") == true then
            shared.require(ms);
        end
    end
end

function modItemModifierClass.AddTierDamage(modifier: ItemModifierInstance)
    if modifier.ModLibrary == nil then return end;
    if modifier.EquipmentClass == nil then return end;
    if modifier.EquipmentClass.Package == nil then return end;
    if modifier.EquipmentClass.Package.WeaponClass == nil then return end;

    local tier = modifier.ModLibrary.BaseTier or 1;

    local weaponClass = modifier.EquipmentClass.Package.WeaponClass; 

    local tierDmgLib = TierDamageLibrary[weaponClass];
    if tierDmgLib == nil then return end;

    local tierDmg = tierDmgLib[tier];
    if tierDmg == nil then return end;

    
    local totalMaxLevels = 0;
    local totalLevels = 0;
	local itemModStorageItem = modifier.ItemModStorageItem;
	local modLib = modifier.ModLibrary;
	for a=1, #modLib.Upgrades do
		local upgradeInfo = modLib.Upgrades[a];
        totalMaxLevels = totalMaxLevels + upgradeInfo.MaxLevel;

        if itemModStorageItem == nil then 
            totalLevels = totalLevels + upgradeInfo.MaxLevel;
            continue;
        end;
        totalLevels = totalLevels + (itemModStorageItem.Values[upgradeInfo.DataTag] or 0);
	end

    local scale = totalMaxLevels > 0 and math.clamp(totalLevels/totalMaxLevels, 0, 1) or 1;
    local tierDmgRatio = tierDmg * scale;

	local configurations = modifier.EquipmentClass.Configurations;
	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * tierDmgRatio;

    modifier.SumValues.Damage = additionalDmg;

    return additionalDmg, tierDmgRatio;
end

return modItemModifierClass;