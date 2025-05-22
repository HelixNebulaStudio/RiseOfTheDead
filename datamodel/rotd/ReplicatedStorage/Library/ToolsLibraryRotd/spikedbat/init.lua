local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16868490126;};
		Load={Id=16868493140};
		PrimaryAttack={Id=102007195486358};
		Inspect={Id=16868496872;};
		Unequip={Id=16868499162};
	};
	Audio={
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4602930505; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1; Volume=2;};
	};
	
	Configurations={
		Category = "Blunt";
		Type="Tool";

		EquipLoadTime=0.5;
		Damage=200;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=15;
		BaseKnockback=100;

		WaistRotation=math.rad(75);
		FirstPersonWaistOffset=math.rad(-30);

		StaminaCost = 15;
		StaminaDeficiencyPenalty = 0.65;
	};
	Properties={};

	Holster = {
		LeftSwordAttachment={PrefabName="spikedbat"; };
	}
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;