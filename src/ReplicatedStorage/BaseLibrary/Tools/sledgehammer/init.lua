local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16971466256;};
		Load={Id=16971470417;};
		PrimaryAttack={Id=16971463462};
		ComboAttack3={Id=16971481755};
		Inspect={Id=16971479063;};
		Unequip={Id=16971484030};
		
	} or {
		Core={Id=16971466256;};
		Load={Id=16971470417;};
		PrimaryAttack={Id=16971463462};
		ComboAttack3={Id=16971481755};
		Inspect={Id=16971479063;};
		Unequip={Id=16971484030};
		
	};
	Audio={
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4844105915; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=2;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1.4;
		BaseDamage=800;

		PrimaryAttackSpeed=1;
		PrimaryAttackAnimationSpeed=0.43;

		HitRange=15;
		BaseKnockback=70;

		Combos = {
			[3]={TimeSlot=3; ResetCombo=true; AnimationSpeed=1.38;}; -- Every third attack within 3 seconds
		};

		StaminaCost = 35;
		StaminaDeficiencyPenalty = 0.65;
	};

	Tool.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;

	end

	Tool.Properties = {
		Attacking=false;
	}
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;