local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local JailCell = Instance.new("Model");
JailCell.Name = "JailCell";
JailCell.Parent = script;
do
	local width = 10;
	local height = 20;
	local spacing = 5.37;
	local base = Instance.new("Part");
	base.Name = "Base";
	base.Anchored = true;
	base.CanCollide = false;
	base.Material = Enum.Material.Metal;
	base.BrickColor = BrickColor.new("Dark stone grey");
	base.TopSurface = Enum.SurfaceType.Smooth;
	base.BottomSurface = Enum.SurfaceType.Smooth;
	base.Size = Vector3.new(width+0.1, 0.3, width+0.1);
	base.Parent = JailCell;
	JailCell.PrimaryPart = base;
	
	local upper = Instance.new("Model");
	upper.Name = "UpperPart";
	upper.Parent = JailCell;
	
	local fakeBase = base:Clone();
	fakeBase.Name = "Base";
	fakeBase.CFrame = CFrame.new(0, 0, 0);
	fakeBase.Size = Vector3.new(0, 0.3, 0);
	fakeBase.Transparency = 1;
	fakeBase.Parent = upper;
	upper.PrimaryPart = fakeBase;
	
	local top = base:Clone();
	top.Name = "Top";
	top.CFrame = CFrame.new(0, height+0.4, 0);
	top.Size = Vector3.new(width+0.1, 0.8, width+0.1);
	top.Parent = upper;
	
	for a=1, 4 do
		local clip = base:Clone();
		clip.Name = "_playerClip";
		clip.Transparency = 1;
		clip.Size = Vector3.new(a <= 2 and width or 0.6, height, a >= 3 and width or 0.6);
		if a == 1 then
			clip.CFrame = CFrame.new(0, height/2, -width/2+0.35);
		elseif a == 2 then
			clip.CFrame = CFrame.new(0, height/2, width/2-0.35);
		elseif a == 3 then
			clip.CFrame = CFrame.new(width/2-0.35, height/2, 0);
		else
			clip.CFrame = CFrame.new(-width/2+0.35, height/2, 0);
		end
		clip.Parent = upper;
	end
	for x=0, 5 do
		local bar = base:Clone();
		bar.Name = "Bar";
		bar.Size = Vector3.new(0.6, height, 0.6);
		bar.CFrame = CFrame.new(-width/2+(width/spacing*x)+0.35, height/2, -width/2+0.35)
		bar.Parent = upper;
	end
	for x=1, 5 do
		local bar = base:Clone();
		bar.Name = "Bar";
		bar.Size = Vector3.new(0.6, height, 0.6);
		bar.CFrame = CFrame.new(-width/2+0.35, height/2, -width/2+(width/spacing*x)+0.35)
		bar.Parent = upper;
	end
	for x=1, 5 do
		local bar = base:Clone();
		bar.Name = "Bar";
		bar.Size = Vector3.new(0.6, height, 0.6);
		bar.CFrame = CFrame.new(-width/2+(width/spacing*x)+0.35, height/2, width/2-0.35)
		bar.Parent = upper;
	end
	for x=1, 4 do
		local bar = base:Clone();
		bar.Name = "Bar";
		bar.Size = Vector3.new(0.6, height, 0.6);
		bar.CFrame = CFrame.new(width/2-0.35, height/2, -width/2+(width/spacing*x)+0.35)
		bar.Parent = upper;
	end
end

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=2; AgentHeight=6;};
		
		Properties = {
			WalkSpeed = {Min=12; Max=20};
			AttackSpeed = 1;
			AttackDamage = 15;
			AttackRange = 5;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=15; Max=20};
			ExperiencePool=40;
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Properties.AttackCooldown = tick();
		self.Properties.LockUpCooldown = tick();
		
		if self.HardMode then
			self.Humanoid.MaxHealth = 143000 + ((#self.NetworkOwners-1) * 82000);
			self.Humanoid.Health = self.Humanoid.MaxHealth;
			self.Properties.AttackDamage = 30;
			self.Humanoid.WalkSpeed = 22;
		end
		self.Cells = {};
		
		self.LevelVisuals();
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
		end
	end);
	
	self.Logic:AddAction("LockUp", function()
		if self.Properties.LockUpCooldown == nil or tick()-self.Properties.LockUpCooldown > (self.HardMode and 0.5 or 5) then
			self.Properties.LockUpCooldown = tick();
		
			for a=1, #self.Enemies do
				local enemy = self.Enemies[a];
				local enemyHumanoid = enemy.Humanoid;
				local enemyRootPart = enemyHumanoid and enemyHumanoid.RootPart;
				if (enemyHumanoid.Health > 25 or self.HardMode) and enemyRootPart then
					spawn(function()
						
						local landingRay = Ray.new(enemyRootPart.Position, Vector3.new(0, -32, 0));
						local rayHit, rayPoint, rayNormal = workspace:FindPartOnRayWithWhitelist(landingRay, {workspace.Environment}, true);
						local cellPosition = Vector3.new(math.ceil(rayPoint.X/10)*10, math.ceil(rayPoint.Y), math.ceil(rayPoint.Z/10)*10);
						
						local exist = false;
						for a=1, #self.Cells do
							local oldCell = self.Cells[a];
							if oldCell:IsDescendantOf(workspace.Clips) then
								local oldPos = oldCell:GetPrimaryPartCFrame();
								if oldPos.X == cellPosition.X and oldPos.Z == cellPosition.Z then
									exist = true;
									break;
								end
							end
						end
						
						if not exist then
							local cell = JailCell:Clone();
							local cframeTag = Instance.new("CFrameValue", cell);
							local top = cell:WaitForChild("UpperPart");
							game.Debris:AddItem(cell, 15);
							game.Debris:AddItem(top, 15);
							cell.PrimaryPart.Size = Vector3.new(0, 0.3, 0);
							top.Parent = script;
							
							cell:SetPrimaryPartCFrame(CFrame.new(cellPosition+Vector3.new(0, 0.1, 0)));
							top:SetPrimaryPartCFrame(cell.PrimaryPart.CFrame*CFrame.new(0, 20, 0));
							cframeTag.Value = top:GetPrimaryPartCFrame();
							cframeTag:GetPropertyChangedSignal("Value"):Connect(function()
								if top.PrimaryPart then
									top:SetPrimaryPartCFrame(cframeTag.Value);
								end
							end)
							top.Parent = cell;
							table.insert(self.Cells, cell);
							cell.Parent = workspace.Clips;
							local timer = self.HardMode and 1 or 3;
							TweenService:Create(cell.PrimaryPart, TweenInfo.new(timer), {Size=Vector3.new(10, 0.3, 10)}):Play();
							wait(timer);
							
							local lifespan = self.HardMode and 8 or 5;
							game.Debris:AddItem(cell, lifespan);
							if cell.PrimaryPart then
								TweenService:Create(cframeTag, TweenInfo.new(0.2), {Value=cell.PrimaryPart.CFrame}):Play();
							end
						end
					end)
					break;
				end
			end
		end
	end);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then 
			for _, obj in pairs(self.Cells) do
				game.Debris:AddItem(obj, 0);
			end
			return false;
		end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 0.25);
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				end
				self.Logic:Action("LockUp");
			end
		else
			self.Follow();
		end
		self.NextTarget();
		self.Logic:Wait(0.1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
