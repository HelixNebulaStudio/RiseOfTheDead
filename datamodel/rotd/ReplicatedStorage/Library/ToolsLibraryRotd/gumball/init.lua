local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
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
		EffectDuration = 30;
		EffectType = "Status";

		StatusId = {"ForceField"; "Reinforcement"; "Superspeed"; "Lifesteal"};
		
		UseDuration = 1;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;