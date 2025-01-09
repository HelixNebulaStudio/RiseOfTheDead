local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="FoodTool";
	Animations={
		Core={Id=17145574614;};
		Use={Id=17145576789;};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		UseDuration = 2;
		EffectType = "Perks"
	};
	
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;