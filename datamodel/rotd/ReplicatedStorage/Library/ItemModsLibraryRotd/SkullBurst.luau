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
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "F");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.Values.SkullBurst = value;
end

if RunService:IsServer() then

	function modifierPackage.Binds.OnPrimaryFire(modifier: ItemModifierInstance, packet)
		packet.RawRpm = packet.RawRpm + modifier.Values.SkullBurst;
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

		local modifierValues = modifier.Values;
		if modifierValues.SkullBurstCooldownTick == nil or tick()-modifierValues.SkullBurstCooldownTick >= 10 then
			if modifierValues.SkullBurstDepleteTick == nil or (tick()-modifierValues.SkullBurstDepleteTick >= 0.5) then
				modifierValues.SkullBurstDepleteTick = tick();
				modifierValues.SkullBurstStacks = math.clamp(modifierValues.SkullBurstStacks -0.04, 0, 1);
			end
		end
		if modifierValues.SkullBurstStacks == nil then
			modifierValues.SkullBurstStacks = 0;
		end

		local alphaRatio = math.clamp(modifierValues.SkullBurstStacks/1, 0, 1);
		local percentRpm = math.round(math.clamp(configurations.SkullBurst * alphaRatio, 0, configurations.SkullBurst)*100);
		toolStatusHud.SkullBurst.Text = `{percentRpm > 0 and "+" or ""}{percentRpm}%`;
		toolStatusHud.SkullBurst.ColorPercent = alphaRatio;
	end

	function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
		local targetPart = packet.HitInfo.Part;
		if targetPart == nil then return end;
		if targetPart.Name ~= "Head" and targetPart:GetAttribute("IsHead") ~= true then return end;
		if tick()-modifier.Values.SkullBurstCooldownTick <= 0.1 then return end;

		modifier.Values.SkullBurstCooldownTick = tick();
		modifier.Values.SkullBurstStacks = math.clamp(modifier.Values.SkullBurstStacks +0.05, 0, 1);
	end

	function modifierPackage.Binds.OnPrimaryFire(modifier: ItemModifierInstance, packet)
		if modifier.Values.SkullBurstStacks <= 0 then return end;
		
		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		assert(equipmentClass, `Missing equipment class: {modifier}`);

		local configurations = equipmentClass.Configurations;

		local baseRpm = configurations.Rpm;
		local skullBurstRpm = baseRpm * (configurations.SkullBurst * modifier.Values.SkullBurstStacks/1);
	
		packet.RawRpm = packet.RawRpm + skullBurstRpm;
	end
	
end

return modifierPackage;