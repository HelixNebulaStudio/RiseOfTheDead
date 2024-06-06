local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16923739633;};
		PrimaryAttack={Id=16923750670};
		Load={Id=16923742307};
		Inspect={Id=16923747582;};
		Charge={Id=16923735442;};
		Throw={Id=16923753693};
		Unequip={Id=16923756581};
		
	} or {
		Core={Id=16923739633;};
		PrimaryAttack={Id=16923750670};
		Load={Id=16923742307};
		Inspect={Id=16923747582;};
		Charge={Id=16923735442;};
		Throw={Id=16923753693};
		Unequip={Id=16923756581};
		
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};

		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";

	Tool.UseViewmodel = false;

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=300;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.5;

		HitRange=8;

		WaistRotation=math.rad(0);
		StaminaCost = 25;
		StaminaDeficiencyPenalty = 0.5;

		-- Throwable
		Throwable = true;
		ThrowDamagePercent = 0.04;

		
		Velocity = 100;
		ChargeDuration = 0.5;
		VelocityBonus = 50;
		ThrowStaminaCost = 25;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(0);

		--== Projectile
		ProjectileId = "pickaxe";
		ProjectileBounce = 0;
		ProjectileLifeTime = 10;

		ConsumeOnThrow=false;
	};

	Tool.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;

	end

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;