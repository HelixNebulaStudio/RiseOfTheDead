local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="MeleeTool";

	Animations={
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
	
	Configurations={
		Category = "Edged";
		Type="Sword";
		EquipLoadTime=1.5;
		Damage=280;

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
	Properties={};

	Holster = {
		RightSwordAttachment={PrefabName="jacksscythe"; Offset=CFrame.new(0.800000012, 0.800000012, 0, -1, 8.74227766e-08, 0, -8.74227766e-08, -1, 0, 0, 0, 1);}; -- Use `Offset` attribute to adjust
	}
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;