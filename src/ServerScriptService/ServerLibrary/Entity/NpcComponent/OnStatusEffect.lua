local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

--== Script;
local Component = {};
Component.__index = Component;

function Component.new(Npc)
	return function(bindFunc)
		return bindFunc;
	end
end

return Component;