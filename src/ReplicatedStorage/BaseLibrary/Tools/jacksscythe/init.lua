local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16880124261;};
		Load={Id=16880126274;};
		PrimaryAttack={Id={16880116337; 16880122337}};
		HeavyAttack={Id=5729677503};
		Inspect={Id=16880131666;};
		Unequip={Id=16880138065};
		
	} or {
		Core={Id=16880124261;};
		Load={Id=16880126274;};
		PrimaryAttack={Id={16880116337; 16880122337}};
		HeavyAttack={Id=5729677503};
		Inspect={Id=16880131666;};
		Unequip={Id=16880138065};
		
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=9141019032; Pitch=0.6; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	Tool.Category = "Edged";

	Tool.Holster = {
		RightSwordAttachment={PrefabName="jacksscythe"; Offset=CFrame.new(0.800000012, 0.800000012, 0, -1, 8.74227766e-08, 0, -8.74227766e-08, -1, 0, 0, 0, 1);}; -- Use `Offset` attribute to adjust
	}

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1.5;
		BaseDamage=280;

		PrimaryAttackSpeed=0.8;
		--PrimaryAttackAnimationSpeed=0.7;

		HeavyAttackMultiplier=2;
		HeavyAttackSpeed=2;
		HitRange=15;

		WaistRotation=math.rad(0);

		StaminaCost = 14;
		StaminaDeficiencyPenalty = 0.8;

		BleedDamagePercent=0.1;
		BleedSlowPercent=0.35;
	};

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;