local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="FoodTool";

	Animations={
		Core={Id=17393100664;};
		Use={Id=17393103125;};
	};
	Audio={};
	
	Configurations={
		EffectDuration = 120;
		EffectType = "Status";
		
		StatusId = "CritBoost";
		
		UseDuration = 3;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;