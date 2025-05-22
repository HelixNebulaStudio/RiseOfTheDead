local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local statusKey = "IncendiaryRounds";
local modifierPackage = {
	Name = "Incendiary Rounds";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
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
end


if RunService:IsServer() then

	function modifierPackage.Binds.OnBulletHit(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
		local duration = modifier.Values.Duration;

		local characterClass: CharacterClass;
		if modifier.Player then
			characterClass = shared.modPlayers.get(modifier.Player);
		end
		
		local healthComp: HealthComp? = modHealthComp.getByModel(packet.TargetModel);
		if healthComp == nil or not healthComp:CanTakeDamageFrom(characterClass) then return end;

		local targetClass: ComponentOwner = healthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;

		if targetClass.ClassName == "NpcClass" then
			local targetImmunity = (targetClass :: NpcClass):GetImmunity("Fire"); 
			if targetImmunity >= 1 then return end;

		elseif targetClass.ClassName == "Destructible" then
			local targetPart = packet.TargetPart;
			if CollectionService:HasTag(targetPart, "Flammable") then
				local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
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
			Values = {
				ApplyBy = characterClass;

				Damage = modifier.Values.Damage;
				TargetPart = packet.TargetPart;
				Stacks = 0;
			};
		});

	end

end

return modifierPackage;