local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17145634257;};
		Use={Id=17145637341;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 20;
		EffectType = "Heal";
		
		HealSourceId = "FoodHeal";
		HealRate = 0.2;
		
		UseDuration = 2;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;