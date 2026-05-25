local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Warmonger Scales";
	
	Tags = {
		Unique_HealthMods = true;
		Unique_PacifistsWarmongers = true;
	};
	Binds = {};

	DamageDataNew = nil;
};
--==

if RunService:IsServer() then
	
    function modifierPackage.Binds.DeathHandler(modifier: ItemModifierInstance, npcClass: NpcClass, damageData: DamageData)
		if shared.WorldName == "Slaughterfest" then return end;
		if damageData == nil then return end;

		local damageTo: CharacterClass? = damageData.DamageTo :: CharacterClass;
		if damageTo == nil or (damageTo.ClassName ~= "PlayerClass" and damageTo.ClassName ~= "NpcClass") then return end;
		
		local damageBy: CharacterClass? = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass?;
		if damageBy == nil then return end;
		
		task.spawn(function()
			local statusComp = damageBy.StatusComp;
			if statusComp == nil then return end;

			local statusClass = statusComp:GetOrDefault("WarmongerScales");
			if statusClass == nil then 
				statusClass = statusComp:Apply("WarmongerScales", {
					Values = {
						HealthPerKill = modifier.Properties.HealthPerKill;
						Max = modifier.Properties.Max;
						Pool = 0;
						Buffer = 0;
						LastDeduct = tick();
					};
				});
			end;

			local add = statusClass.Values.HealthPerKill;

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

	modifier.Properties.HealthPerKill = hpkValue;
	modifier.Properties.Max = hpValue;
end

return modifierPackage;