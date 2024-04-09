local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Hazard = {};
Hazard.__index = Hazard;

Hazard.Title = "Fog";

local TweenService = game:GetService("TweenService");

Hazard.Controller = nil;
--==

function Hazard.new()
	local self = {};
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
	self.Atmosphere = game.ReplicatedStorage:FindFirstChild("ServerAtmosphere");
	
	local function setFogAmbient()
		local h, s, v = game.Lighting.OutdoorAmbient:ToHSV();
		self.Atmosphere.Color = Color3.fromHSV(129/255, 43/255, math.min(227/255, v));
	end
	if self.Atmosphere == nil then
		self.Atmosphere = script:WaitForChild("ServerAtmosphere"):Clone();
		
		setFogAmbient();
		self.Atmosphere.Parent = game.ReplicatedStorage;
	end
	
	game.Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(setFogAmbient)

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
	
	TweenService:Create(self.Atmosphere, TweenInfo.new(10), {
		Density=config.Density or 0.8;
		Offset=0.2;
		Haze=2.5;
	}):Play();
	
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
			local npcPrefab, npcModule = self.Controller:SpawnEnemy(spawnName, {
				Level = math.min(self.Controller.Wave-1, self.Controller.PeekPlayerLevel);
				SpawnCFrame = spawnCf;
			});

			npcPrefab:SetAttribute("EntityHudHealth", true);
			Debugger:Warn("Spawned fog entity",self.HazardSpawns);
		end
	end
end

function Hazard:End()
	task.spawn(function()
		TweenService:Create(self.Atmosphere, TweenInfo.new(10), {
			Density=0.3;
			Offset=0.3;
			Haze=0;
		}):Play();
		
	end)
end

return Hazard;
