return function()
	local Food = {};
	
	Food.Configurations = {
		EffectDuration = 60;
		EffectType = "Status";

		StatusId = "StatusResistance";
		
		UseDuration = 4;
	};
	
	return Food;
end;