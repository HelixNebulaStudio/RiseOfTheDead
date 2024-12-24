local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local ZombieModule = script.Parent.Zombie;
--== Modules
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Zombie");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		PathAgent = {AgentRadius=1; AgentHeight=4;};
		
		AggressLevel = 0;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=12; Max=16};
			AttackSpeed=2;
			AttackDamage=10;
			AttackRange=6;
			TargetableDistance=50;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=20;
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Immunity = 1;

		self.Humanoid.MaxHealth = 100 + 20*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Properties.AttackDamage = 10 + 3*(self.Configuration.Level-1);
		
		self.Properties.AttackCooldown = tick();
		self.Movement:SetWalkSpeed("default", 12);
		
		self.BodyLayer:AddLayer("Zombie");
		
		self.Think:Fire();
		
		local oilGrid = {};
		local lastOilProjObj;
		while not self.IsDead do 
			task.wait(1); 
		
			local origin = self.RootPart.CFrame;

			local gridKey = `{math.round(origin.X/4)*4};{math.round(origin.Y/8)*8};{math.round(origin.Z/4)*4}`;
			if oilGrid[gridKey] and tick()-oilGrid[gridKey] <= 10 then continue end;
			oilGrid[gridKey] = tick();

			local projectileObject = modProjectile.Fire("Gasoline", origin, Vector3.new(0, -1, 0));
			if projectileObject.Prefab then
				projectileObject.Prefab.Color = Color3.fromRGB(103, 0, 62);
				projectileObject.Prefab.Transparency = 0;
				lastOilProjObj = projectileObject.Prefab;
			end

			local spreadLookVec = modMath.CFrameSpread(-Vector3.yAxis, 90);

			modProjectile.ServerSimulate(projectileObject, origin.p, spreadLookVec * 20);
		end

		task.wait(0.2);
		if lastOilProjObj then
			if lastOilProjObj:HasTag("Flammable") then
				local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
				modFlammable:Ignite(lastOilProjObj);
			end
		end
	end
	
	function self.OnFlammableIgnite()
		if self.Ignited then return end;
		self.Ignited = true;
		self.Immunity = nil;

		for _, obj in pairs(self.Prefab:GetChildren()) do
			if obj:GetAttribute("BodyLayer") ~= true then continue end;
			if obj:FindFirstChild("Fire") then continue end;

			local newFire = Instance.new("Fire");
			newFire.Parent = obj;
		end
	end

	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("BehaviorTree");
	self:AddComponent("BodyLayer");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack2);
	self:AddComponent(ZombieModule.Idle);
	
	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("ZombieTree", true);
	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
