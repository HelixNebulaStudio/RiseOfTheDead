local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="FoodTool";
	Animations={
		Core={Id=14880979790;};
		Use={Id=4534092581;};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 10;
		EffectType = "Heal";

		HealSourceId = "FoodHeal";
		HealRate = 0.75;

		UseDuration = 2;
	};
	
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;