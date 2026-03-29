local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local statusKey = "ElectricCharge";

local modifierPackage = {
	Name = "Electric Charge";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local tLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Properties.Targets = math.ceil(tValue);
	modifier.Properties.DamagePercent = dValue;
end

if RunService:IsServer() then

	function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
		if packet.TargetModel == nil then return end;
		
		local maxTargets = modifier.Properties.Targets;
		local damagePercent = modifier.Properties.DamagePercent;

		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;
		local weaponSiid = modifier.EquipmentClass and modifier.EquipmentClass.StorageItem.ID;

		local characterClass: CharacterClass? = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass;
		if characterClass == nil then return end;

		local targetHealthComp: HealthComp? = modHealthComp.getByModel(packet.TargetModel);
		if targetHealthComp == nil or targetHealthComp.IsDead or not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;

		local targetCharClass: EntityClass = targetHealthComp.CompOwner;
		local statusComp: StatusComp? = targetCharClass.StatusComp;
		if statusComp == nil then return end;

		local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusKey);
		if statusClass then return end;

		local hitInfo: HitInfo = packet.HitInfo;

		statusComp:Apply(statusKey, {
			Expires = workspace:GetServerTimeNow()+1;
			ApplyBy = characterClass;
			Values = {
				MaxTargets = maxTargets;
				WeaponSiid = weaponSiid;
				
				OriginAtt = packet.OriginAtt;
				HitPart = hitInfo.Part;
				
				Damage = configurations.PreModDamage;
				DamagePercent = damagePercent;

				TargetsHit = 0;
			};
		});

	end
	
	function modifierPackage.Binds.WeaponShotProjectileNew(
		modifier: ItemModifierInstance, 
		projectile: ProjectileInstance
	)
    	local projectilePart = projectile.Part;

		projectilePart.Color = Color3.fromRGB(255, 253, 139);
		projectilePart.Material = Enum.Material.Cobblestone;

		local bulletTracer = projectilePart:FindFirstChild("BulletTracer");
		if bulletTracer then
			bulletTracer.Color = ColorSequence.new(Color3.fromRGB(255, 253, 139));
		end
	end

	function modifierPackage.Binds.WeaponShotProjectileHit(
		modifier: ItemModifierInstance, 
		projectile: ProjectileInstance, 
		arcPoint: ArcPoint
	)
		if arcPoint.Hit == nil then return end;

		local targetModel = arcPoint.Hit.Parent;
		if targetModel == nil then return end;

		local bulletOriginAtt: Attachment = projectile.;
		
		modifierPackage.Binds.WeaponShotBulletHit(modifier, {
			TargetModel = targetModel;
			OriginAtt = arcTracer.Origin;
			HitInfo = {
				Part = arcPoint.Hit;
			}
		} :: BulletHitData);
	end

end

return modifierPackage;