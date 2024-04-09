local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local Destructibles = {};
Destructibles.__index = Destructibles;
Destructibles.ClassName = "Destructible";

local RunService = game:GetService("RunService");

local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modModEngineService = require(game.ReplicatedStorage.Library.ModEngineService);

local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

function Destructibles:TakeDamagePackage(damageSource)
	local damage = damageSource.Damage;
	local dealer = damageSource.Dealer;
	local storageItem = damageSource.ToolStorageItem;
	local hitPart = damageSource.TargetPart;
	local damageType = damageSource.DamageType;
	
	if not self.Enabled then Debugger:Log(self.Prefab," Distructible not enabled.") return false end;

	if self.DamagableBy then
		if dealer == nil then return end;

		local humanoid = dealer:FindFirstChildWhichIsA("Humanoid");
		if humanoid == nil or self.DamagableBy[humanoid.Name] == nil then
			return;
		end
	end

	if self.DamageModifier then
		damage, dealer, storageItem, hitPart, damageType = self:DamageModifier(damage, dealer, storageItem, hitPart, damageType);
	end

	self:SetHealth(self.Health - (damage or 0));

	if self.Humanoid then self.Humanoid.Health = self.Health; end
	if self.OnDamaged then self.OnDamaged(damage, dealer, storageItem, hitPart, damageType); end

	if self.CustomDestroy ~= true and self.Health <= 0 and not self.Destroyed then
		self:SetDestroyed(true);
		
		modOnGameEvents:Fire("OnDestructibleDestroy", self, dealer, storageItem);
		self.OnDestroySignal:Fire(dealer, storageItem);

		local respawnAtt = self.Prefab:GetAttribute("Respawn");
		if respawnAtt then
			if self.RespawnPrefab == nil then
				self.RespawnPrefab = self.Prefab:Clone();
			end

			local respawnTime = math.random(respawnAtt.Min*10, respawnAtt.Max*10)/10
			task.delay(respawnTime, function()
				local parent = self.Prefab.Parent;
				game.Debris:AddItem(self.Prefab, 0);

				local new = self.RespawnPrefab:Clone();
				new.Parent = parent;
			end)
		end

		if self.OnDestroy then
			self:OnDestroy(hitPart);
		end
		if self.RewardId then
			local resourceTable = modRewardsLibrary:Find(self.RewardId);
			if resourceTable then
				local cframe = self.Prefab:GetPrimaryPartCFrame();

				local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
				local itemDrop = modItemDrops.ChooseDrop(resourceTable);
				if itemDrop then
					modItemDrops.Spawn(itemDrop, cframe);
				end
			end
		end
	end

	if dealer and dealer:IsA("Player") then
		if hitPart then
			if damageType == "Hidden" then
			elseif damage >= 1 then

				modInfoBubbles.Create{
					Players={dealer};
					Position=hitPart.Position;
					Type=(damageType or "Damage");
					Value=damage;
				};

			elseif damage <= -1 then
				modInfoBubbles.Create{
					Players={dealer};
					Position=hitPart.Position;
					Type="Heal";
					Value=math.abs(damage);
				};

			else
				modInfoBubbles.Create{
					Players={dealer};
					Position=hitPart.Position;
					Type="Immune";
				};

			end
		end

	end

	return true;
end

function Destructibles:SetEnabled(v)
	self.Enabled = v;
	if self.OnEnableChange then
		self:OnEnableChange();
	end
end
	
function Destructibles:SetHealth(health, maxhealth)
	if maxhealth then self.MaxHealth = maxhealth; end;
	self.Health = math.clamp(health, 0, self.MaxHealth);
	
	if self.Script then
		self.Script:SetAttribute("Health", self.Health);
		if maxhealth then
			self.Script:SetAttribute("MaxHealth", self.MaxHealth);
		end
	end
end

function Destructibles.new(model, class)
	local self = {
		Enabled = true;
		Destroyed = false;
		
		Health = 100;
		MaxHealth = 100;
		
		DamagableBy=nil;
		
		Humanoid = nil;
		Prefab = model;
		Name = class or model.Name;
		Script = model:FindFirstChild("Destructible");
		
		OnDestroySignal = modEventSignal.new("OnDestroy");
	};
	
	setmetatable(self, Destructibles);
	
	if model:FindFirstChild("Structure") and model["Structure"]:IsA("Humanoid") then
		self.Humanoid = model["Structure"];
		self.MaxHealth = self.Humanoid.MaxHealth;
		self.Health = self.MaxHealth;
	end
	
	if RunService:IsServer() then
		if model:FindFirstChild("NavMeshIgnore") == nil then
			local navmeshIgnore = Instance.new("Humanoid");
			navmeshIgnore.Name = "NavMeshIgnore";
			navmeshIgnore:SetStateEnabled(Enum.HumanoidStateType.Dead, false);
			navmeshIgnore.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
			navmeshIgnore.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
			navmeshIgnore.Parent = model;
		end
	end

	if class then
		local loadClassFunc = script:FindFirstChild(class) and require(script[class]) or nil;
		
		local moddedSelf = modModEngineService:GetServerModule(script.Name);
		if moddedSelf and loadClassFunc == nil then
			loadClassFunc = moddedSelf.Script:FindFirstChild(class) and require(moddedSelf.Script[class]) or nil;
		end
		
		if loadClassFunc then
			loadClassFunc(self);

		end
	end
	
	self:SetHealth(self.Health, self.MaxHealth);
	return self;
end

function Destructibles:DestroyExplode(min, max)
	min = min or 35;
	max = max or 45;
	
	for _, obj in pairs(self.Prefab:GetDescendants()) do
		if obj:IsA("JointInstance") then
			obj:Destroy();

		elseif obj:IsA("BasePart") then
			obj.Anchored = false;

			if obj ~= self.Prefab.PrimaryPart then
				obj.Velocity = (obj.Position - self.Prefab.PrimaryPart.Position).Unit * math.random(min*10, max*10)/10;
			else
				local v = math.random(min*10, max*10)/10;
				obj.Velocity = Vector3.new(math.random(-v*10, v*10)/10, v, math.random(-v*10, v*10)/10);
			end

		end
	end
end

function Destructibles:SetDestroyed(v)
	self.Destroyed = v;
	if self.Prefab then
		self.Prefab:SetAttribute("Destroyed", v);
	end
end

return Destructibles;
