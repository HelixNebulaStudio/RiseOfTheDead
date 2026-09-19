local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modifierPackage = {
	Id = script.Name;
	Name = "Agile Recovery";

	Tags = {};
	Binds = {};
};

function modifierPackage.Binds.Update(modifier: ItemModifierInstance)
	local skillData = modifier.Properties.SkillData;
	local percent = skillData.Stats.Percent.Value;
	
	modifier.SumValues.MoveImpairReduction = math.clamp(percent/100, 0, 1);
end

return modifierPackage;