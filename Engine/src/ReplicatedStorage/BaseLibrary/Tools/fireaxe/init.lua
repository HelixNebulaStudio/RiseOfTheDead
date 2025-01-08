local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations={
		Core={Id=16971427992;};
		Load={Id=16971430052;};
		PrimaryAttack={Id=16971425618};
		HeavyAttack={Id=16971437059};
		Inspect={Id=16971433041;};
		Unequip={Id=16971435376; Looped=false;};
	};
	Audio={
		Load={Id=2304904662; Pitch=0.6; Volume=0.5;};
		PrimaryHit={Id=4844105915; Pitch=1.4; Volume=1;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=1;};
		HeavySwing={Id=158037267; Pitch=0.70; Volume=1;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	Tool.Category = "Edged";

	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1;
		BaseDamage=460;
		
		PrimaryAttackSpeed=1;
		--PrimaryAttackAnimationSpeed=0.4;

		HeavyAttackMultiplier=2.5;
		HeavyAttackSpeed=2;
		HitRange=15;

		WaistRotation=math.rad(0);

		StaminaCost = 18;
		StaminaDeficiencyPenalty = 0.8;
		
		BleedDamagePercent=0.1;
		BleedSlowPercent=0.2;

		SpecialStats = {
			IgnitionChance = 0.66;
		};
		
		PropertiesOfMod = {
			Damage = 50;
			Duration = 5;
			UseCurrentHpDmg = true;
		};
	};

	Tool.Properties = {
		Attacking=false;
	}
	
	function Tool:OnEnemyHit(model, damage)
		local ignitionChance = self.ToolConfig.Configurations.SpecialStats.IgnitionChance;
		if math.random(0, 100)/100 > ignitionChance then return end;
		
		local modFlameMod = require(game.ReplicatedStorage.BaseLibrary.ItemModsLibrary.FlameMod);
		
		local bodyParts = {};
		for _, obj in pairs(model:GetChildren()) do
			if obj:IsA("BasePart") then
				table.insert(bodyParts, obj);
			end
		end
		
		modFlameMod.ActivateMod{
			Dealer=self.Player;
			ToolModule=self.ToolConfig;
			
			TargetModel=model;
			TargetPart=#bodyParts > 0 and bodyParts[math.random(1, #bodyParts)] or model:FindFirstChildWhichIsA("BasePart");
		};
		
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;