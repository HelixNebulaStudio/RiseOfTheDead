local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="Throwable";

	Animations={
		Core={Id=6235891614;};
		Throw={Id=6235897108};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations={
		Damage = 50;
		
		Velocity = 100;
		ProjectileBounce = 0;
		VelocityBonus = 40;
		
		--== Projectile
		ProjectileId = "firework";
		ProjectileLifeTime = 10;
		ProjectileAcceleration = Vector3.new(0, 296.2, 0);
		ProjectileKeepAcceleration = true;

		ThrowingMode="Directional";
		
		--ShowFocusTraj=false;
		ConsumeOnThrow=true;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;