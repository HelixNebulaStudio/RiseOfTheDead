local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	ItemId="bloxycola";
	Type="FoodTool";
	Animations={
		Core={Id=17067020465;};
		Use={Id=17067021960;};
	};
	Audio={
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		EffectDuration = 33;
		EffectType = "Status";

		StatusId = "BloxyRush";

		UseDuration = 3;
	};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;