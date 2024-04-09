local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();



--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {};
	
	
	setmetatable(self, Component);
	return self;
end

return Component;