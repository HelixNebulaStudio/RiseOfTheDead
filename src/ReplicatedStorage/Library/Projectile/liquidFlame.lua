local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local Projectile = require(script.Parent.Projectile);

local flamePrefab = script.Flame;
local random = Random.new();

local fireParticle = game.ReplicatedStorage.Particles.Fire:Clone();
local fireParticle2 = game.ReplicatedStorage.Particles.Fire2:Clone();
fireParticle2.Parent = flamePrefab;

--== Script;
function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = flamePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=50;
		LifeTime=10;
		Bounce=0;
		Acceleration=Vector3.new(0, -workspace.Gravity/16, 0);
		KeepAcceleration = true;
		IgnoreEntities=false;
		AddIncludeTags={"LiquidFlame"};
	};
	
	local particles = projectile.Prefab:WaitForChild("Fire2");
	
	local statusKey = script.Name;
	function projectile:OnEnemyHit(hit, damagable, player, weaponItem)
		local configurations = self.WeaponModule and self.WeaponModule.Configurations or {};
		local damage = (configurations.Damage or 1);

		local damagableObj = damagable.Object;
		
		self.DamageSource.Damage = damage;
		self.DamageSource.DamageType = "FireDamage";
		self.DamageSource.TargetPart = hit;
		
		if damagableObj.ClassName == "NpcStatus" then
			local npcStatus = damagableObj;

			local npcModule = npcStatus:GetModule();
			local entityStatus = npcModule.EntityStatus;
			
			local dmgMulti = self.TargetableEntities[npcStatus.Name];
			
			if dmgMulti and npcStatus:CanTakeDamageFrom(player) then
				if entityStatus:GetOrDefault(statusKey) == nil then
					entityStatus:Apply(statusKey, 1);
					
					spawn(function()
						local new;
						
						if self.Owner then
							new = fireParticle2:Clone();
							new.Name = "FlameModFire";
							new.Parent = hit;
						end
						
						local humanoid = npcStatus.NpcModule and npcStatus.NpcModule.Humanoid;
						
						local c = 0;
						local laststacks = 0;
						repeat
							local stacks = entityStatus:GetOrDefault(statusKey);
							if laststacks ~= stacks then
								laststacks = stacks;
								c = 0;
							end;
							local damage = damage + (damage*math.clamp(stacks or 0, 0, 100));
							
							local dmgSrc = self.DamageSource:Clone();
							dmgSrc.Damage = damage;
							damagable:TakeDamagePackage(dmgSrc);
							
							c = c +1;
							task.wait(0.5);
						until humanoid == nil or humanoid.Health <= 0 or c >= 10;
						
						entityStatus:Apply(statusKey);
						new:Destroy();
					end)
				else
					entityStatus:Apply(statusKey, entityStatus:GetOrDefault(statusKey)+1);
				end
			else
				damage = 0;	
			end
			
		elseif damagableObj.ClassName == "Destructible" and damagableObj.Enabled then
			for a=1, 10 do
				damagable:TakeDamagePackage(self.DamageSource);
				
				task.wait(0.5);
				if damagableObj.Health <= 0 then break; end;
			end
			
		elseif damagableObj.ClassName == "PlayerClass" then
			local damagablePlayer = damagableObj:GetInstance();
			if damagablePlayer and damagable:CanDamage(player) then
				modStatusEffects.Burn(damagablePlayer, 50, 5);
			end;
			
		end
		
		if damage and damage > 0 then
			damagable:TakeDamagePackage(self.DamageSource);
			
			local oldDespawnTime = self.Prefab:GetAttribute("DespawnTime");
			self.Prefab:SetAttribute("DespawnTime", oldDespawnTime-0.1);
			if tick() > oldDespawnTime then
				self.Prefab:Destroy();
				Debugger.Expire(self.Prefab);
			end
		end
		
	end;

	function projectile:Activate()
		local configurations = self.WeaponModule and self.WeaponModule.Configurations or {};
		
		local despawnTime = projectile.ArcTracerConfig.LifeTime + (configurations.EverlastDuration or 0);
		self.Prefab:SetAttribute("DespawnTime", tick()+despawnTime);
		
		if math.random(1, 3) == 1 then
			task.delay(random:NextNumber(0, 0.2), function()
				local sound = modAudio.Play("Fire", self.Prefab, true);
				sound.Volume = random:NextNumber(0.1, 0.3);
			end);
		end;
		particles.LockedToPart = true;
		particles:Emit(4);

		local att = Instance.new("Attachment");
		att.Name = "FireAtt";
		fireParticle:Clone().Parent = att;
		att.Parent = self.Prefab;
	end	
	
	local activated = false;
	function projectile:OnContact(arcPoint)
		if RunService:IsClient() then return end; -- potential crash point below
		
		local hitPart = arcPoint.Hit;

		local touched = {};

		local function onFlameTouch(hitPart)
			if hitPart == nil then return end;
			if RunService:IsClient() then return end; -- old;
			if hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) then Debugger.Expire(self.Prefab); return end;

			local damagable = modDamagable.NewDamagable(hitPart.Parent);
			if damagable then
				local model = damagable.Model;
				for a=1, #touched do
					if touched[a] == model then
						return;
					end
				end

				table.insert(touched, model);
				if projectile.ProjectileDamage then projectile:ProjectileDamage(damagable, hitPart); end
			end
		end
		
		if CollectionService:HasTag(hitPart, "Flammable") then
			local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
			modFlammable:Ignite(hitPart);
		end
		
		if hitPart and hitPart.Anchored ~= true then
			onFlameTouch(hitPart);
			return;
		end
		
		if activated then return end;
		activated = true;
		
		particles.LockedToPart = false;
		
		local landingCframe = CFrame.new(self.Prefab.CFrame.Position);
		local newSize = Vector3.new(2, 2, 2);
		
		self.Prefab.Size = newSize;
		self.Prefab.CFrame = landingCframe;
		self.Prefab.Transparency = 1;
		
		if hitPart == nil then return end;
		
		local newFlame = hitPart;
		

		if not newFlame:HasTag("LiquidFlame") then
			local overlapParam = OverlapParams.new();
			overlapParam.FilterDescendantsInstances = CollectionService:GetTagged("LiquidFlame");
			overlapParam.FilterType = Enum.RaycastFilterType.Include;
			overlapParam.MaxParts = 1;
			
			local hitList = workspace:GetPartBoundsInBox(landingCframe, newSize*1.5, overlapParam);
			
			if #hitList > 0 then
				newFlame = hitList[1];
			end
		end
		
		if newFlame:HasTag("LiquidFlame") then
			newFlame:SetAttribute("DespawnTime", self.Prefab:GetAttribute("DespawnTime"));
			
			local newSize = newFlame.Size.X+0.5;
			newFlame.Size = Vector3.new(math.clamp(newSize, 2, 4), 2, math.clamp(newSize, 2, 4))
			
			local flames = newFlame:GetChildren();
			if #flames <= 4 then
				local oldFireAtt = self.Prefab.FireAtt;
				oldFireAtt.Parent = newFlame;
				oldFireAtt.WorldCFrame = CFrame.new(landingCframe.X, newFlame.Position.Y, landingCframe.Z);
				
				if oldFireAtt:FindFirstChild("Fire") then
					oldFireAtt.Fire.Size = math.clamp(oldFireAtt.Fire.Size +1, 3, 12);
				end
				
			else
				local fireAtt = nil;
				for a=1, #flames do
					if flames[a].Name == "FireAtt" then
						fireAtt = flames[a];
						break;
					end
				end
				
				fireAtt.WorldCFrame = CFrame.new(landingCframe.X, newFlame.Position.Y, landingCframe.Z);

				if fireAtt:FindFirstChild("Fire") then
					fireAtt.Fire.Size = math.clamp(fireAtt.Fire.Size +1, 3, 12);
				end
				
			end

			Debugger.Expire(self.Prefab);
			
		else
			local onTouch;
			onTouch = self.Prefab.Touched:Connect(onFlameTouch)
			onFlameTouch(hitPart);
			
			self.Prefab:AddTag("LiquidFlame");
		end
		
	end
	
	function projectile:ProjectileDamage(damagable, hitPart)
		if self.Owner and hitPart:IsDescendantOf(self.Owner) then return end;
		
		local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
		
	 	task.spawn(function()
			if self.Owner then
				if damagable:CanDamage(self.Owner) then
					modTagging.Tag(damagable.Model, self.Owner and self.Owner:IsA("Player") and self.Owner.Character);
					self:OnEnemyHit(hitPart, damagable, self.Owner, self.StorageItem);
				end
			else
				self:OnEnemyHit(hitPart, damagable, nil, self.StorageItem);
			end
		end);
	end
	
	return projectile;
end

return Pool;
