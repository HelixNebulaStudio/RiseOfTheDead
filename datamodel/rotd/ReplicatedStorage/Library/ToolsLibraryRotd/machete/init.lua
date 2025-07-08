local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=122282841438828;};
		Load={Id=110742733779650;};
		PrimaryAttack={Id={91842639525261; 70616300336827}};
		HeavyAttack={Id=115586386679572};
		Inspect={Id=103025753935487;};
		Unequip={Id=101946188265103};
	};
	Audio={
		Load={Id=2304904662; Pitch=1; Volume=0.4;};
		PrimaryHit={Id=9141019032; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
	};
	
	Configurations={
		Category = "Edged";
		Type="Sword";

		EquipLoadTime=1;
		Damage=240;

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
	Properties={};

	Holster = {
		RightSwordAttachment={PrefabName=script.Name;};
	}
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;