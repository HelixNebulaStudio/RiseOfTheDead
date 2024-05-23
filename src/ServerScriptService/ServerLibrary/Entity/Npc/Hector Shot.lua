local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modAoeHighlight = require(game.ReplicatedStorage.Particles.AoeHighlight);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Bandit");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			WalkSpeed={Min=16; Max=20};
			AttackSpeed=2;
			AttackDamage=1;
			AttackRange={Min=16; Max=32};
			TargetableDistance=512;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=130; Max=180};
			ExperiencePool=35;
			Audio={Hurt=false;};
		};
		
		VisionDistance=128;
	};
	
	self.LassoDialogues = {
		"Yeeeeehaw!";
		"Y'all need to start running!";
		"C'mon now!";
	}
	
	self.SpottedDialogues = {
		"Look who do we have here!";
		"I see you!";
		"Peeka boo, I see you!";
		"Look what we got here!";
	}
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackCooldown = tick();
		
		self.Wield.Equip("revolver454");
				
		self.Wield.Targetable.Humanoid = 1;
		self.Wield.Targetable.Destructible = 500;
		
		--==
		self.StagePoints = self.Arena and self.Arena:WaitForChild("StageElement"):GetChildren() or {};
		self.LassoRange = 45;
		self.LassoTime = 2.2;
		self.LassoCooldown = 10;
		self.LassoTimer = tick();
		
		self.HuntDuration = 10;
		self.State = "Search";
		self.SearchPoint = nil;
		self.HuntTimer = tick();
		self.FieldOfView = 60;
		
		if self.HardMode then
			self.Humanoid.MaxHealth = 98000 + ((#self.NetworkOwners-1) * 66000);
			self.Humanoid.Health = self.Humanoid.MaxHealth;
			self.LassoRange = 50;
			self.LassoTime = 1;
			self.LassoCooldown = 5;
			self.FieldOfView = 89;
			self.KnockbackResistant = true;
		end
		
		repeat until not self.Update();
		game.Debris:AddItem(self.Indicator, 0);
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("CrateReward");
	self:AddComponent("Wield");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(BanditModule.OnTarget);
	self:AddComponent(BanditModule.Idle);
	
	--== NPC Logic;
	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
	
	function self.OnDamagedEvent(character)
		if self.State == "Search" and (tick()-self.LassoTimer) >= self.LassoCooldown then
			self.State = "Lasso";
			if character and character.PrimaryPart then
				if self.HardMode then
					self.Humanoid.WalkSpeed = 20;
					self.Follow(character.PrimaryPart, 6);
					wait(4);
				else
					self.Movement:Face(character.PrimaryPart.Position);
				end
			end
		end
	end
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		local followGap = random:NextNumber(self.Properties.AttackRange.Min, self.Properties.AttackRange.Max);
		
		local function scanForVictims()
			for a=1, #self.Enemies do
				local character = self.Enemies[a].Character;
				if character.PrimaryPart then
					local distance = self.Actions:DistanceFrom(character.PrimaryPart.Position);
					if distance < 18 then
						self.Movement:Face(character.PrimaryPart.Position);
						return true;
					end
					local player = game.Players:FindFirstChild(character.Name);
					local isVisible, opacity = self.IsInVision(character.PrimaryPart, self.FieldOfView);
					isVisible = isVisible and opacity > 0.3;
					
					if isVisible then
						self.Movement:EndMovement();
						self.Movement:Face(character.PrimaryPart.Position);
						
						if distance > self.LassoRange-5 then
							self.Humanoid.WalkSpeed = 18;
							self.Follow(character.PrimaryPart, 10);
							wait(2);
						end
						
						return true;
					end
				end
			end
		end
		
		if self.State == "Search" then
			self.Immunity = 0;
			
			if self.Wield.ToolModule == nil then
				self.Wield.Equip("revolver454");
			end
			
			if (self.SearchPoint == nil or self.HardMode) and self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
				self.Humanoid.WalkSpeed = 9;
				self.Follow(self.Enemy.Humanoid.RootPart, 10, 10);
				
			else
				self.Humanoid.WalkSpeed = 7;
				if self.Movement.IsFollowing then
					self.Follow();
					wait(0.2);
				end
				if not self.Movement.IsMoving then
					self.Movement:Move(self.SearchPoint.Position);
				end
				
			end
			
			if scanForVictims() then
				self.Chat(self.NetworkOwners, self.SpottedDialogues[math.random(1, #self.SpottedDialogues)]);
				self.State = "Lasso";
			end
			
			if self.SearchPoint and self.Actions:DistanceFrom(self.SearchPoint.Position) < 3 then
				self.SearchPoint = #self.StagePoints > 0 and self.StagePoints[math.random(1, #self.StagePoints)] or nil;
			end
			
		elseif self.State == "Lasso" then
			self.Immunity = 1;
			self.Wield.Unequip();
			self.CanBlink = false;
			wait(0.5);
			
			if self.IsDead or self.Humanoid.RootPart == nil then return false end;
			self.Movement:EndMovement();
			self.Humanoid.WalkSpeed = 0;
			self.Wield.Equip("lasso");
			self.Wield.PrimaryFireRequest();
			
			self.Chat(self.NetworkOwners, self.LassoDialogues[math.random(1, #self.LassoDialogues)]);
					
			self.Indicator = modAoeHighlight.newSphere(self.LassoTime);
			self.Indicator.Parent = workspace.Debris;
			task.spawn(function()
				while self.Indicator.Parent == workspace.Debris do
					self.Indicator.Position = self.RootPart.Position;
					task.wait();
				end
			end)
			
			TweenService:Create(
				self.Indicator,  
				TweenInfo.new(self.LassoTime), 
				{Size=Vector3.new(self.LassoRange*2, self.LassoRange*2, self.LassoRange*2)}
			):Play();

			task.wait(self.LassoTime);

			if self.IsDead or self.Humanoid.RootPart == nil then return false end;
			
			self.Wield.Unequip();
			self.LassoVictims = {};
			for a=1, #self.Enemies do
				local character = self.Enemies[a].Character;
				local player = game.Players:FindFirstChild(character.Name);
				
				if player and character.PrimaryPart and self.Actions:DistanceFrom(character.PrimaryPart.Position) < (self.LassoRange-4) then
					modStatusEffects.TiedUp(player, 5);
					
					table.insert(self.LassoVictims, character);
				end
			end
			self.CanBlink = nil;
			
			if #self.LassoVictims > 0 then
				self.HuntDuration = 10 + (#self.LassoVictims-1)*5;
				self.State = "Hunt";
				self.HuntTimer = tick();
			else
				self.State = "Search";
			end
			self.Immunity = 0;
			self.LassoTimer = tick();
			
		elseif self.State == "Hunt" and tick()-self.HuntTimer < self.HuntDuration then
			self.Humanoid.WalkSpeed = 16;
			self.Immunity = 0;
			
			if self.Wield.ToolModule == nil then
				self.Wield.Equip("revolver454");
				pcall(function()
					self.Wield.ToolModule.Configurations.MinBaseDamage = self.HardMode and 180 or 95;
				end);
			end
			
			if self.HuntTarget == nil then
				for a=1, #self.LassoVictims do
					local character = self.LassoVictims[a];
					local humanoid = character:FindFirstChildWhichIsA("Humanoid");
					
					if character and character.PrimaryPart and humanoid and humanoid.Health > 0 then
						self.Follow(character.PrimaryPart, 10, 10);
						self.HuntTarget = {Index=a; Character=character; Humanoid=humanoid};
						self.Wield.OnWieldHit = nil;
					end
				end
			else
				if self.Wield.ToolModule and not self.Wield.ToolModule.Properties.Reloading 
				and self.IsInVision(self.HuntTarget.Humanoid.RootPart) then
					if self.Wield.OnWieldHit == nil then
						self.Wield.OnWieldHit = function(model)
							if model == self.HuntTarget.Character then
								table.remove(self.LassoVictims, self.HuntTarget.Index);
								self.Follow();
								self.HuntTarget = nil;
							end
						end
					end
					
					self.Wield.SetEnemyHumanoid(self.HuntTarget.Humanoid);
					self.Movement:Face(self.HuntTarget.Humanoid.RootPart.Position);
					wait(0.2);
					self.Wield.PrimaryFireRequest();
				end
			end
			
			if #self.LassoVictims <= 0 or tick()-self.HuntTimer >= self.HuntDuration then
				self.Wield.ReloadRequest();
				wait(2);
				if scanForVictims() then
					self.State = "Lasso";
				else
					self.State = "Search";
				end
			end
		else
			self.State = "Search";
		end
		
		self.Logic:Wait(0.2);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
