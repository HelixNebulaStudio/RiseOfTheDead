local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);


--==
local Hazard = {
	Title = "BombBarrage";
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
	self.RoundStartTick = tick();
end

function Hazard:Tick()
	if self.LastAirtrike == nil then
		self.LastAirtrike = tick()+5;
	end
	
	if self.LastAirtrike > tick() then return end;
	local timeLapsed = math.clamp(tick()-self.RoundStartTick, 0, 60)/60;
	
	self.LastAirtrike = tick() + math.random(3, 6) - (timeLapsed * 2);

	if timeLapsed >= 45 and math.random(1, 2) == 1 then
		self.LastAirtrike = tick();

	elseif timeLapsed >= 25 and math.random(1, 4) == 1 then
		self.LastAirtrike = tick();
		
	end
		
	local randomCFrame;
	
	local randomChar = self.Controller.Characters[math.random(1, #self.Controller.Characters)];
	randomCFrame = randomChar:GetPivot();
	
	if math.random(1, 3) == 1 and #self.Controller.EnemyModules > 0 then
		local randomNpcModule = self.Controller.EnemyModules[math.random(1, #self.Controller.EnemyModules)];
		randomCFrame = randomNpcModule.RootPart.CFrame;
	end
	

	local groundCframe = modAoeHighlight:Ray(randomCFrame.Position + Vector3.new(0, 128, 0), Vector3.new(0, -256, 0));
	
	for a=1, 5 do
		if groundCframe then
			break;
		else
			groundCframe = modAoeHighlight:Ray(randomCFrame.Position + Vector3.new(math.random(-64, 64), 128, math.random(-64, 64)), Vector3.new(0, -256, 0));
		end
	end
	
	if groundCframe == nil then Debugger:Warn("Failed to find ground for airstrike.") return end;
	
	local timeToImpact = 3 - (timeLapsed * 2);
	local impactRadius = 24;
	
	if self.Controller.Wave >= 10 then
		impactRadius = 34;
	end
	
	local new = modAoeHighlight.newCylinder(timeToImpact+0.1);
	new.CFrame = groundCframe;
	new.Size = Vector3.new(4, 4, 2);
	new.Parent = workspace.Entities;

	TweenService:Create(new, TweenInfo.new(timeToImpact, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Size = Vector3.new(impactRadius, impactRadius, 4)}):Play();
	
	local origin = groundCframe.Position + Vector3.new(0, 128, 0);
	local targetPoint = groundCframe.Position;

	local projectileObject = modProjectile.Fire("rpgRocket", CFrame.new(origin));
	projectileObject.TargetableEntities = {Humanoid=1; Zombie=1; Bandit=1; Rat=1;};
	projectileObject.Configurations.DamageRatio = 0.25 - (timeLapsed * 0.1);
	projectileObject.Configurations.ExplosionRadius = impactRadius/2;

	local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, timeToImpact);
	modProjectile.ServerSimulate(projectileObject, origin, velocity);
end

function Hazard:End()
	
end

return Hazard;
