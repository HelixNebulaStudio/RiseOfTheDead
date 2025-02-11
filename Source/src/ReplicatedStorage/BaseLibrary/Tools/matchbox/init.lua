local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="Throwable";

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

		Damage = 10,
		
		Velocity = 100,
		ProjectileBounce = 0,
		VelocityBonus = 40,

		ThrowRate = 1,
		
		--== Projectile
		ProjectileId = "matchStick",
		ProjectileLifeTime = 4,
		ProjectileAcceleration = Vector3.new(0, -workspace.Gravity, 0),
		ProjectileKeepAcceleration = true,
		
		--ShowFocusTraj=false,
		ConsumeOnThrow=true
	};
	Properties={};
	Welds={
		LeftToolGrip="matchbox";
	};
};


function toolPackage.OnLoad(handler, toolModels)
	for a=1, #toolModels do
		local prefab = toolModels[a];
		
		local fire = prefab:FindFirstChild("Fire2", true);
		if fire then
			modAudio.Play("BurnTick"..math.random(1,3), fire.Parent);
			fire.Enabled = true;
		end
	end
end;

function toolPackage.OnThrow(handler, toolModels)
	for a=1, #toolModels do
		local prefab = toolModels[a];

		local fire = prefab:FindFirstChild("Fire2", true);
		if fire then
			fire.Enabled = false;
			fire:Clear();
		end
	end
end;

function toolPackage.OnThrowComplete(handler, toolModels)
	for a=1, #toolModels do
		local prefab = toolModels[a];

		local fire = prefab:FindFirstChild("Fire2", true);
		if fire then
			fire.Enabled = true;
		end
	end
end;


function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class);
end

return toolPackage;