local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Axe of Fire";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Binds.OnEnemyHit(modifier: ItemModifierInstance)
	if RunService:IsClient() then return end;

	local equipmentClass = modifier.EquipmentClass;
	
	local configurations = equipmentClass.Configurations;
	local ignitionChance = configurations.AxeOfFireIgnitionChance or 0.66;

	if math.random(0, 100)/100 > ignitionChance then return end;
	local fireDamage = configurations.AxeOfFireDamage or 50;
	local fireDuration = configurations.AxeOfFireDuration or 5;
	local useCurrHpAsDmg = configurations.AxeOfFireUseCurrentHpDmg == true;
	
	local modFlameMod = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary.FlameMod);
	
	local bodyParts = {};
	for _, obj in pairs(model:GetChildren()) do
		if obj:IsA("BasePart") then
			table.insert(bodyParts, obj);
		end
	end
	
	modFlameMod.ActivateMod{
		Dealer=modifier.Player;
		ToolModule=modifier.ToolConfig;
		
		TargetModel=model;
		TargetPart=#bodyParts > 0 and bodyParts[math.random(1, #bodyParts)] or model:FindFirstChildWhichIsA("BasePart");
	};
end

return modifierPackage;