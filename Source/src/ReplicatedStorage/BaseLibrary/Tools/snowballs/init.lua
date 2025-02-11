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
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;