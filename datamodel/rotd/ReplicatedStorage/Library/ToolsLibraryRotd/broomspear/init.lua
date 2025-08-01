local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16923661895;};
		PrimaryAttack={Id=16923667458};
		Inspect={Id=16923664864; WaistStrength=0.2;};
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
	
	Configurations={
		Category = "Pointed";
		Type="Spear";
		
		EquipLoadTime=0.5;
		Damage=240;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.4;

		HitRange=16;
		WaistRotation=math.rad(80);
		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.6;

		-- Throwable
		Throwable = true;
		ThrowRange = 64;
		ThrowDamagePercent = 0.04;

		ChargeDuration = 0.5;
		ThrowStaminaCost = 25;

		ThrowRate = 1;
		ThrowWaistRotation=math.rad(35);

		--== Projectile
		ProjectileId = "broomspear";
		ProjectileConfig={
			Velocity = 160;
			LifeTime = 30;
			Bounce = 0;
		};
		VelocityBonus = 100;

		ConsumeOnThrow=false;
	};
	Properties={};

	Holster = {
		RightSwordAttachment={PrefabName=script.Name;};
	}
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;