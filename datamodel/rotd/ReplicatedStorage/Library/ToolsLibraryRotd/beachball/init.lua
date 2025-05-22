local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="ThrowableTool";

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
		ChargeDuration = 1;
		ThrowRate = 2;

		WaistRotation = math.rad(0);

		--== Projectile
		ProjectileId = "beachball";
		ProjectileConfig={
			Velocity = 50;
			Bounce = 0.9;
			LifeTime = 10;
		};
		VelocityBonus = 100;

		ConsumeOnThrow=false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;