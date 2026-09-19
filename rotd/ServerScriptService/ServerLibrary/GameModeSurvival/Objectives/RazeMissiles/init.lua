local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);


local Objective = {
	Controller = nil;
};
Objective.__index = Objective;

Objective.Title = "Raze Missiles";
Objective.Description = "Activate the Raze Missiles to disrupt zombie immunity";

--==
function Objective.onRequire()
	shared.modEventService:OnInvoked("Generic_BindTrigger", function(event: EventPacket, ...)
		local triggerId: string, interactable: InteractableInstance, packet = ...;
		
		if triggerId == "RazeMissile" then
			local config = interactable.Config;
			task.spawn(function()
				if config == nil
				or config.Parent == nil
				or config.Parent.Parent == nil then return end;
				
				local missile = config.Parent.Parent;

				config:SetAttribute("_InteractDuration", nil);
				config:SetAttribute("_Label", "Activated");

				local wave = missile:GetAttribute("Wave") or 1;
				missile:SetAttribute("Active", true);

				local destructibleConfig = modDestructibles.createDestructible("Scarecrow");
				destructibleConfig:SetAttribute("_AttractRange", 128);
				destructibleConfig:SetAttribute("_ExpiringDamageTick", false);
				destructibleConfig.Parent = missile;
				
				local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
				destructible.BroadcastHealth = true;
				destructible.HealthComp:SetCanBeHurtBy("!Player&!Human"); -- not HumanoidType == Player & not Survivors
				destructible.HealthComp:SetMaxHealth(wave * 500);
				destructible.HealthComp:Reset();

				destructible:SetupHealthbar{
					Size = UDim2.new(4, 0, 1, 0);
					Distance = 128;
					OffsetWorldSpace = Vector3.new(0, 3, 0);
					ShowLabel = true;
				};
			end)
		end
	end)
end

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	Objective.MissileSpawns = {};

	local razeMissiles = self.Controller.StageElements:WaitForChild("RazeMissiles");
	for _, obj in ipairs(razeMissiles:GetChildren()) do
		table.insert(Objective.MissileSpawns, obj);
	end
end

function Objective:Begin()
	local controller = self.Controller;

	self.CurMissiles = {};
	self.State = 1;

	local pickList = {};
	for _, missile in pairs(self.MissileSpawns) do
		table.insert(pickList, missile);
	end
		
	local missileSpawnCount = 2;
	if controller.Wave >= 50 then
		missileSpawnCount = 4;
	elseif controller.Wave >= 20 then
		missileSpawnCount = 3;
	end

	for a=1, missileSpawnCount do
		local newMissile = table.remove(pickList, math.random(1, #pickList));
		newMissile = newMissile:Clone();
		newMissile:SetAttribute("Wave", controller.Wave);
		newMissile.Parent = workspace.Environment.Game;
		table.insert(self.CurMissiles, newMissile);

		controller.StageGarbage:Tag(newMissile);

		local interactConfig = modInteractables.createInteractable("ButtonRotd");
		interactConfig:SetAttribute("_Id", "RazeMissile");
		interactConfig:SetAttribute("_IndicatorPresist", true);
		interactConfig:SetAttribute("_Label", "Activate");
		interactConfig:SetAttribute("_Uses", 1);
		interactConfig:SetAttribute("_InteractDuration", 2);
		interactConfig.Parent = newMissile:WaitForChild("keyPad");

	end

	controller:Hud{
		ObjectiveDesc = `Activate {0}/{#self.CurMissiles} Raze Missiles`;
	};
end

function Objective:Tick()
	local controller = self.Controller;

	local endWaveBool = false;

	if self.State == 1 then
		
		local active = 0;
		for _, missile in pairs(self.CurMissiles) do
			if missile:GetAttribute("Active") ~= true then continue end;
			active += 1;
		end

		if active >= #self.CurMissiles then
			self.State = 2;

			self.SecTick = tick();
			controller.WaveStartTime = workspace:GetServerTimeNow();
			controller.WaveDuration = 10;
			controller:Hud{
				ObjectiveDesc = `Survive until the missiles detonate`;
			};

		else
			if self.LastMissileCount ~= active then
				modAudio.Play("KeyLock", workspace).PlaybackSpeed = 3;
				self.LastMissileCount = active;
			end
			controller:Hud{
				ObjectiveDesc = `Activate {active}/{#self.CurMissiles} Raze Missiles`;
			};

		end

	elseif self.State == 2 then
		if workspace:GetServerTimeNow() >= controller.WaveStartTime + controller.WaveDuration then
			self.State = 3;

			modAudio.Play("DoomAlarm", workspace);
			controller.WaveStartTime = nil;
			controller.WaveDuration = nil;
			controller:Hud{
				ObjectiveDesc = `Kill the remaining enemies`;
			};

			for _, npcClass: NpcClass in ipairs(controller.EnemyNpcClasses) do
				npcClass.Properties.Immunity = nil;
			end

			for _, missile in ipairs(self.CurMissiles) do
				task.delay(0.333, function()
					local primaryPart = missile.PrimaryPart;
					if primaryPart == nil then return end;

					local lastPosition = primaryPart.Position;
		
					modAudio.Play(math.random(1, 2) == 1 and "Explosion" or "Explosion2", lastPosition);
					
					local ex = Instance.new("Explosion");
					ex.DestroyJointRadiusPercent = 0;
					ex.BlastRadius = 256;
					ex.BlastPressure = 0;
					ex.Position = lastPosition;
					ex.Parent = workspace;
					Debugger.Expire(ex, 1);

					primaryPart:ClearAllChildren();
					missile.Parent = workspace.Debris;
					Debugger.Expire(missile, 4);

					for _, part in pairs(missile:GetChildren()) do
						if not part:IsA("BasePart") or part == primaryPart then continue end;
						part.Anchored = false;
						part.CanCollide = true;

						local rngVec = Vector3.new(
							math.random(-100, 100)/100, 
							math.random(0, 50)/100, 
							math.random(-100, 100)/100
						).Unit;
						local dir = (part.Position-(lastPosition + rngVec)).Unit
						part:ApplyImpulse(dir * part.AssemblyMass * 150);
					end
					
					local hitLayers = modExplosionHandler:Cast(lastPosition, {
						Radius = 256;
					});
					
					modExplosionHandler:Process(lastPosition, hitLayers, {
						DamageRatio = 1;
						ExplosionStun = 3;

						DamageOrigin = lastPosition;
						OnPartHit = modExplosionHandler.GenericOnPartHit;

						BindHealthCompHit = function(healthComp: HealthComp, newDmgData)
							local charClass: CharacterClass = healthComp.CompOwner :: CharacterClass;
							if charClass == nil then return false; end;
							
							if charClass.ClassName == "NpcClass" and charClass.HumanoidType == "Zombie" then
								charClass.Properties.Immunity = nil;
							end

							return charClass.ClassName == "PlayerClass";
						end;
					});
				end)
			end

		else
			if tick() > self.SecTick then
				self.SecTick = tick() +1;
            	modAudio.Play("ClockTick", workspace);
			end
		end

	elseif self.State == 3 then
		if #controller.EnemyNpcClasses <= 0 then
			endWaveBool = true;
		end

	end

	if self.State == 1 then

		local canSpawn = true;

		if #controller.EnemyNpcClasses >= 30 then
			canSpawn = false;
		end

		if canSpawn then
			local enemyName = controller:PickEnemy();
			local enemyLevel = controller:GetWaveLevel();
			controller:SpawnEnemy(enemyName, {
				Level = enemyLevel;
				Immunity = 1;
			});

		end
	end

	return endWaveBool;
end

function Objective:End()
	local controller = self.Controller;

	table.clear(self.CurMissiles);
end

return Objective;
