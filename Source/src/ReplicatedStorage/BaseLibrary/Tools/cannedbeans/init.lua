local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="FoodTool";
	Animations={
		Core={Id=17052988779;};
		Use={Id=17053001636};
	};
};


function toolPackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Configurations = {
		EffectDuration = 30;
		EffectType = "Heal";

		HealSourceId = "FoodHeal";
		HealRate = 0.2;

		UseDuration = 3;
	};
	
	toolLib.__index = toolLib;
	setmetatable(toolLib, handler);
	return toolLib;
end

return toolPackage;