local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=17791090952;};
		PrimaryAttack={Id=17791092107};
		PrimaryAttack2={Id=17791093356};
		Inspect={Id=17791095270; WaistStrength=0.2;};
		Charge={Id=17791097278;};
		Throw={Id=17791099691};
		Equip={Id=18160784201};
		Unequip={Id=18160786727};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=1884075293; Pitch=1; Volume=2;};
		PrimarySwing={Id=5083063763; Pitch=1.4; Volume=2;};
	};
	
	Configurations={
		Category = "Pointed";
		Type="Boomerang";

		EquipLoadTime=0.2;
		Damage=500;

		PrimaryAttackSpeed=0.45;

		HitRange=6;
		WaistRotation=math.rad(0);
		StaminaCost = 8;
		StaminaDeficiencyPenalty = 0.6;

		-- Throwable
		Throwable = true;
		ThrowDamagePercent = 0.04;

		ChargeDuration = 0.2;
		ThrowStaminaCost = 20;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(35);

		--== Projectile
		ProjectileId = "boomerang";
		ProjectileConfig={
			Velocity = 120;
			LifeTime = 10;
		};
		VelocityBonus = 100;

		ConsumeOnThrow=false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;