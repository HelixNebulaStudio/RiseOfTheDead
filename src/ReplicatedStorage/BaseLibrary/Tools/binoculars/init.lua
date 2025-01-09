local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="RoleplayTool";
	Animations={
		Core={Id=17585654487;};
		Use={Id=17585665324};
	};
};


function toolPackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.IsActive = false;
	toolLib.UseViewmodel = false;
	toolLib.CustomViewModel = CFrame.new(-0.24, -1, 0);
	toolLib.UseFOV = 5;
	
	toolLib.__index = toolLib;
	setmetatable(toolLib, handler);
	return toolLib;
end

return toolPackage;