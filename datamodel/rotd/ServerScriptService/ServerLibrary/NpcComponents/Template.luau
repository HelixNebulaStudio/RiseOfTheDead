local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {};
	
	
	setmetatable(self, Component);
	return self;
end

return Component;