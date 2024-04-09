local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);
--==
return function()
	local Melee = {};
	Melee.Class = "Melee";
	
	Melee.Configurations = {
		Type="Chainsaw";
		Mode="Auto";
		
		EquipLoadTime=0.5;
		BaseDamage=450;

		PrimaryAttackSpeed=0.2;

		HitRange=15;
		
		WaistRotation=math.rad(0);

		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.8;
	};
	
	Melee.Properties = {
		Attacking=false;
	}
	
	Melee.OnToolEquip = function(ToolHandler, toolModel)
		if toolModel.Parent == nil then return end;
		
		local bladeA = toolModel:WaitForChild("BladeA");
		local bladeB = toolModel:WaitForChild("BladeB");
		
		local t = 3;
		while toolModel:IsDescendantOf(workspace) do
			bladeA.Transparency = 1;
			bladeB.Transparency = 0;
			
			for a=1, t do task.wait(); end
			
			bladeA.Transparency = 0;
			bladeB.Transparency = 1;
			
			for a=1, t do task.wait(); end
		end
	end;
	
	return modMeleeProperties.new(Melee);
end;
