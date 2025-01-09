local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=3296519824;};
		Use={Id=4706454123};
	};
};


function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end

return toolPackage;