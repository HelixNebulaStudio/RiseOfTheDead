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

NpcProperties.Happiness = 1;
NpcProperties.Hunger = 1;

NpcProperties.Health = 100;
NpcProperties.MaxHealth = 100;
NpcProperties.Armor = 10;
NpcProperties.MaxArmor = 10;

NpcProperties.HungerRate = 0.3; -- % cost per day.
--==
function NpcProperties.new(data)
	local self = data or {};
	
	self.__index = self;
	setmetatable(self, NpcProperties);
	
	return self;
end

function NpcProperties:CalculateHappiness()
	self.Hunger = math.clamp(self.Hunger, 0, 1);
	self.Health = math.clamp(self.Health, 0, self.MaxHealth);
	self.Armor = math.clamp(self.Armor, 0, self.MaxArmor);

	local health = math.clamp(self.Health/self.MaxHealth, 0, 1);
	local happiness = self.Hunger;
	self.Happiness = math.clamp(happiness*0.5 + health*0.5, 0, 1);
end

function NpcProperties:SetLevel(level)
	self.Level = level;
	self.LevelUpTime = os.time();
end

return NpcProperties;