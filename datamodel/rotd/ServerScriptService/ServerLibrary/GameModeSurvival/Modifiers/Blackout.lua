local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--==
local Modifier = {};
Modifier.__index = Modifier;
--==

function Modifier:Set(modifier)
	return setmetatable(modifier, Modifier);
end

function Modifier:Begin(controller)
	self.LastSpawnTick = tick();
	self.PathSpawned = 0;
	workspace:SetAttribute("ModifiersBlackout", true);
	shared.Notify(game.Players:GetPlayers(), "[Blackout] Threat sense is disabled.", "Important");
end

function Modifier:Tick(controller)
	local spawnLimit = self.Value;
	
	if tick()-self.LastSpawnTick >= 15 and self.PathSpawned <= spawnLimit then
		self.LastSpawnTick = tick();
		self.PathSpawned = self.PathSpawned +1;
		
		controller:SpawnEnemy("Pathoroth", {
			Level = math.min(controller.Wave*2, controller.PeekPlayerLevel);
		})
	end
end

function Modifier:End(controller)
	workspace:SetAttribute("ModifiersBlackout", false);
end

return Modifier;
