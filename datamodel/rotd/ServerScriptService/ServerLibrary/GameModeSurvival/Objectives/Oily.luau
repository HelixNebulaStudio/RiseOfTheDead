local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local eliminateObjective = shared.require(script.Parent.Eliminate);

local Objective = {};
Objective.__index = Objective;
Objective.DifficultyModes = {Easy=false;};

Objective.Title = "Oily";

Objective.Controller = nil;
--==

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	eliminateObjective.Controller = self.Controller;
end

function Objective:Begin()
	self.LastZombieSpawn = tick();
	self.StartTime = tick()+5;
	
	local bossList = {};
	
	local bossPrefab, npcModule = self.Controller:SpawnEnemy("Oily", {
		Level = self.Controller:GetWaveLevel();
	});
	
	npcModule.IsBoss = true;
	npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;

	npcModule:Died(function()
		game.Debris:AddItem(bossPrefab, 10);

		for a=#bossList, 1, -1 do
			if bossList[a] == bossPrefab then
				table.remove(bossList, a);
			end
		end

		self.Controller:Hud{
			BossKilled=true;
		};
	end)

	bossPrefab:SetAttribute("EntityHudHealth", true);
	table.insert(bossList, bossPrefab);

	self.Controller:Hud{
		BossList = bossList;
	};

	eliminateObjective:Begin()
end

function Objective:Tick()
	return eliminateObjective:Tick();
end

function Objective:End()
	eliminateObjective:End();
end

return Objective;
