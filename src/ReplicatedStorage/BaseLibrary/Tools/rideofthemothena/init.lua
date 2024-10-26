local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=4843250039;};
		Use={Id=4706454123};
	};
};


function toolPackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.IsActive = false;

	toolLib.__index = toolLib;
	setmetatable(toolLib, handler);
	return toolLib;
end

return toolPackage;