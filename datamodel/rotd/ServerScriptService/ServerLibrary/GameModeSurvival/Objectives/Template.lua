local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Template";
Objective.Description = "Template";

Objective.Controller = nil;
--==

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()

end

function Objective:Begin()

end

function Objective:Tick()

	return false;
end

function Objective:End()
	
end

return Objective;
