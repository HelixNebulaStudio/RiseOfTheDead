local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId = script.Name;
	Class = "Tool";
	HandlerType = "ThrowableTool";

	Animations = {
		Core={Id=5069636743;};
		Charge={Id=5075419727;};
		Throw={Id=5075441987};
	};
	Audio = {
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations = {
		ChargeDuration = 0.2;
		
		--== Projectile
		ProjectileId = "junk";
		ProjectileConfig = {
			Velocity = 100;
			Bounce = 0.2;
			LifeTime = 20;
			KeepAcceleration=true;
			IgnoreWater=false;

			MaxBounce = 3;
			RayRadius = 0;
			AirSpin = math.rad(18);
		};
		VelocityBonus = 25;
		
		ConsumeJunk = true;
		ConsumeOnThrow = false;
	};
	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

function toolPackage.ServerEquip(handler: ToolHandlerInstance)
	local mainToolModel = handler.MainToolModel;

	local r = math.random(1, 6);
	local a = 1;
	for _, part in pairs(mainToolModel:GetChildren()) do
		if part.Name ~= "Junk" then continue end;

		part.Transparency = a == r and 0 or 1;

		a += 1;
	end
end

return toolPackage;