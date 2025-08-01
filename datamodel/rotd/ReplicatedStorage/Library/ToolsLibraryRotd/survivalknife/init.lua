local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16855529757;};
		Load={Id=16855532480;};
		PrimaryAttack={Id={107395534384375; 117118082984437}};
		Inspect={Id=16855539538; WaistStrength=0.2;};
		Unequip={Id=16855542753};
	};
	Audio={
		Load={Id=2304904662; Pitch=1; Volume=0.4;};
		PrimaryHit={Id=9141019032; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
	};
	
	Configurations={
		Category = "Edged";
		Type="Knife";

		EquipLoadTime=0.3;
		Damage=100;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=7.5;
		WaistRotation=math.rad(0);

		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.4;

		BleedDamagePercent=0.35;
		BleedSlowPercent=0.1;
	};
	Properties={};

	Holster = {
		KnifeAttachment={PrefabName="survivalknife"; };
	}
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;