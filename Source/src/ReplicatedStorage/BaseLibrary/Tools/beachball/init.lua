local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="Throwable";

	Animations={
		Core={Id=5441598768;};
		Charge={Id=5441607436;};
		Throw={Id=5075441987};
	};
	Audio={
		Throw={Id=1863039220; Pitch=1; Volume=1;};
	};
	
	Configurations={
		Damage = 100;
		
		Velocity = 50;
		ProjectileBounce = 0.9;
		ChargeDuration = 1;
		VelocityBonus = 100;
		
		WaistRotation = math.rad(0);
		ThrowRate = 2;
		
		--== Projectile
		ProjectileId = "beachball";
		ProjectileLifeTime = 10;
		
		ConsumeOnThrow=false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;