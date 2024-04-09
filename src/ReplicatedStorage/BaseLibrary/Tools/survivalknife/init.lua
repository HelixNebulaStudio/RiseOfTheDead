local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16855529757;};
		Load={Id=16855532480;};
		PrimaryAttack={Id=16855534942};
		PrimaryAttack2={Id=16855537221};
		Inspect={Id=16855539538;};
		Unequip={Id=16855542753};
	} or {
		Core={Id=16855529757;};
		Load={Id=16855532480;};
		PrimaryAttack={Id=16855534942};
		PrimaryAttack2={Id=16855537221};
		Inspect={Id=16855539538;};
		Unequip={Id=16855542753};
	};
	Audio={
		Load={Id=2304904662; Pitch=1; Volume=0.4;};
		PrimaryHit={Id=9141019032; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";

	Tool.Holster = {
		KnifeAttachment={PrefabName="survivalknife"; };
	}

	Tool.Configurations = {
		Type="Knife";
		EquipLoadTime=0.3;
		BaseDamage=100;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=7.5;
		WaistRotation=math.rad(0);

		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.4;
	};

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;