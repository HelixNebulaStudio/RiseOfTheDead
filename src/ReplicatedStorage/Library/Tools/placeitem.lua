local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);


return function(handler)
	local Tool = {};
	Tool.UseViewmodel = false;
	
	setmetatable(Tool, handler);
	return Tool;
end;