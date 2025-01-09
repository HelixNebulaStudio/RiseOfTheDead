local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	ItemId="eggnog";
	Type="FoodTool";
	Animations={
		Core={Id=17145536579;};
		Use={Id=17145547730;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 120;
		EffectType = "Status";

		StatusId = "FrostivusSpirit";
		
		UseDuration = 2;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;