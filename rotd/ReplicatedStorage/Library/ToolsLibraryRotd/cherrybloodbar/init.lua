local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17145531714;};
		Use={Id=17145534026;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 3;
		EffectType = "Heal";

		HealSourceId = "FoodHeal";
		HealRate = 2;

		UseDuration = 1;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;