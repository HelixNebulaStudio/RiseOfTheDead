local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local statusKey = "ToxicBarrage";
local modifierPackage = {
	Name = "Toxic Barrage";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local rLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local rValue, rTweakVal = rLayerInfo.Value, rLayerInfo.TweakValue;
	if rTweakVal then
		rValue = rValue + rTweakVal;
	end
		
	local tLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Values = {
		Reduction = rValue;
		Duration = tValue;
	}
end

if RunService:IsServer() then

	function modifierPackage.Binds.OnBulletHit(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
		if packet.TargetModel == nil then return end;
		local duration = modifier.Values.Duration;

		local characterClass: CharacterClass;
		if modifier.Player then
			characterClass = shared.modPlayers.get(modifier.Player);
		end
		
		local healthComp: HealthComp? = modHealthComp.getByModel(packet.TargetModel);
		if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return end;
	
		local targetClass: ComponentOwner = healthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;
			
		local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusKey);
		if statusClass then
			statusClass.Expires = workspace:GetServerTimeNow() + duration;
			return;
		end

		statusComp:Apply(statusKey, {
			Expires = workspace:GetServerTimeNow() + duration;
			Values = {
				ImmunityReduction = modifier.Values.Reduction;
			};
		});

	end

end

return modifierPackage;