local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="HealTool";

	Animations={
		Core={Id=17076794599;};
		Use={Id=17076796044;};
		UseOthers={Id=16167636769;};
	};
	Audio={};
	Configurations={
		HealAmount = 50;
		UseDuration = 5;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;