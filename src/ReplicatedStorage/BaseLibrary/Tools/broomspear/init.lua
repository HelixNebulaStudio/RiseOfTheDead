local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16923661895;};
		PrimaryAttack={Id=16923667458};
		Inspect={Id=16923664864;};
		Charge={Id=16923657792;};
		Throw={Id=16923669399};
		Equip={Id=18161004108};
		Unequip={Id=18161006746};
		
	} or {
		Core={Id=16923661895;};
		PrimaryAttack={Id=16923667458};
		Inspect={Id=16923664864;};
		Charge={Id=16923657792;};
		Throw={Id=16923669399};
		Equip={Id=18161004108};
		Unequip={Id=18161006746};
		
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
		Type="Spear";
		EquipLoadTime=0.5;
		BaseDamage=240;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.4;

		HitRange=16;
		WaistRotation=math.rad(80);
		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.6;

		-- Throwable
		Throwable = true;
		ThrowDamagePercent = 0.04;

		Velocity = 60;
		VelocityBonus = 60;
		ProjectileBounce = 0;
		ChargeDuration = 0.5;
		ThrowStaminaCost = 25;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(35);

		--== Projectile
		ProjectileId = "broomSpear";
		ProjectileLifeTime = 30;

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