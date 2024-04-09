return function()
	local Food = {};
	
	Food.Configurations = {
		EffectDuration = (60*3);
		EffectType = "Status";
		
		StatusId = "Ziphoning";
		
		UseDuration = 1;
	};
	
	return Food;
end;
