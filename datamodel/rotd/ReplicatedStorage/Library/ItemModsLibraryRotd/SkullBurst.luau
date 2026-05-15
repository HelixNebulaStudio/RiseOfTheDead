local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Skull Burst";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);

	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "F");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.Properties.SkullBurst = value;
end

if RunService:IsServer() then

	function modifierPackage.Binds.GunPullTrigger(modifier: ItemModifierInstance, packet)
		packet.RawRpm = packet.RawRpm + modifier.Properties.SkullBurst;
	end

elseif RunService:IsClient() then

	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		assert(equipmentClass, `Missing equipment class: {modifier}`);

		local configurations = equipmentClass.Configurations;

		if toolStatusHud.SkullBurst == nil then
			toolStatusHud.SkullBurst = {
				ModItemId=`skullburstmod`;
				Order=1;
				Text="0%";
			};
		end

		local modifierValues = modifier.Properties;
		if modifierValues.SkullBurstStacks == nil then
			modifierValues.SkullBurstStacks = 0;
		end

		local sbCooldownTick = modifier.Properties.SkullBurstCooldownTick;
		if sbCooldownTick == nil or tick()-sbCooldownTick >= 10 then

			local sbDepleteTick = modifierValues.SkullBurstDepleteTick;
			if sbDepleteTick == nil or (tick()-sbDepleteTick >= 0.5) then
				modifierValues.SkullBurstDepleteTick = tick();
				modifierValues.SkullBurstStacks = math.clamp(modifierValues.SkullBurstStacks -0.04, 0, 1);
			end
		end

		local alphaRatio = math.clamp(modifierValues.SkullBurstStacks/1, 0, 1);
		local percentRpm = math.round(math.clamp(modifierValues.SkullBurst * alphaRatio, 0, modifierValues.SkullBurst)*100);
		toolStatusHud.SkullBurst.Text = `{percentRpm > 0 and "+" or ""}{percentRpm}%`;
		toolStatusHud.SkullBurst.ColorPercent = alphaRatio;
	end

	function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
		local targetPart = packet.HitInfo.Part;
		if targetPart == nil then return end;
		if targetPart.Name ~= "Head" and targetPart:GetAttribute("IsHead") ~= true then return end;

		local sbCooldownTick = modifier.Properties.SkullBurstCooldownTick;
		if sbCooldownTick and tick()-sbCooldownTick <= 0.1 then return end;

		modifier.Properties.SkullBurstCooldownTick = tick();
		modifier.Properties.SkullBurstStacks = math.clamp(modifier.Properties.SkullBurstStacks +0.05, 0, 1);
	end

	function modifierPackage.Binds.GunPullTrigger(modifier: ItemModifierInstance, changeRef)
		if modifier.Properties.SkullBurstStacks <= 0 then return end;
		
		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		assert(equipmentClass, `Missing equipment class: {modifier}`);

		local configurations = equipmentClass.Configurations;

		local baseRpm = configurations.Rpm;
		local alpha = modifier.Properties.SkullBurstStacks/1
		local skullBurstRpm = baseRpm * (modifier.Properties.SkullBurst * alpha);

		changeRef.RawRpm = changeRef.RawRpm + skullBurstRpm;
	end
	
end

return modifierPackage;