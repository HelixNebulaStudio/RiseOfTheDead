local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local statusKey = "ElectricCharge";

local modifierPackage = {
	Name = "Electric Charge";
	
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
		Targets = math.ceil(tValue);
		DamagePercent = dValue;
	};
end

if RunService:IsServer() then

	function modifierPackage.Binds.OnBulletHit(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
		local maxTargets = modifier.Values.Targets;
		local damagePercent = modifier.Values.DamagePercent;

		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;
		local weaponSiid = modifier.EquipmentStorageItem and modifier.EquipmentStorageItem.ID;


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
		if statusClass then return end;

		statusComp:Apply(statusKey, {
			Expires = workspace:GetServerTimeNow()+1; 
			Values = {
				ApplyBy = characterClass;

				MaxTargets = maxTargets;
				WeaponSiid = weaponSiid;
				
				ArcOrigin = packet.OriginPoint;
				ArcPoint = packet.TargetPoint;

				Damage = configurations.PreModDamage;
				DamagePercent = damagePercent;

				TargetsHit = 0;
			};
		});

	end
	
end

return modifierPackage;