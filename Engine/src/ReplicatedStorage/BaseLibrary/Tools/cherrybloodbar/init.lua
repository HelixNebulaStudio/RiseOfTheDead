local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="FoodTool";
	Animations={
		Core={Id=17145531714;};
		Use={Id=17145534026;};
	};
};


function toolPackage.NewToolLib(handler)
	local toolLib = {};
	
	toolLib.Configurations = {
		EffectDuration = 3;
		EffectType = "Heal";

		HealSourceId = "FoodHeal";
		HealRate = 2;

		UseDuration = 1;
	};

	toolLib.__index = toolLib;
	setmetatable(toolLib, handler);
	return toolLib;
end

return toolPackage;