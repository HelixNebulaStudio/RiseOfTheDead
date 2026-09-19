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

        local multi = 1 + (verionToNum/2);
        
        modifier.SetValues.EverEvolving = verionToNum;
        modifier.ProductValues.PreModDamage = multi;
    end

	modifier.OnEnabledChanged:Connect(update);
    update();
end

return modifierPackage;