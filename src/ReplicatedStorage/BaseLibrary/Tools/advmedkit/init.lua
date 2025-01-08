local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="HealTool";
	Animations={
		Core={Id=17114048278;};
		Use={Id=17114051824;};
		UseOthers={Id=5011194350;};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		HealAmount = 75;
		UseDuration = 4.5;
	};
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;