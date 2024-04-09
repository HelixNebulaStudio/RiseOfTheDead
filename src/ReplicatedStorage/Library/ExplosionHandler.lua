local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ExplosionHandler = {}
ExplosionHandler.__index = ExplosionHandler;

local CollectionService = game:GetService("CollectionService");

local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

ExplosionHandler.Debug = false;

CollectionService:AddTag(workspace.Environment, "EnvironmentColliders");
CollectionService:AddTag(workspace.Interactables, "EnvironmentColliders");


function ExplosionHandler:Cast(position, params)
	params = params or {};
	
	params.Radius = params.Radius or 20;
	params.MaxParts = params.MaxParts or 32;
	params.CollisionGroup = params.CollisionGroup or "Raycast";

	params.Tags = params.Tags or {
		{"EntityRootPart"; "PlayerRootParts"};
		{"EnvironmentColliders"};
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

		for a=1, #hitParts do
			if hitMarker[hitParts[a].Parent] == nil then
				hitMarker[hitParts[a].Parent] = true;
				table.insert(hitResultLayer, hitParts[a]);
			end
		end
		hitMarker=nil;
		
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


function ExplosionHandler:Process(position, hitResultLayers, params)
	params = params or {};
	
	-- Default values;
	params.Damage = params.Damage or 1;
	params.MinDamage = params.MinDamage or 20;
	params.DamageRatio = params.DamageRatio or nil;
	params.ExplosionStun = params.ExplosionStun or 0.5;
	params.ExplosionForce = params.ExplosionForce or 50;
	params.Owner = params.Owner or nil;
	
	params.OnPartHit = params.OnPartHit or nil;
	params.HandleExplosion = params.HandleExplosion;
	
	for a=1, #hitResultLayers do
		local hitList = hitResultLayers[a];
		
		local fireFuncs = {};
		
		for _, basePart: BasePart in pairs(hitList) do
			if params.OnPartHit then
				params.OnPartHit(basePart);
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
					local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
					modTagging.Tag(targetModel, params.Owner and params.Owner.Character);

					damage = (params.Damage/#fireFuncs);

					local humanoid = typeof(damagable.HealthObj) == "Instance" and damagable.HealthObj:IsA("Humanoid") and damagable.HealthObj or nil;
					
					if params.ExplosionStun then
						local healthInfo = damagable:GetHealthInfo();
						if healthInfo.Armor <= 0 and damage > healthInfo.MaxHealth*0.23 and humanoid then
							damagable.HealthObj.PlatformStand = true;
							task.delay(params.ExplosionStun, function()
								damagable.HealthObj.PlatformStand = false;
							end)
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
					
					if damagable.Object.ClassName == "NpcStatus" then
						Debugger:Log("targetModel", targetModel.Name..(targetModel:GetAttribute("EntityId") or "##"), "damage", damage);
					end

					if params.TargetableEntities and humanoid then
						local dmgRatio = (params.TargetableEntities[humanoid.Name] or 0);
						damage = damage * dmgRatio;
					end
					
					if damage > 0 then
						local newDmgSrc = modDamagable.NewDamageSource{
							Damage=damage;
							Dealer=params.Owner;
							ToolStorageItem=params.StorageItem;
							TargetPart=basePart;
							DamageType="ExplosiveDamage";
						}

						local assemblyRootPart = player and targetModel.PrimaryPart or basePart:GetRootPart();
						if assemblyRootPart and assemblyRootPart.Anchored ~= true and params.ExplosionForce > 0 then
							local dir = (assemblyRootPart.Position-position).Unit;
							assemblyRootPart.Velocity = dir * params.ExplosionForce + Vector3.new(0, 40, 0);
						
							newDmgSrc.DamageForce = dir * 500;
							newDmgSrc.DamagePosition = basePart.Position;
						end
						
						damagable:TakeDamagePackage(newDmgSrc);
						
					end

				end
			end)
		end

		for f=1, #fireFuncs do
			fireFuncs[f]();
			if a > 1 then task.wait() end;
		end
		
		wait();
	end
end

return ExplosionHandler;
