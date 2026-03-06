local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local statusKey = "IncendiaryRounds";
local modifierPackage = {
	Name = "Incendiary Rounds";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local tLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Values = {
		Damage = dValue;
		Duration = tValue;
	};
	modifier.ArrayValues.PassiveModifiers = statusKey;
end


if RunService:IsServer() then
	local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);

	function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
		local duration = modifier.Values.Duration;
		if packet.HitInfo == nil then return end;
		
		local characterClass: CharacterClass = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass;
		if characterClass == nil then return end;

		local targetModel = packet.TargetModel;
		if targetModel == nil then return end;

		local targetPart = packet.HitInfo.Part;
		if targetPart == nil then return end;
		
		local targetHealthComp: HealthComp? = modHealthComp.getByModel(targetModel);
		if targetHealthComp == nil or not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;

		local targetClass: EntityClass = targetHealthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;

		if targetClass.ClassName == "NpcClass" then
			local targetImmunity = (targetClass :: NpcClass):GetImmunity("Fire"); 
			if targetImmunity >= 1 then return end;

		elseif targetClass.ClassName == "Destructible" then
			if CollectionService:HasTag(targetPart, "Flammable") then
				modFlammable:Ignite(targetPart);
			end

		end

		local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusKey);
		if statusClass then
			statusClass.Expires = workspace:GetServerTimeNow() + duration;
			statusClass.Values.Stacks = statusClass.Values.Stacks +1;

			return;
		end

		statusComp:Apply(statusKey, {
			Expires = workspace:GetServerTimeNow() + duration;
			Duration = duration;
			ApplyBy = characterClass;
			Values = {
				Damage = modifier.Values.Damage;
				TargetPart = targetPart;
				Stacks = 0;
				UseCurrHpDmg = true;
			};
		});

	end

end

return modifierPackage;