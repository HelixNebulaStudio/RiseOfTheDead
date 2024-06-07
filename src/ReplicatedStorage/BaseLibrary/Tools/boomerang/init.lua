local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=17763509030;};
		PrimaryAttack={Id=17767638647};
		Inspect={Id=16923664864;};
		Charge={Id=17766900927;};
		Throw={Id=17766919300};
		
	} or {
		Core={Id=17763509030;};
		PrimaryAttack={Id=17767638647}; --17763711056
		Inspect={Id=16923664864;};
		Charge={Id=17766900927;};
		Throw={Id=17766919300};
		
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=1884075293; Pitch=1; Volume=2;};
		PrimarySwing={Id=5083063763; Pitch=1.4; Volume=2;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";

	Tool.Configurations = {
		Type="Boomerang";
		EquipLoadTime=0.2;
		BaseDamage=500;

		PrimaryAttackSpeed=0.3;
		PrimaryAttackAnimationSpeed=1;

		HitRange=6;
		WaistRotation=math.rad(0);
		StaminaCost = 4;
		StaminaDeficiencyPenalty = 0.6;

		-- Throwable
		Throwable = true;
		ThrowDamagePercent = 0.04;

		Velocity = 80;
		VelocityBonus = 50;
		ProjectileBounce = 0;
		ChargeDuration = 0.2;
		ThrowStaminaCost = 20;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(35);

		--== Projectile
		ProjectileId = "boomerang";
		ProjectileLifeTime = 10;

		ConsumeOnThrow=false;
	};

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;