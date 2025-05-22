local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="HealTool";

	Animations={
		Core={Id=17114048278;};
		Use={Id=17114051824;};
		UseOthers={Id=5011194350;};
	};
	Audio={};
	Configurations={
		HealAmount = 75;
		UseDuration = 4.5;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;