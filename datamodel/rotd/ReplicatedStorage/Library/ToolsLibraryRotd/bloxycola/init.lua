local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17067020465;};
		Use={Id=17067021960;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 33;
		EffectType = "Status";

		StatusId = "BloxyRush";

		UseDuration = 3;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;