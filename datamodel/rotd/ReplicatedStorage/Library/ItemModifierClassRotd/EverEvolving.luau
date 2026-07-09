local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);

local modifierPackage = {
	Name = "Ever Evolving";

	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Instancing(modifier: ItemModifierInstance, isFirstTime: boolean)
    local function update()
        local verionStr = `{modGlobalVars.GameVersion}{modGlobalVars.GameBuild}`;
        local verionToNum = tonumber(verionStr);

        if modifier.EquipmentClass == nil then return end;

        local configurations = modifier.EquipmentClass.Configurations;

        local baseDamage = configurations.PreModDamage;
        local additionalDmg = baseDamage * (verionToNum/2);
        
        modifier.SetValues.EverEvolving = verionToNum;
        modifier.SumValues.PreModDamage = additionalDmg;
    end

	modifier.OnEnabledChanged:Connect(update);
    update();
end

return modifierPackage;