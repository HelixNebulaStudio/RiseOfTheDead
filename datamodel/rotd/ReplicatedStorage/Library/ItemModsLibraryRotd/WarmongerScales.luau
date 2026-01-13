local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Warmonger Scales";
	
	Tags = {};
	Binds = {};
};
--==
if RunService:IsServer() then
	function modifierPackage.Binds.OnNewDamageData(modifier: ItemModifierInstance, damageData: DamageData)
		if modBranchConfigs.IsWorld("Slaughterfest") then return end;
		
		task.spawn(function()
			local damage = damageData.Damage;
			if damageData.DamageType == "Heal" then return end;
			if damage <= 0 then return end;

			local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner or nil;
			if characterClass == nil then return end;

			local statusComp = characterClass.StatusComp;
			if statusComp == nil then return end;

			local targetModel = damageData.TargetModel;
			local targetHealthComp: HealthComp? = targetModel and modHealthComponent.getByModel(targetModel) or nil;
			if targetHealthComp == nil or targetHealthComp.IsDead then return end;
			if targetHealthComp:CanTakeDamageFrom(characterClass) == false then return end;

			local statusClass = statusComp:GetOrDefault("WarmongerScales");
			if statusClass == nil then 
				statusClass = statusComp:Apply("WarmongerScales", {
					Values = {
						HealthPerKill = modifier.Values.HealthPerKill;
						Max = modifier.Values.Max;
						Pool = 0;
						Buffer = 0;
						LastDeduct = tick();
					};
				});
			end;

			local maxHealth = targetHealthComp.MaxHealth;

			local ratio = math.clamp(damage/maxHealth, 0.1, 1);
			local add = ratio * statusClass.Values.HealthPerKill;

			local oldPool = (statusClass.Values.Pool or 0);
			statusClass.Values.Pool = math.clamp(oldPool + add, 0, statusClass.Values.Max);
			statusClass.Values.LastDeduct = tick()+1;

			if statusClass.Values.Pool > oldPool then
				local dif = statusClass.Values.Pool-oldPool;

				statusClass.Values.Buffer = (statusClass.Values.Buffer or 0) + dif;
			end
			statusClass.Values.LastDamageDealt = workspace:GetServerTimeNow();

			statusClass:Sync();
		end)
	end
end;

function modifierPackage.Update(modifier: ItemModifierInstance)
	local hpkLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "HPK");
	local hpkValue, hpkTweakVal = hpkLayerInfo.Value, hpkLayerInfo.TweakValue;
	if hpkTweakVal then
		hpkValue = hpkValue + hpkTweakVal;
	end

	local hpLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "HP");
	local hpValue, hpTweakVal = hpLayerInfo.Value, hpLayerInfo.TweakValue;
	if hpTweakVal then
		hpValue = hpValue + hpTweakVal;
	end

	modifier.Values.HealthPerKill = hpkValue;
	modifier.Values.Max = hpValue;
end

return modifierPackage;