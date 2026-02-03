local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Agile Recovery";

	Tags = {};
	Binds = {};
};

function modifierPackage.Binds.Update(modifier: ItemModifierInstance)
	local skillData = modifier.Values.SkillData;
	local percent = skillData.Stats.Percent.Value;
	
	modifier.SumValues.MoveImpairReduction = math.clamp(percent/100, 0, 1);
end

return modifierPackage;