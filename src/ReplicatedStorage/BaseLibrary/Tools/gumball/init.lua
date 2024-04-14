local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	ItemId="gumball";
	Type="FoodTool";
	Animations={
		Core={Id=17145531714;};
		Use={Id=17145534026;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 30;
		EffectType = "Status";

		StatusId = {"ForceField"; "Reinforcement"; "Superspeed"; "Lifesteal"};
		
		UseDuration = 1;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;