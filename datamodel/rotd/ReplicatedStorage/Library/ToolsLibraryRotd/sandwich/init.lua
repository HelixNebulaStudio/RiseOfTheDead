local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17393105157;};
		Use={Id=17393108574;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 10;
		EffectType = "Heal";

		HealSourceId = "FoodHeal";
		HealRate = 0.75;

		UseDuration = 2;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;