local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

--==
local Hazard = {
	Title = "Witherers";
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
	self.Counter = 0;
	self.OnZombieDeathDisconnect = modOnGameEvents:ConnectEvent("OnZombieDeath", function(npcModule)
		local deathPosition = npcModule.DeathPosition;
		local config = npcModule.Configuration;

		self.Counter = self.Counter+1;

		if self.Counter >= 20 then
			self.Counter = 0;

			modNpc.Spawn("Witherer", CFrame.new(deathPosition), function(npc, withererNpcModule)
				withererNpcModule.Configuration.Level = config.Level;
			end)
		end
	end)
end

function Hazard:Tick()

end

function Hazard:End()
	if self.OnZombieDeathDisconnect then
		Debugger:Warn("OnZombieDeathDisconnect")
		self.OnZombieDeathDisconnect();
	end
end

return Hazard;
