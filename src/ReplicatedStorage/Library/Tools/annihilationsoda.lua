return function()
	local Food = {};
	
	Food.Configurations = {
		EffectDuration = 120;
		EffectType = "Status";
		
		StatusId = "CritBoost";
		
		UseDuration = 3;
	};
	
	return Food;
end;