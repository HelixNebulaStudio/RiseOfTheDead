local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="HealTool";
	Animations={
		Core={Id=17076794599;};
		Use={Id=17076796044;};
		UseOthers={Id=16167636769;};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.Configurations = {
		HealAmount = 35;
		UseDuration = 4;
	};
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;