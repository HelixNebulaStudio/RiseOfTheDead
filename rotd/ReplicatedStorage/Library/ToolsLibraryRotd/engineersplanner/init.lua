local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="PlannerTool";

	ToolWindow = "EngineerPlannerWindow";

	Animations={
		Core={Id=16357522577;};
	};
	Audio={};
	
	Configurations={
		UseViewmodel = false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;