local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=17585654487;};
		Use={Id=17585665324};
	};
	Audio={};
	Configurations={
		UseViewmodel = false;
		CustomViewModel = CFrame.new(-0.24, -1, 0);
		UseFOV = 5;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;