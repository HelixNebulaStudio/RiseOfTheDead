local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Hazard = {};
Hazard.__index = Hazard;

Hazard.Title = "Heavy Fog";

local modWeatherService = shared.require(game.ReplicatedStorage.Library.WeatherService);
local TweenService = game:GetService("TweenService");

Hazard.Controller = nil;
--==

function Hazard.new()
	local self = {};
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
	Hazard.Spawns = {};
	local fogSpawns = self.Controller.StageElements:FindFirstChild("FogSpawns");
	if fogSpawns then
		for _, obj in pairs(fogSpawns:GetChildren()) do
			table.insert(Hazard.Spawns, obj);
			obj.Transparency = 1;
		end
	end
end

function Hazard:Begin()
	local config = self.Controller.FogConfig;
	
	modWeatherService:SetWeather({
		Id="heavyfog";
	});
	
	self.LastSpawnTick = tick();
	self.HazardSpawns = {};
	
	if #Hazard.Spawns > 0 then
		repeat
			local pickSpawn = Hazard.Spawns[math.random(1, #Hazard.Spawns)];
			if table.find(self.HazardSpawns, pickSpawn) == nil then
				table.insert(self.HazardSpawns, pickSpawn);
			end
		until #self.HazardSpawns >= 3
	end
end

function Hazard:Tick()
	if tick()-self.LastSpawnTick >= 10 and #self.HazardSpawns > 0 then
		self.LastSpawnTick = tick();
		
		local spawnPart = table.remove(self.HazardSpawns, math.random(1, #self.HazardSpawns));
		local spawnName = spawnPart.Name;
		local spawnCf = spawnPart.CFrame;
		
		if spawnCf then
			
			local npcClass: NpcClass = self.Controller:SpawnEnemy(spawnName, {
				Level = math.min(self.Controller.Wave-1, self.Controller.PeekPlayerLevel);
				SpawnCFrame = spawnCf;
			});

			npcClass.Character:SetAttribute("EntityHudHealth", true);
			Debugger:Warn("Spawned fog entity",self.HazardSpawns);
		end
	end
end

function Hazard:End()
	modWeatherService:ClearWeather("heavyfog");
	
end

return Hazard;
