local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17052988779;};
		Use={Id=17053001636};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 30;
		EffectType = "Heal";

		HealSourceId = "FoodHeal";
		HealRate = 0.2;

		UseDuration = 3;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;