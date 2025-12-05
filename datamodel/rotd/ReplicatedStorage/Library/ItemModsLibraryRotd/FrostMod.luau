local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local statusId = "Frostbite";
local modifierPackage = {
	Name = "Frostbite";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local sLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "S");
	local sValue, sTweakVal = sLayerInfo.Value, sLayerInfo.TweakValue;
	if sTweakVal then
		sValue = sValue + sTweakVal;
	end

	local tLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Values = {
		Radius = sValue;
		Targets = tValue;
	}
end

if RunService:IsServer() then

	function modifierPackage.Binds.OnBulletHit(modifier: ItemModifierInstance, packet: OnBulletHitPacket)
		if packet.TargetModel == nil then return end;
		
		local characterClass: CharacterClass;
		if modifier.Player then
			characterClass = shared.modPlayers.get(modifier.Player);
		end
		
		local healthComp: HealthComp? = modHealthComp.getByModel(packet.TargetModel);
		if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(characterClass) then return end;
	
		if modifier.Values.Counter > 1 then
			modifier.Values.Counter = modifier.Values.Counter -1;
			modifier:Sync({"Counter"});
			return;
		else
			modifier.Values.Counter = 5;
			modifier:Sync({"Counter"})
		end

		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;

		
		local targetClass: ComponentOwner = healthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;
		
		local frostbiteStatusClass: StatusClassInstance = statusComp:GetOrDefault(statusId);
		if frostbiteStatusClass == nil then
			statusComp:Apply(statusId, {
				Expires = workspace:GetServerTimeNow() + 5;
				ApplyBy = characterClass;
				Values = {
					Damage = configurations.Damage; 
					Radius = modifier.Values.Radius;
					Targets = modifier.Values.Targets;
				};
			});
		end
	end

elseif RunService:IsClient() then

	function modifierPackage.Binds.OnWeaponRender(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		if toolStatusHud.Frostbite == nil then
			toolStatusHud.Frostbite = {
				ModItemId = "frostmod";
				Order = 1;
				Text = ``;
			};
		end

		local frostbiteHudData = toolStatusHud.Frostbite;
		if modifier.Values.Counter then
			frostbiteHudData.Text = `{modifier.Values.Counter}`;
			frostbiteHudData.ColorPercent = modifier.Values.Counter/5;
		end
	end

end

return modifierPackage;