return function()
	local Food = {};
	
	Food.Configurations = {
		EffectDuration = 20;
		EffectType = "Heal";
		
		HealSourceId = "FoodHeal";
		HealRate = 0.2;
		
		UseDuration = 2;
	};
	
	return Food;
end;
