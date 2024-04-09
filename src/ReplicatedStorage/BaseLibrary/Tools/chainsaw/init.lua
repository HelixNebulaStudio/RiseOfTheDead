local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations=workspace:GetAttribute("IsDev") and {
		Core={Id=16871565985;};
		Load={Id=16871576080;};
		PrimaryAttack={Id=16871579001};
		HeavyAttack={Id=16871751420};
		Inspect={Id=16871595873;};
		
	} or {
		Core={Id=16871565985;};
		Load={Id=16871576080;};
		PrimaryAttack={Id=16871579001};
		HeavyAttack={Id=16871751420};
		Inspect={Id=16871595873;};
		
	};
	Audio={
		Core={Id=7326200210; Pitch=1; Volume=0.25;};
		Load={Id=7326258540; Pitch=1; Volume=2;};
		PrimaryHit={Id=1869594237; Pitch=1; Volume=0.75;};
		PrimarySwing={Id=7326259044; Pitch=1; Volume=1;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";

	Tool.Configurations = {
		Type="Chainsaw";
		Mode="Auto";

		EquipLoadTime=1;
		BaseDamage=450;

		PrimaryAttackSpeed=0.2;

		HitRange=15;

		WaistRotation=math.rad(0);

		StaminaCost = 6;
		StaminaDeficiencyPenalty = 0.8;
	};

	Tool.Properties = {
		Attacking=false;
	}

	Tool.OnToolEquip = function(ToolHandler, toolModel)
		if toolModel.Parent == nil then return end;

		local bladeA = toolModel:WaitForChild("BladeA");
		local bladeB = toolModel:WaitForChild("BladeB");
		
		task.wait(1);
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
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;