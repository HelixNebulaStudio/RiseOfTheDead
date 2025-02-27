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
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations={
		Velocity = 200;
		ChargeDuration = 0.2;
		VelocityBonus = 50;
		
		--== Projectile
		ProjectileId = "snowball";
		ProjectileBounce = 0;
		ProjectileLifeTime = 20;
		ProjectileKeepAcceleration=true;
		IgnoreWater=false;
		
		ConsumeOnThrow=false;
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