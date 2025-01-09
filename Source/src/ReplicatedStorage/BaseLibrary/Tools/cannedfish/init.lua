local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	ItemId="cannedfish";
	Type="FoodTool";
	Animations={
		Core={Id=17145603824;};
		Use={Id=17145607603;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 60;
		EffectType = "Status";

		StatusId = "StatusResistance";
		
		UseDuration = 4;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;