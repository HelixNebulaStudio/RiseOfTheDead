local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="FoodTool";
	Animations={
		Core={Id=5096936519;};
		Use={Id=10370762593;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = (60*3);
		EffectType = "Status";
		
		StatusId = "Ziphoning";
		
		UseDuration = 1;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;