local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
--	Melee.Holster = {
--		LeftSwordAttachment="spikedbat";
--	}
	
	Melee.Configurations = {
		Type="Sword";
		EquipLoadTime=1.4;
		BaseDamage=800;
		
		PrimaryAttackSpeed=1;
		PrimaryAttackAnimationSpeed=0.8;
		
		HitRange=15;
		BaseKnockback=70;
		
		Combos = {
			[3]={TimeSlot=3; ResetCombo=true; AnimationSpeed=1;}; -- Every third attack within 3 seconds
		};
		
		StaminaCost = 35;
		StaminaDeficiencyPenalty = 0.65;
	};
	
	Melee.OnEnemyHit = function(toolHandler, targetModel, damage)
		if damage <= 0 then return end;
		
	end
	
	Melee.Properties = {
		Attacking=false;
	}
	
	return modMeleeProperties.new(Melee);
end;