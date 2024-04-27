local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local NpcProperties = {};
NpcProperties.__index = NpcProperties;
--==
NpcProperties.StorageConfig = {
	Persistent=true;
	Size=5;
	axSize=5;
	Virtual=true;
};

NpcProperties.Level = 0;
NpcProperties.LevelUpTime = os.time();

NpcProperties.Happiness = 0;
NpcProperties.Hunger = 0;
NpcProperties.HungerRate = 0.1;
--==
function NpcProperties.new(data)
	local self = data or {};
	
	self.__index = self;
	setmetatable(self, NpcProperties);
	
	return self;
end

function NpcProperties:CalculateHappiness()
	local happiness = 0 - self.Hunger;
	
	self.Happiness = math.clamp(happiness, -10, 10);
end

function NpcProperties:SetLevel(level)
	self.Level = level;
	self.LevelUpTime = os.time();
end

return NpcProperties;