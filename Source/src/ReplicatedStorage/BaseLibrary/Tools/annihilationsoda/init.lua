local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="FoodTool";
	Animations={
		Core={Id=17393100664;};
		Use={Id=17393103125;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 120;
		EffectType = "Status";
		
		StatusId = "CritBoost";
		
		UseDuration = 3;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;