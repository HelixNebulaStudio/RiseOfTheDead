local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local ZombieModule = script.Parent.Zombie;
local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			WalkSpeed={Min=4; Max=6};
			AttackSpeed=2;
			AttackDamage=25;
			AttackRange=7;
			TargetableDistance=70;
		};
		
		Configuration = {
			Level=10;
			MoneyReward={Min=13; Max=15};
			ExperiencePool=35;
			ResourceDrop=modRewardsLibrary:Find("zombie");
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Wield.Targetable = {Humanoid = 1;};
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent("Logic");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead then return false; end;
		
--		for a=1, #self.Enemies do
--			local EnemyModule = self.Enemies[a];
--			if EnemyModule.Humanoid and EnemyModule.Humanoid.Health > 0 and EnemyModule.RootPart and (EnemyModule.RootPart.Position - self.RootPart.Position).Magnitude <= 40 then
--				EnemyModule:UpdateDropReward(modRewardsLibrary:Find("michaelkills"));
--				self.Wield.SetEnemyHumanoid(EnemyModule.Humanoid);
--				self.Movement:Face(EnemyModule.RootPart.Position);
--				self.Wield.PrimaryFireRequest();
--				break;
--			end
--		end
--		
--		self.Wield.Equip("tec9");
		
		wait(1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	self.Garbage:Tag(self.Humanoid.Running:Connect(function(speed) self.Properties.Speed = speed; end));
	
return self end
