local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ExplosionHandler = {}
ExplosionHandler.__index = ExplosionHandler;

local CollectionService = game:GetService("CollectionService");

local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modDamageTag = require(game.ReplicatedStorage.Library.DamageTag);

ExplosionHandler.Debug = false;

CollectionService:AddTag(workspace.Environment, "EnvironmentColliders");
CollectionService:AddTag(workspace.Interactables, "EnvironmentColliders");


function ExplosionHandler:Cast(position, params)
	params = params or {};
	
	params.Radius = params.Radius or 20;
	params.MaxParts = params.MaxParts or 32;
	params.CollisionGroup = params.CollisionGroup or "Raycast";

	params.Tags = params.Tags or {
		{"PlayerRootParts"}; -- 1
		{"EntityRootPart"}; -- 2
		{"Destructibles"; "EntityDestructibles"; "Flammable"}; --"EnvironmentColliders";
	};
	
	
	local hitResultLayers = {};
	local rayIncludeList = nil;

	local overlapParams = OverlapParams.new();
	overlapParams.FilterType = Enum.RaycastFilterType.Include;
	overlapParams.MaxParts = params.MaxParts;
	overlapParams.CollisionGroup = params.CollisionGroup;
	
	
	for a=1, #params.Tags do -- passes;
		local tagLayerList = params.Tags[a];


		rayIncludeList = nil;
		for b=1, #tagLayerList do
			if rayIncludeList == nil then
				rayIncludeList = CollectionService:GetTagged(tagLayerList[b]);
			else
				for _, objs in pairs(CollectionService:GetTagged(tagLayerList[b])) do
					table.insert(rayIncludeList, objs);
				end
			end
		end
		overlapParams.FilterDescendantsInstances = rayIncludeList;
		
		
		local hitResultLayer = {};
		local hitMarker = {};
		local hitParts = workspace:GetPartBoundsInRadius(position, params.Radius, overlapParams);

		for b=1, #hitParts do
			if a == 1 and hitMarker[hitParts[b].Parent] == nil then
				hitMarker[hitParts[b].Parent] = true;
				table.insert(hitResultLayer, hitParts[b]);
			elseif a >= 2 and hitMarker[hitParts[b]] == nil then
				hitMarker[hitParts[b]] = true;
				table.insert(hitResultLayer, hitParts[b]);
			end
		end
		table.clear(hitMarker);

		table.insert(hitResultLayers, hitResultLayer);
	end
	

	if self.Debug == true then
		local dbPart = Debugger:PointPart(position);
		dbPart.Transparency = 0.5;
		dbPart.Size = Vector3.new(params.Radius*2, params.Radius*2, params.Radius*2);
		game.Debris:AddItem(dbPart, 30);
	end
	
	
	return hitResultLayers;
end

export type ExplosionProcessPacket = {
	Damage: number?;
	MinDamage: number?;
	MaxDamage: number?;

	DamageRatio: number?;
	ExplosionStun: number?;
	ExplosionStunThreshold: number?;
	ExplosionForce: number?;

	IgniteFlammables: boolean?;

	Owner: Player?;
	DamageOrigin: Vector3?;
	OnPartHit: ((packet: ExplosionProcessPacket, basePart: BasePart) -> nil)?;
	OnDamagableHit: ((damagable: {any}, damage: number)->boolean)?;
	HandleExplosion: boolean?;

	TargetableEntities: {[any]:any}?;
	StorageItem: {[any]:any}?;
}
export type HitResultLayers = {
	{[number]: BasePart}
}
function ExplosionHandler:Process(position: Vector3, hitResultLayers: HitResultLayers, params: ExplosionProcessPacket)
	params = params or {};
	
	-- Default values;
	params.Damage = params.Damage or 1;
	params.MinDamage = params.MinDamage or 20;
	params.DamageRatio = params.DamageRatio or nil;
	params.ExplosionStun = params.ExplosionStun or 0.5;
	params.ExplosionForce = params.ExplosionForce or 100;
	
	params.IgniteFlammables = params.IgniteFlammables == nil or params.IgniteFlammables;

	params.Owner = params.Owner or nil;
	params.DamageOrigin = position or params.DamageOrigin or nil;

	params.OnPartHit = params.OnPartHit or nil;
	params.HandleExplosion = params.HandleExplosion;
	
	for a=1, #hitResultLayers do
		local hitList = hitResultLayers[a];
		
		local fireFuncs = {};
		
		for _, basePart in pairs(hitList) do
			task.spawn(function()
				if CollectionService:HasTag(basePart, "Flammable") then
					local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
					modFlammable:Ignite(basePart);
				end
			end)
			if params.OnPartHit then
				params.OnPartHit(params, basePart);
			end
			
			if params.HandleExplosion == false then continue end;
			
			local targetModel = basePart.Parent;
			local damagable = modDamagable.NewDamagable(targetModel);
			if damagable == nil then continue end;
			
			table.insert(fireFuncs, function()
				local damage = 1;
				local player = game.Players:GetPlayerFromCharacter(targetModel);
				
				if params.Owner and player == params.Owner then --If hit is rocket owner, Rocket jump
					local assemblyRootPart = player and targetModel.PrimaryPart and targetModel.PrimaryPart:GetRootPart();
					if assemblyRootPart and assemblyRootPart.Anchored ~= true then
						modStatusEffects.ApplyImpulse(player, Vector3.new(0, 220, 0));
					end
					
				elseif damagable:CanDamage(params.Owner) then --If hit can be damaged by owner
					modDamageTag.Tag(targetModel, params.Owner and params.Owner.Character);

					damage = ((params.Damage or 1)/#fireFuncs);

					local humanoid = typeof(damagable.HealthObj) == "Instance" and damagable.HealthObj:IsA("Humanoid") and damagable.HealthObj or nil;
					
					local knockbackResistance = 0;
					if damagable.Object.ClassName == "NpcStatus" then
						local npcModule = damagable.Object:GetModule();
						knockbackResistance = npcModule.KnockbackResistant or 0;

						if params.ExplosionStun then
							local healthInfo = damagable:GetHealthInfo();
							if healthInfo.Armor <= 0 and damage > healthInfo.MaxHealth*(params.ExplosionStunThreshold or 0.23) and humanoid and knockbackResistance < 1 then
								npcModule.EntityStatus:GetOrDefault("explosionRagdoll", {
									Ragdoll=true;
									Expires=tick()+params.ExplosionStun;
								});
							end
						end

					end

					if params.DamageRatio then
						local healthInfo = damagable:GetHealthInfo();
						damage = healthInfo.MaxHealth * params.DamageRatio;
					end
					
					if params.MinDamage then
						damage = math.max(params.MinDamage, damage);
					end
					if params.MaxDamage then
						damage = math.min(params.MaxDamage, damage);
					end
					
					if params.TargetableEntities and humanoid then
						local dmgRatio = (params.TargetableEntities[humanoid.Name] or 0);
						damage = damage * dmgRatio;
					end
					
					if damage > 0 then
						if params.OnDamagableHit and params.OnDamagableHit(damagable, damage) then
							return;
						end

						local newDmgSrc = modDamagable.NewDamageSource{
							Damage=damage;
							Dealer=params.Owner;
							ToolStorageItem=params.StorageItem;
							TargetPart=basePart;
							DamageType="ExplosiveDamage";
							BreakJoint=true;
						}

						local assemblyRootPart: BasePart = player and targetModel.PrimaryPart or basePart:GetRootPart();
						if assemblyRootPart and assemblyRootPart.Anchored ~= true and params.ExplosionForce > 0 then
							local dir = (assemblyRootPart.Position-position).Unit;
							
							newDmgSrc.DamageForce = dir * params.ExplosionForce;
							newDmgSrc.DamagePosition = basePart.Position;

							if knockbackResistance < 1 then
								assemblyRootPart:ApplyImpulse(newDmgSrc.DamageForce * assemblyRootPart.AssemblyMass * (1-knockbackResistance));
							end
						end
						
						damagable:TakeDamagePackage(newDmgSrc);
						
					end

				end
			end)
		end

		for f=1, #fireFuncs do
			task.spawn(fireFuncs[f]);
			if a > 2 then task.wait() end;
		end
		
		wait();
	end
end


function ExplosionHandler.GenericOnPartHit(packet: ExplosionProcessPacket, hitPart: BasePart)
	if hitPart.Anchored then return end
	if not workspace.Environment:IsAncestorOf(hitPart) then return end;

	local rootModel = hitPart;
	while rootModel:GetAttribute("DynamicPlatform") == nil do
		rootModel = rootModel.Parent;
		if rootModel == workspace or rootModel == game then break; end
	end
	if rootModel:GetAttribute("DynamicPlatform") then return end;

	local origin = packet.DamageOrigin;
	local assemblyRootPart: BasePart = hitPart:GetRootPart();
	if assemblyRootPart and assemblyRootPart.Anchored ~= true then
		local dir = (assemblyRootPart.Position-origin).Unit
		assemblyRootPart:ApplyImpulse(dir * assemblyRootPart.AssemblyMass * 150);
	end
end

return ExplosionHandler;