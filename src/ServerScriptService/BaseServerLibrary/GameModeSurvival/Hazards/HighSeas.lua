local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Hazard = {};
Hazard.__index = Hazard;

Hazard.Title = "High Seas";

local TweenService = game:GetService("TweenService");

Hazard.Controller = nil;
--==

function Hazard.new()
	local self = {};
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
	self.RootCf = CFrame.new(-155, 24, 40);
end

function Hazard:Begin()
	local y = 4;
	for a=1, 5, 0.5 do
		workspace.Terrain:FillBlock(self.RootCf, Vector3.new(1024, math.min(y, 28), 1024), Enum.Material.Water)
		task.wait(1);
		y = y+2.8;
	end
end

function Hazard:Tick()

end

function Hazard:End()
	task.spawn(function()
		for y=14, 0, -1 do
			workspace.Terrain:FillBlock(self.RootCf + Vector3.new(0, y+1, 0), Vector3.new(1024, 2, 1024), Enum.Material.Air);
			task.wait(0.5);
		end
	end)
end

return Hazard;
