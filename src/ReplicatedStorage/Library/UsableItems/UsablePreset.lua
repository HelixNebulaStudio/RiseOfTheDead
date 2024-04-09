local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = {};
UsablePreset.__index = UsablePreset;

--==
function UsablePreset:Use()
	Debugger:Warn("Client tried to use",self.Id);
end

function UsablePreset.new()
	local self = {};
	
	setmetatable(self, UsablePreset);
	return self;
end

return UsablePreset;