local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local statusKey = "IncendiaryRounds";
local modifierPackage = {
	Name = "Incendiary Rounds";
	
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

	modifier.Properties.Damage = dValue;
	modifier.Properties.Duration = tValue;
	modifier.ArrayValues.PassiveModifiers = statusKey;
end


if RunService:IsServer() then
	local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);

	function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
		local damageTo: EntityClass? = damageData.DamageTo;
		if damageTo == nil then return end;

		if modifier.WieldComp == nil or modifier.WieldComp.CompOwner == nil then return end;
		local characterClass: CharacterClass = modifier.WieldComp.CompOwner :: CharacterClass;

		local targetHealthComp: HealthComp? = damageTo.HealthComp;
		if targetHealthComp == nil then return end;

		local targetPart = damageData.TargetPart;
		if targetPart == nil then return end;

		local statusComp: StatusComp? = damageTo.StatusComp;
		if statusComp == nil then return end;

		if damageTo.ClassName == "NpcClass" then
			local targetImmunity = (damageTo :: NpcClass):GetImmunity("Fire"); 
			if targetImmunity >= 1 then return end;

		elseif damageTo.ClassName == "Destructible" then
			if CollectionService:HasTag(targetPart, "Flammable") then
				modFlammable:Ignite(targetPart);
			end

		end
		if not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;

		local duration = modifier.Properties.Duration;

		local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusKey);
		if statusClass then
			statusClass.Expires = workspace:GetServerTimeNow() + duration;
			statusClass.Values.Stacks = statusClass.Values.Stacks +1;

			return;
		end

		statusComp:Apply(statusKey, {
			Expires = workspace:GetServerTimeNow() + duration;
			Duration = duration;
			ApplyBy = characterClass;
			Values = {
				Damage = modifier.Properties.Damage;
				StorageItemBy = modifier.EquipmentClass and modifier.EquipmentClass.StorageItem;
				TargetPart = targetPart;
				Stacks = 0;
				UseCurrHpDmg = true;
			};
		});
	end

	function modifierPackage.Binds.WeaponShotProjectileNew(
		modifier: ItemModifierInstance, 
		projectile: ProjectileInstance
	)
    	local projectilePart = projectile.Part;

		projectilePart.Color = Color3.fromRGB(255, 94, 0);
		projectilePart.Material = Enum.Material.Neon;
		if projectilePart:IsA("MeshPart") then
			projectilePart.TextureID = "";
		end

		local bulletTracer = projectilePart:FindFirstChild("BulletTracer");
		if bulletTracer then
			bulletTracer.Color = ColorSequence.new(Color3.fromRGB(255, 94, 0));
		end

		local fireParticle = Instance.new("Fire");
		fireParticle.Size = 2;
		fireParticle.Heat = 10;
		fireParticle.Parent = projectilePart;
	end
	
end

return modifierPackage;