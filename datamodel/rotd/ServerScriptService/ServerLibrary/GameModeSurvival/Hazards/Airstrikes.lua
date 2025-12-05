local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);


--==
local Hazard = {
	Title = "Airstrikes";
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
	self.JetPrefab = script:WaitForChild("Jet");
	self.JetPrimary = self.JetPrefab:WaitForChild("JetPart");
	self.JetIdleSnd = self.JetPrimary:WaitForChild("JetIdle");
	self.JetSwooshSnd = self.JetPrimary:WaitForChild("Swoosh");
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
	
	self.LastAirtrike = tick() + math.random(8, 10) - (timeLapsed * 3);
	if timeLapsed >= 115 and math.random(1, 2) == 1 then
		self.LastAirtrike = tick();

	elseif timeLapsed >= 75 and math.random(1, 4) == 1 then
		self.LastAirtrike = tick();

	end
	
	local randomCFrame, groundCframe;
	repeat
		local randomChar = self.Controller.Characters[math.random(1, #self.Controller.Characters)];
		randomCFrame = randomChar:GetPivot();
		if math.random(1, 3) == 1 and #self.Controller.EnemyNpcClasses > 0 then
			local randomNpcModule = self.Controller.EnemyNpcClasses[math.random(1, #self.Controller.EnemyNpcClasses)];
			randomCFrame = randomNpcModule.RootPart.CFrame;
		end
		groundCframe = modAoeHighlight:Ray(randomCFrame.Position + Vector3.new(0, 128, 0), Vector3.new(0, -256, 0));
	until groundCframe ~= nil;
	
	
	local randomDir;
	repeat
		randomDir = Vector3.new(math.random(-100, 100)/100, 0, math.random(-100, 100)/100).Unit;
	until rawequal(randomDir, randomDir) == true;
	
	local jetAltitude = 120;
	local dirDist = 800;
	
	self.JetIdleSnd:Play();
	
	local entryOrigin = CFrame.new(groundCframe.Position) * CFrame.new(0, jetAltitude, 0) * CFrame.new(randomDir*dirDist);
	local exitPoint = entryOrigin * CFrame.new(-randomDir*dirDist*2);
	local lookAtCf = CFrame.lookAt(entryOrigin.Position, exitPoint.Position);
	
	entryOrigin = entryOrigin * lookAtCf.Rotation;
	exitPoint = exitPoint * lookAtCf.Rotation;

	self.JetPrefab:PivotTo(entryOrigin);
	self.JetPrefab.Parent = workspace.Entities;
	
	local jetFlyByTween = TweenService:Create(self.JetPrimary, TweenInfo.new(5, Enum.EasingStyle.Linear), {CFrame=exitPoint;});
	jetFlyByTween.Completed:Once(function()
		self.JetPrefab.Parent = script;
	end)
	jetFlyByTween:Play();

	self.JetSwooshSnd:Play();
	
	local timeToImpact = 2 - (timeLapsed * 1.2);
	local impactRadius = 26;

	-- if self.Controller.Wave >= 10 then
	-- 	local maxRadius = 64;
	-- 	impactRadius = math.clamp(34 + (self.Controller.Wave-10), 34, maxRadius);
		
	-- 	timeToImpact = math.clamp((impactRadius/maxRadius*4) - (timeLapsed * 2), 2, 6);
	-- end

	local targetCFrame = groundCframe;
	
	task.delay(1, function()
		for a=1, 4 do
			if targetCFrame == nil then continue end;

			local new = modAoeHighlight.newCylinder(timeToImpact+0.1);
			new.CFrame = targetCFrame;
			new.Size = Vector3.new(4, 4, 2);
			new.Parent = workspace.Entities;

			TweenService:Create(new, TweenInfo.new(timeToImpact, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Size = Vector3.new(impactRadius, impactRadius, 4)}):Play();

			local projectileObject = modProjectile.Fire("rpgRocket", self.JetPrimary.CFrame);
			projectileObject.TargetableEntities = {Humanoid=1; Zombie=1; Bandit=1; Rat=1;};
			
			local dmgRatio = 0.5;
			
			if self.Controller.Wave >= 10 then
				dmgRatio = 0.75;
			end
			projectileObject.Configurations.DamageRatio = dmgRatio;
			
			projectileObject.Configurations.ExplosionRadius = impactRadius/2;

			local velocity = projectileObject.ArcTracer:GetVelocityByTime(self.JetPrimary.Position, targetCFrame.Position, timeToImpact);
			modProjectile.ServerSimulate(projectileObject, self.JetPrimary.Position, velocity);

			task.wait(0.2);
			targetCFrame = modAoeHighlight:Ray(randomCFrame.Position + Vector3.new(0, 128, 0) - (randomDir*32*a), Vector3.new(0, -256, 0));
		end
	end)
end

function Hazard:End()
	self.JetPrefab.Parent = script;
end

return Hazard;
