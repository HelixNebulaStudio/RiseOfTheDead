local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17145603824;};
		Use={Id=17145607603;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 60;
		EffectType = "Status";

		StatusId = "StatusResistance";
		
		UseDuration = 4;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;