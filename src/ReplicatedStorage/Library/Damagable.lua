local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local Damagable = {};
Damagable.__index = Damagable;

local RunService = game:GetService("RunService");

local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local remoteTryHookEntity = modRemotesManager:Get("TryHookEntity");
--==
Damagable.Dealer = {};
Damagable.DamageCategory = {
	Generic="Generic";
	Melee="Melee";
	AoE="Area Of Effect";
	Projectile="Projectile";

	FumesGas="Fumes Gas";
}

--==
local DamageSource = {};
DamageSource.__index = DamageSource;

function DamageSource:Clone()
	return setmetatable(table.clone(self), DamageSource);
end

function Damagable.NewDamageSource(data) -- Contains every detail about a damage.
	local self = data or {};
	
	setmetatable(self, DamageSource);
	return self;
end

function Damagable.NewDamagable(model)
	if model == nil then return end;
	
	if typeof(model) == "Instance" then
		if model:IsA("Accessory") then
			model = model.Parent;
			
		elseif model:IsA("Player") then
			model = model.Character;
			
		end
		
	elseif model.Prefab then
		model = model.Prefab;
		
	end

	if typeof(model) ~= "Instance" or not model:IsA("Model") then return end;
	while model:GetAttribute("EntityParent") do model = model.Parent; end -- Manual assign attribute guarantees parent is model.
	
	
	if RunService:IsServer() then
		local player = game.Players:GetPlayerFromCharacter(model);
		local classPlayer = player and shared.modPlayers.GetByName(player.Name);
		if classPlayer then
			return Damagable.new(model, classPlayer, classPlayer.Humanoid);
		end

		local npcStatus = model:FindFirstChild("NpcStatus");
		npcStatus = npcStatus and require(npcStatus) or nil;
		if npcStatus then
			return Damagable.new(model, npcStatus, npcStatus:GetHumanoid());
		end

		local humanoid = model:FindFirstChildWhichIsA("Humanoid");
		if humanoid and humanoid.Name ~= "NavMeshIgnore" and humanoid.Name ~= "Prop" and humanoid.Name ~= "Structure" then
			return Damagable.new(model, humanoid, humanoid);
		end

		while model:GetAttribute("DestructibleParent") do model = model.Parent; end
		
		local destructible = model:FindFirstChild("Destructible");
		destructible = destructible and require(destructible) or nil;
		if destructible then
			return Damagable.new(model, destructible, destructible);
		end
		
	else
		local humanoid = model:FindFirstChildWhichIsA("Humanoid");
		if humanoid and humanoid.Name ~= "NavMeshIgnore" and humanoid.Name ~= "Prop" and humanoid.Name ~= "Structure" then
			return Damagable.new(model, humanoid, humanoid);
		end
		
		while model:GetAttribute("DestructibleParent") do model = model.Parent; end
		local destructibleModule = model:FindFirstChild("Destructible");
		if destructibleModule then
			local destructibleProxy = setmetatable({
				ClassName="Destructible";
				Script=destructibleModule;
			}, {
				__index = function(t, k)
					if k == "Health" then
						return destructibleModule:GetAttribute("Health");
						
					elseif k == "MaxHealth" then
						return destructibleModule:GetAttribute("MaxHealth");
						
					end
					
					return;
				end;
			})
			
			return Damagable.new(model, destructibleProxy, destructibleProxy);
		end
	end

	return;
end

function Damagable:CanDamage(attacker)
	if attacker == Damagable.Dealer then
		return true;
	end
	
	if typeof(attacker) == "table" and attacker.ClassName == "Projectile" then
		local projectile = attacker;
		
		local netOwners = projectile.NetworkOwners or {};
		
		local exist = false;
		for a=1, #netOwners do
			if netOwners[a].Name == self.Object.Name then
				exist = true;
			end
		end
		if not exist then
			return false;
		end
	end
	
	local attackerNpcStatus = typeof(attacker) == "Instance" and attacker:FindFirstChild("NpcStatus") or nil;
	
	if self.Object.ClassName == "NpcStatus" then
		if self.Object:CanTakeDamageFrom(attacker) or (attackerNpcStatus ~= nil) then
			
		else
			return false;
		end
		
	elseif self.Object.ClassName == "Destructible" then
		local canDamage = false;
		if self.Object.NetworkOwners then
			for a=1, #self.Object.NetworkOwners do
				if self.Object.NetworkOwners[a] == attacker then
					canDamage = true;
					break;
				end
			end
		else
			canDamage = true;
		end
		if not canDamage then return false end;
		
	elseif self.Object.ClassName == "PlayerClass" then
		if attackerNpcStatus then
			local modNpcStatus = require(attackerNpcStatus);
			local modNpcModule = modNpcStatus.NpcModule;

			local canDamage = false;
			if modNpcModule.NetworkOwners then
				for a=1, #modNpcModule.NetworkOwners do
					if modNpcModule.NetworkOwners[a] == self.Object:GetInstance() then
						canDamage = true;
						break;
					end
				end
			else
				canDamage = true;
			end
			if not canDamage then return false end;
			
		elseif typeof(attacker) == "Instance" and attacker:IsA("Player") then
			if modConfigurations.TargetableEntities.Humanoid then
				return true;
			end
			
			local duelDmgMulti = bindIsInDuel:Invoke(attacker, self.Object.Name);

			if duelDmgMulti then

			else
				return false;
			end

		end
		
	end
	
	return true;
end

function Damagable:TakeDamage(damage, attacker, storageItem, part, damageType)
	
	if self.Object == nil then return end;
	self.Object:TakeDamage(damage, attacker, storageItem, part, damageType);
	
end

-- !outline: Damagable:TakeDamagePackage(package)
function Damagable:TakeDamagePackage(package)
	if self.Object == nil then return end;
	
	if typeof(self.Object) ~= "table" then
		Debugger:Warn("TakeDamagePackage attempted to be called on ", self.Model);
		return;
	end
	
	if typeof(self.Object) == "table" and self.Object.TakeDamagePackage then
		self.Object:TakeDamagePackage(package);
		
	else
		Debugger:Warn("deprecated obj TakeDamage implementation", debug.traceback());
		self.Object:TakeDamage(package.Damage, package.Dealer, package.ToolStorageItem, package.TargetPart, package.DamageType);
		
	end
	
	if package.Dealer and typeof(package.Dealer) == "Instance" and package.Dealer:IsA("Player") then
		if self.Model and self.Model:GetAttribute("EntityHudHealth") == true then
			remoteTryHookEntity:FireClient(package.Dealer, self.Model, 300);
		end
	end
end

-- !outline: Damagable:IsDead()
function Damagable:IsDead()
	if self.Object == nil then return end;

	if self.Object.ClassName == "NpcStatus" then
		local npcModule = self.Object:GetModule()
		return npcModule.IsDead;
		
	elseif self.Object.ClassName == "PlayerClass" then
		return not self.Object.IsAlive;
		
	end
	
	return true;
end


function Damagable.new(model, object, healthObj)
	local self = {
		Model = model;
		Object = object;
		HealthObj = healthObj;
	};
	
	setmetatable(self, Damagable);
	return self;
end

function Damagable:GetHealthChangedSignal()
	if self.Object.ClassName == "Humanoid" then
		return self.Object.HealthChanged;
		
	elseif self.Object.ClassName == "NpcStatus" then
		return self.Object.Humanoid.HealthChanged;

	elseif self.Object.ClassName == "Destructible" then
		return self.Object.Script:GetAttributeChangedSignal("Health");
		
	elseif self.Object.ClassName == "PlayerClass" then
		return self.Object.Humanoid.HealthChanged;
		
	end

	return;
end

function Damagable:GetHealthInfo()
	if self.Object.ClassName == "PlayerClass" then
		return self.Object:GetHealthInfo()
	end
	
	local info = {
		Health=self.HealthObj and self.HealthObj.Health or 0;
		MaxHealth=self.HealthObj and self.HealthObj.MaxHealth or 1;
		Armor=0;
		MaxArmor=0;
	}
	return info;
end

return Damagable;