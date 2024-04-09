local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");

local toolPackage = {
	Type="PlannerTool";
	Animations={
		Core={Id=16357522577;};
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.UseViewmodel = false;
	
	
	setmetatable(Tool, handler);
	return Tool;
end;

return toolPackage;