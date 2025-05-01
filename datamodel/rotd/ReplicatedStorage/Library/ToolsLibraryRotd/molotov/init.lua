local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="ThrowableTool";

	Animations={
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio={
		Charge={Id=5088355920; Pitch=1; Volume=1;};
		ProjectileBounce={Id=5088356214; Pitch=1; Volume=1;};
		Throw={Id=5083063763; Pitch=1; Volume=1;};
    };
    
	Configurations={
		Damage = 5;
		ChargeDuration = 1;
		
		--== Projectile
		ProjectileId = "molotov";
		ProjectileConfig = {
			Velocity = 140;
			LifeTime = 30;
			Bounce = 0;
			IgnoreWater=false;
		};
		VelocityBonus = 60;
		
		ConsumeOnThrow=true;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;