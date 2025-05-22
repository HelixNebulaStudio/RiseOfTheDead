local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Tool";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16919319262;};
		Load={Id=16919321381;};
		PrimaryAttack={Id={16919327237; 16919328303}};
		HeavyAttack={Id=16919323389};
		Inspect={Id=16919325385;};
		Unequip={Id=16919330088};
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
		
		EquipLoadTime=1.25;
		Damage=640;

		PrimaryAttackSpeed=0.8;
		--PrimaryAttackAnimationSpeed=0.7;

		HeavyAttackMultiplier=2;
		HeavyAttackSpeed=2;
		HitRange=15;

		WaistRotation=math.rad(0);

		StaminaCost = 10;
		StaminaDeficiencyPenalty = 0.8;

		BleedDamagePercent=0.3;
		BleedSlowPercent=0.3;
	};
	Properties={};

	Holster = {
		RightSwordAttachment={PrefabName="inquisitorssword"; Offset=CFrame.new(-0.600000024, -0.200000003, 0.5, -0.256916583, 0.344730973, 0.902859032, -0.383022249, 0.821393788, -0.42261824, -0.887292385, -0.454392731, -0.0789900571);}; -- Use `Offset` attribute to adjust
	}
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;