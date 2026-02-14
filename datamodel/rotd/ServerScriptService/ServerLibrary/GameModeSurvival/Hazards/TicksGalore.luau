local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Hazard = {
	Title = "Ticks Galore";
	Description = "Only Ticks spawns";
	Controller = nil;
};
Hazard.__index = Hazard;
--==

function Hazard.new()
	local self = {};
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()

end

function Hazard:Begin()

end

function Hazard:Tick()

end

function Hazard:End()
	
end

return Hazard;
