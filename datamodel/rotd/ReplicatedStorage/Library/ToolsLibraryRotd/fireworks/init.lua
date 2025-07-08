local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="ThrowableTool";

	Animations={
		Core={Id=6235891614;};
		Throw={Id=6235897108};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations={
		Damage = 50;

		--== Projectile
		ProjectileId = "fireworks";
		ProjectileConfig = {
			Velocity = 100;
			Bounce = 0;
			LifeTime=10;
			Acceleration = Vector3.new(0, 296.2, 0);
			KeepAcceleration = true;
			ThrowingMode="Directional";
		};
		VelocityBonus = 40;

		--ShowFocusTraj=false;
		ConsumeOnThrow=true;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;