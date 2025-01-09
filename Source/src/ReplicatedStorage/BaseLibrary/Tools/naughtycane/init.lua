local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16971651562;};
		PrimaryAttack={Id=102007195486358};
		Load={Id=16971653858;};
		Inspect={Id=16971657001;};
		Unequip={Id=16971658803;};
		
	} or {
		Core={Id=16971651562;};
		PrimaryAttack={Id=16971648919};
		Load={Id=16971653858;};
		Inspect={Id=16971657001;};
		Unequip={Id=16971658803;};
		
	};
	Audio={
		Load={Id=4601593953; Pitch=1; Volume=2;};
		PrimaryHit={Id=4602930505; Pitch=1; Volume=2;};
		PrimarySwing={Id=4601593953; Pitch=1; Volume=2;};
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
		BaseDamage=520;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=0.3;

		HitRange=13;
		BaseKnockback=80;

		WaistRotation=math.rad(75);
		FirstPersonWaistOffset=math.rad(-30);

		StaminaCost = 16;
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