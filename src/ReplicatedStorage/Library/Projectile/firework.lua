local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.rocket;
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local fireworksParticle = game.ReplicatedStorage.Particles.Fireworks;

local fireworkLightStatic;
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		LifeTime=10;
		Acceleration=Vector3.new(0, 296.2, 0);
	};
	
	projectile.Configurations = {
		ProjectileLifeTime=10;
		ProjectileAcceleration=Vector3.new(0, 296.2, 0);
	};
	
	function projectile:Activate()
		local Launch = projectile.Prefab:WaitForChild("Launch");
		Launch:Play();
		
		task.delay(random:NextNumber(0.3, 0.6), function() self:PopFirework(); end)
	end	
	
	function projectile:ProjectileDamage(hitObjects)
		hitObjects = type(hitObjects) == "table" and hitObjects or {hitObjects};
		for _, hitObj in pairs(hitObjects) do
			local damagable = modDamagable.NewDamagable(hitObj.Parent);
			if damagable then
				local model = damagable.Model;
				local damagableObj = damagable.Object;
				
				local damage = 100;
				
				if damagableObj.ClassName == "NpcStatus" then
					local npcModule = damagableObj:GetModule();
					local humanoid = npcModule.Humanoid;
					local dmgMulti = self.TargetableEntities[humanoid.Name];
					
					if dmgMulti then
						damage = damage * dmgMulti;
					else
						damage = 0;
					end
					
				end
				
				if damage ~= 0 then
					if damagable:CanDamage(self.Owner) then
						modDamageTag.Tag(model, self.Owner.Character);
						
						local newDmgSrc = modDamagable.NewDamageSource{
							Damage=damage;
							Dealer=self.Owner;
							ToolStorageItem=self.StorageItem;
							TargetPart=hitObj;
							DamageType="ExplosiveDamage";
						}
						damagable:TakeDamagePackage(newDmgSrc);
					end
				end
				
			end
			
		end
	end
	
	function projectile:PopFirework()
		if self.Popped then return end;
		self.Popped = true;

		self.Prefab.Transparency = 1;
		
		local Pop2 = self.Prefab:WaitForChild("Pop2");
		Pop2:Play();
		local Bang4 = self.Prefab:WaitForChild("Bang4");
		Bang4:Play();

		local newPar = fireworksParticle:Clone();
		local colorPattlet = {
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 4))};
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 255) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))};
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 234) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 234))};
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 226, 0) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 226, 0))};
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 247) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 247))};
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 93, 0) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 93, 0))};
			{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 8) ); ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 8))};
		};
		local pickedColor = colorPattlet[math.random(1,#colorPattlet)];
		
		newPar.Color = ColorSequence.new(pickedColor);
		newPar.Speed = NumberRange.new(random:NextNumber(20, 50));
		newPar.Lifetime = NumberRange.new(random:NextNumber(3, 8));
		newPar.Parent = self.Prefab;
		
		if fireworkLightStatic then
			fireworkLightStatic:Destroy();
		end
		local light = Instance.new("PointLight");
		light.Color = pickedColor[1].Value;
		light.Range = 60;
		light.Brightness = 1;
		light.Shadows = false;
		light.Parent = self.Prefab;
		fireworkLightStatic = light;
		
		newPar:Emit(math.random(64, 256));
		game.Debris:AddItem(self.Prefab, 2);
	end
	
	
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit then
			if RunService:IsServer() then
				if CollectionService:HasTag(arcPoint.Hit, "Flammable") then
					local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
					modFlammable:Ignite(arcPoint.Hit);
				end
				
				if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
				if self.ProjectileDamage then
					self:ProjectileDamage(arcPoint.Hit);
				end
				
				return self.Popped;
			else
				
				local targetModel = arcPoint.Hit.Parent;
				local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
				if humanoid then
					modAudio.Play(random:NextInteger(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab).MaxDistance = 1024;
				end
			end
		end
	end
	
	return projectile;
end

return Pool;