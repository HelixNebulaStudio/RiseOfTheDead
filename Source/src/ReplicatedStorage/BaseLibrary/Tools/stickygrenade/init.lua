local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
<<<<<<< HEAD
	HandlerType="Throwable";
=======
	HandlerType="ThrowableTool";
>>>>>>> b7050963ccc669ec5ee00093af9741966adc936a

	Animations={
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		Charge={Id=5082994235; Pitch=1; Volume=1;};
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};
	
	Configurations={
		ExplosionRadius = 35;
		DamageRatio = 0.1;
		MinDamage = 200;
		
		Velocity = 160;
		ProjectileBounce = 0;
		ChargeDuration = 0.7;
		VelocityBonus = 40;
		
		--== Projectile
		ProjectileId = "stickyGrenade";
		ProjectileLifeTime = 20;
		DetonateTimer = 3;
		
		ConsumeOnThrow=true;
	};
	Properties={};
};

function toolPackage.newClass()
<<<<<<< HEAD
	return modEquipmentClass.new(toolPackage.Class);
=======
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
>>>>>>> b7050963ccc669ec5ee00093af9741966adc936a
end

return toolPackage;