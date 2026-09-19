local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local statusKey = "ToxicBarrage";
local modifierPackage = {
	Name = "Toxic Barrage";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);

	local rLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local rValue, rTweakVal = rLayerInfo.Value, rLayerInfo.TweakValue;
	if rTweakVal then
		rValue = rValue + rTweakVal;
	end
		
	local tLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Properties.Reduction = rValue;
	modifier.Properties.Duration = tValue;
end

if RunService:IsServer() then

	function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
		local damageTo: EntityClass? = damageData.DamageTo;
		if damageTo == nil then return end;

		if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
			return;
		end

		local characterClass: CharacterClass = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass;
		if characterClass == nil then return end;

		local targetHealthComp: HealthComp? = damageTo.HealthComp;
		if targetHealthComp == nil then return end;
		if targetHealthComp.IsDead or not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;
	
		local statusComp: StatusComp? = damageTo.StatusComp;
		if statusComp == nil then return end;
			
		local duration = modifier.Properties.Duration;

		local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusKey);
		if statusClass then
			statusClass.Expires = workspace:GetServerTimeNow() + duration;
			return;
		end

		statusComp:Apply(statusKey, {
			ApplyBy = characterClass;
			Expires = workspace:GetServerTimeNow() + duration;
			Duration = duration;
			Values = {
				ImmunityReduction = modifier.Properties.Reduction;
			};
		});
	end

	function modifierPackage.Binds.WeaponShotProjectileNew(
		modifier: ItemModifierInstance, 
		projectile: ProjectileInstance
	)
    	local projectilePart = projectile.Part;

		projectilePart.Color = Color3.fromRGB(87, 211, 83);
		projectilePart.Material = Enum.Material.Cobblestone;
		if projectilePart:IsA("MeshPart") then
			projectilePart.TextureID = "";
		end

		local bulletTracer = projectilePart:FindFirstChild("BulletTracer");
		if bulletTracer then
			bulletTracer.Color = ColorSequence.new(Color3.fromRGB(87, 211, 83));
		end
	end

end

return modifierPackage;