local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=5096936519;};
		Use={Id=10370762593;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = (60*3);
		EffectType = "Status";
		
		StatusId = "Ziphoning";
		
		UseDuration = 1;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;