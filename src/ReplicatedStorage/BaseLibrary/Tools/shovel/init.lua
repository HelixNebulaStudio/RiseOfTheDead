local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16904172089;};
		Load={Id=16904173371;};
		PrimaryAttack={Id={85153211105334; 136133793967029}};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16904175486;};
		Unequip={Id=16904176888};
		
	} or {
		Core={Id=16904172089;};
		Load={Id=16904173371;};
		PrimaryAttack={Id={16904169877; 16904170758}};
		HeavyAttack={Id=4473902088};
		Inspect={Id=16904175486;};
		Unequip={Id=16904176888};
		
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=8814671013; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.75; Volume=1;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	Tool.Category = "Blunt";

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=0.5;
		BaseDamage=400;

		PrimaryAttackSpeed=0.3;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=12.5;
		BaseKnockback=50;

		WaistRotation=math.rad(0);

		StaminaCost = 13;
		StaminaDeficiencyPenalty = 0.6;
	};

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;