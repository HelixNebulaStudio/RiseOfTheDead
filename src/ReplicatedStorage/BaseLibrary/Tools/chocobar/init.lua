local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	ItemId="chocobar";
	Type="FoodTool";
	Animations={
		Core={Id=17145634257;};
		Use={Id=17145637341;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 20;
		EffectType = "Heal";
		
		HealSourceId = "FoodHeal";
		HealRate = 0.2;
		
		UseDuration = 2;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;