local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17145574614;};
		Use={Id=17145576789;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 120;
		EffectType = "Status";

		StatusId = "FrostivusSpirit";

		UseDuration = 2;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;