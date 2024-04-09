return function()
	local Food = {};
	
	Food.Configurations = {
		EffectDuration = 30;
		EffectType = "Status";

		StatusId = {"ForceField"; "Reinforcement"; "Superspeed"; "Lifesteal"};
		
		UseDuration = 1;
	};
	
	return Food;
end;