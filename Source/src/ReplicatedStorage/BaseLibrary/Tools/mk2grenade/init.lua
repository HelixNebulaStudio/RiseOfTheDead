local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="Throwable";

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
		DamageRatio = 0.05;
		MinDamage = 100;
		
		Velocity = 160;
		ProjectileBounce = 0.6;
		ChargeDuration = 0.65;
		VelocityBonus = 40;
		
		--== Projectile
		ProjectileId = "mk2Grenade";
		ProjectileLifeTime = 20;
		DetonateTimer = 2;
		
		ConsumeOnThrow=true;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;