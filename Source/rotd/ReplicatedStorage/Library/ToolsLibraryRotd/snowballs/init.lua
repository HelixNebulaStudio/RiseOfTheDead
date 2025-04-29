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
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations={
		ChargeDuration = 0.2;
		
		--== Projectile
		ProjectileId = "snowball";
		ProjectileConfig = {
			Velocity = 200;
			Bounce = 0;
			LifeTime = 20;
			KeepAcceleration=true;
			IgnoreWater=false;
		};
		VelocityBonus = 50;
		
		ConsumeOnThrow=false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;