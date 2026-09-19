local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local modProjectileRicochet = shared.require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

local modifierPackage = {
	Name = "Bow Ricochet";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	modifier.SetValues.ProjectileConfig = {
		Velocity = 175;
		LifeTime = 3;
		MaxBounce = 1;
	}
	modifier.Properties.Radius = value;
end

if RunService:IsServer() then

	function modifierPackage.Binds.WeaponShotProjectileNew(modifier: ItemModifierInstance, projectile: ProjectileInstance)
		local scanRadius = modifier.Properties.Radius;
		function projectile.BindArcStepped(projectile: ProjectileInstance, arcPoint: ArcPoint)
			modProjectileRicochet.BindStepped(projectile, arcPoint, scanRadius);
		end
	end

end

return modifierPackage;