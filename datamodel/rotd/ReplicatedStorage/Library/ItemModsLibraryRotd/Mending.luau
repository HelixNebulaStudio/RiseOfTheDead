local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Mending";
	
	Tags = {};
	Binds = {};
};
--==
function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.DeathHandler(modifier: ItemModifierInstance, npcClass: NpcClass)
		if modifier.WieldComp == nil then return end;

		local characterClass: CharacterClass = modifier.WieldComp.CompOwner;
		if characterClass == nil then return end;

		local statusComp: StatusComp = characterClass.StatusComp;

		local statusClass = statusComp:GetOrDefault("ArmorBreak");
		if statusClass == nil then return end;

		local timeReduction = modifier.Values.Time;
		if timeReduction == nil or timeReduction <= 0 then return end;

		local newTime = statusClass.Expires - timeReduction;
		newTime = math.clamp(newTime, workspace:GetServerTimeNow(), statusClass.Expires);

		statusClass.Expires = newTime;
		statusClass:Sync();
	end
end

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.Values.Time = value;
	modifier.ArrayValues.PassiveModifiers = "Mending";
end


return modifierPackage;