local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="ThrowableTool";

	Animations={
		Core={Id=7326904292;};
		Load={Id=7326901815;};
		Throw={Id=6235897108};
	};
	Audio={
		Throw={Id=5083063763; Pitch=1; Volume=1;};
	};

	Configurations={
		LoadTime = 1;
		UseViewmodel = false;
		CustomThrowPoint = "MatchStick";

		Damage = 10;
		ThrowRate = 1;

		--== Projectile
		ProjectileId = "matchStick";
		ProjectileConfig = {
			Velocity = 100;
			Bounce = 0;
			LifeTime = 4;
			Acceleration = Vector3.new(0, -workspace.Gravity, 0);
			KeepAcceleration = true;
		};
		VelocityBonus = 40;

		ConsumeOnThrow=true;
	};
	Properties={};
	Welds={
		LeftToolGrip="matchbox";
	};
};


function toolPackage.OnLoad(handler: ToolHandlerInstance)
	local prefab = handler.Prefabs[1];

	local fire = prefab:FindFirstChild("Fire2", true);
	if fire then
		modAudio.Play("BurnTick"..math.random(1,3), fire.Parent);
		fire.Enabled = true;
	end
end;

function toolPackage.OnThrow(handler: ToolHandlerInstance)
	local prefab = handler.Prefabs[1];

	local fire = prefab:FindFirstChild("Fire2", true);
	if fire then
		fire.Enabled = false;
		fire:Clear();
	end
end;

function toolPackage.OnThrowComplete(handler: ToolHandlerInstance)
	local prefab = handler.Prefabs[1];

	local fire = prefab:FindFirstChild("Fire2", true);
	if fire then
		fire.Enabled = true;
	end
end;

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;