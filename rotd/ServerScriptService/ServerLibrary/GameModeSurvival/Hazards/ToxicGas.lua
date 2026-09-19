local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modToxicClip = shared.require(game.ReplicatedStorage.Library.WorldClipsHandler._toxicClip);

--==
local Hazard = {
	Title = "Toxic Gas";
	Description = "Toxic gas is leaking from the pipes";	
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
	modToxicClip.Config.Damage = 10;
	
	self.ClipsTemplates = self.Controller.StageElements:WaitForChild("ToxicGas"):GetChildren();
	self.ActiveClips = {};
end

function Hazard:Begin()
	local list = {};
	for a=1, #self.ClipsTemplates do
		table.insert(list, self.ClipsTemplates[a]);
	end
	
	for a=1, 3 do
		local new = table.remove(list, math.random(1, #list)):Clone();
		table.insert(self.ActiveClips, new);
		new.Parent = workspace.Clips;
	end
	
	self.StartTime = tick();
end

function Hazard:Tick()
	local timeLapsed = math.clamp(math.ceil(tick()-self.StartTime)*0.5, 10, 25);
	modToxicClip.Config.Damage = timeLapsed;
end

function Hazard:End()
	for _, obj in pairs(self.ActiveClips) do
		game.Debris:AddItem(obj, 0);
	end
	table.clear(self.ActiveClips);
end

return Hazard;
