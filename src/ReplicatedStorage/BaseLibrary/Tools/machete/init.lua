local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16855658641;};
		Load={Id=16855661898;};
		PrimaryAttack={Id={137947152092729; 91864590162345}};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16855689192;};
		Unequip={Id=16855693138};
		
	} or {
		Core={Id=16855529757;};
		Load={Id=16855532480;};
		PrimaryAttack={Id={16855664531; 16855682824}};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16855689192;};
		Unequip={Id=16855693138};
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
	Tool.Category = "Edged";
	
	Tool.Holster = {
		RightSwordAttachment={PrefabName="machete";};
	}

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1;
		BaseDamage=240;

		PrimaryAttackSpeed=1;
		PrimaryAttackAnimationSpeed=0.4;

		HeavyAttackMultiplier=1.75;
		HeavyAttackSpeed=1.4;
		HitRange=12.5;

		WaistRotation=math.rad(0);

		StaminaCost = 13;
		StaminaDeficiencyPenalty = 0.6;

		BleedDamagePercent=0.1;
		BleedSlowPercent=0.1;
	};

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;