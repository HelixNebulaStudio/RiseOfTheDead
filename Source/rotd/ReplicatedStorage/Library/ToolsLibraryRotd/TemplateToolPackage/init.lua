local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="GenericTool";

	Animations={
		Core={Id=4493584242;};
		Use={Id=4493588865};
	};
	Audio={};
	Configurations={};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;