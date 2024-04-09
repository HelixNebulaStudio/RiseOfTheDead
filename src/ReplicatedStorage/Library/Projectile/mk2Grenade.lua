local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modExplosionHandler = require(game.ReplicatedStorage.Library.ExplosionHandler);

local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.Grenade;
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=100;
		Bounce=0.6;
		LifeTime=20;
		MaxBounce=8;
	}
	
	function projectile:Activate()
		task.delay(self.Configurations.DetonateTimer, function()
			modAudio.Play(random:NextInteger(1,2)==1 and "Explosion" or "Explosion2", self.Prefab);
			self.Prefab.Transparency = 1;

			if not RunService:IsServer() then return end;
			local lastPosition = self.Prefab.Position;
			
			local ex = Instance.new("Explosion");
			ex.DestroyJointRadiusPercent = 0;
			ex.BlastRadius = 35;
			ex.BlastPressure = 0;
			ex.Position = lastPosition;
			ex.Parent = workspace;
			Debugger.Expire(ex, 1);
			self.Prefab.Transparency = 1;
			
			
			local hitLayers = modExplosionHandler:Cast(lastPosition, {
				Radius = self.Configurations.ExplosionRadius;
			});

			local damage = self.Configurations.Damage;
			local minDamage = self.Configurations.MinDamage;
			local explosionStun = self.Configurations.ExplosionStun;
			local damageRatio = self.Configurations.DamageRatio;

			modExplosionHandler:Process(lastPosition, hitLayers, {
				OnPartHit=function(hitPart)
					if hitPart.Anchored then return end
					if not workspace.Environment:IsAncestorOf(hitPart) then return end;


					local rootModel = hitPart;
					while rootModel:GetAttribute("DynamicPlatform") == nil do
						rootModel = rootModel.Parent;
						if rootModel == workspace or rootModel == game then break; end
					end
					if rootModel:GetAttribute("DynamicPlatform") then return end;


					local assemblyRootPart = hitPart:GetRootPart();
					if assemblyRootPart and assemblyRootPart.Anchored ~= true then
						assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*30;
					end
				end;

				Owner = self.Owner;
				StorageItem = self.StorageItem;
				TargetableEntities = projectile.TargetableEntities;

				Damage = damage;
				MinDamage = minDamage;
				ExplosionStun = explosionStun;
				DamageRatio = damageRatio;
			});
			
			
			--local hitList = {};
			--local explosionHitConnect = ex.Hit:Connect(function(hitPart, distance)
			--	table.insert(hitList, {Part=hitPart; Distance=distance});
			--end)
			
			--task.wait()
			--explosionHitConnect:Disconnect();
			
			--local partsAffected = {};
			--for a=1, #hitList do
				
			--	local humanoid = hitList[a].Part and hitList[a].Part.Parent and hitList[a].Part.Parent:FindFirstChildWhichIsA("Humanoid");
			--	if humanoid then
			--		local ignore = false;
			--		for b=1, #partsAffected do
			--			if partsAffected[b].Parent == hitList[a].Part.Parent then
			--				ignore = true;
			--				break;
			--			end;
			--		end
			--		if not ignore then
			--			if (self.Owner == nil or humanoid.Parent.Name ~= self.Owner.Name) then
			--				table.insert(partsAffected, hitList[a].Part);
			--			end
			--		end
			--	else
			--		if hitList[a].Part and not hitList[a].Part.Anchored and hitList[a].Part:IsDescendantOf(workspace.Environment) then
			--			local rootModel = hitList[a].Part;

			--			while rootModel:GetAttribute("DynamicPlatform") == nil do
			--				rootModel = rootModel.Parent;
			--				if rootModel == workspace or rootModel == game then break; end
			--			end

			--			if rootModel:GetAttribute("DynamicPlatform") == nil then
			--				local assemblyRootPart = hitList[a].Part:GetRootPart();
			--				if assemblyRootPart and assemblyRootPart.Anchored ~= true then
			--					assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*30;
			--				end
			--			end
			--		end
			--	end
			--end
			--if self.ProjectileDamage then self:ProjectileDamage(partsAffected, lastPosition); end
		end)
	end	
	
	--function projectile:ProjectileDamage(hitObjects, epicenter)
	--	local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
		
	--	hitObjects = type(hitObjects) == "table" and hitObjects or {hitObjects};
	--	for _, hitObj in pairs(hitObjects) do
	--		local targetModel = hitObj.Parent;
	--		local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
	--		local dmgMulti = humanoid and self.TargetableEntities[humanoid.Name];
			
	--		if targetModel then
	--		--== Duel
	--		local duelDmgMulti = bindIsInDuel:Invoke(self.Owner, humanoid.Parent.Name);
	--		if duelDmgMulti then dmgMulti = duelDmgMulti end;
	--		--== Duel
	--		end
			
	--		if humanoid and dmgMulti then
	--			modTagging.Tag(targetModel, self.Owner.Character);
	--			humanoid = (targetModel:FindFirstChild("NpcStatus") and require(targetModel.NpcStatus)) or humanoid;
				
	--			if humanoid.ClassName == "NpcStatus" and not humanoid:CanTakeDamageFrom(self.Owner) then
	--				return;
	--			end
				
	--			local damage = math.clamp(self.Configurations.DamagePercent * humanoid.MaxHealth, 100, Projectile.MaxDamage);
	--			damage = damage*dmgMulti;
	--			humanoid:TakeDamage(damage, self.Owner, self.StorageItem, hitObj, "ExplosiveDamage");
				
	--			hitObj.Velocity = (hitObj.Position-epicenter).Unit*30 + Vector3.new(0, 40, 0);
	--		end
	--	end
	--end
	
	function projectile:OnContact(arcPoint)
		local hitPart = arcPoint.Hit;
		
		modAudio.Play("GrenadeBounce", self.Prefab);
	end
	
	return projectile;
end

return Pool;
