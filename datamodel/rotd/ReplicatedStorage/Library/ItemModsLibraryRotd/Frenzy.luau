local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Frenzy";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	if modifier.EquipmentClass == nil then return end;
	modItemModifierClass.AddTierDamage(modifier);

	local fdLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "FD");
	local fdValue = fdLayerInfo.Value;

	modifier.Values.FrenzyDamage = fdValue;
	modifier.Values.FrenzyRate = 0.2;
end

if RunService:IsServer() then
	function modifierPackage.BindTickUpdate(modifier: ItemModifierInstance, tickData: TickData)
		if modifier.Values.Stacks == nil then
			modifier.Values.Stacks = 0;
			modifier.Values.CooldownTick = tick();
			modifier.Values.DepleteTick = tick();
		end

		if tick() >= modifier.Values.CooldownTick then
			if tick()-modifier.Values.DepleteTick >= 0.5 then
				modifier.Values.DepleteTick = tick();
				modifier.Values.Stacks = math.clamp(modifier.Values.Stacks -0.01, 0, 1);
			end
		end

		if modifier.Values.LastStacks ~= modifier.Values.Stacks then
			modifier.Values.LastStacks = modifier.Values.Stacks;

			modifier:Sync({"Stacks"});
		end
	end

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner or nil;
		if characterClass == nil then return end;

		local frenzyRate = modifier.Values.FrenzyRate;

		modifier.Values.Stacks = math.clamp(modifier.Values.Stacks + frenzyRate, 0, 1);
		modifier.Values.CooldownTick = tick()+10;
	end

	function modifierPackage.Binds.WeaponShotDamageData(modifier: ItemModifierInstance, damageData: DamageData)
        if modifier.EquipmentClass == nil then return end;
		local configurations = modifier.EquipmentClass.Configurations;
		local preModDmg = configurations.PreModDamage;
		local frenzyDmg = modifier.Values.FrenzyDamage;

		local stackAlpha = modifier.Values.Stacks;
		local additionalDmg = stackAlpha * (frenzyDmg * preModDmg);
		damageData.Damage = damageData.Damage + additionalDmg;
	end

elseif RunService:IsClient() then

	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		if equipmentClass == nil then return end;

		local frenzyDmg = modifier.Values.FrenzyDamage;
		if frenzyDmg == nil then return; end;

		if toolStatusHud.FrenzyDamage == nil then
			toolStatusHud.FrenzyDamage = {
				ModItemId=`frenzydamagemod`;
				Order=1;
				Text="0%";
			};
		end

		if modifier.Values.Stacks then
			local statusInfo = toolStatusHud.FrenzyDamage;

			local alphaRatio = modifier.Values.Stacks;
			local percentFrenzy = math.round(math.clamp(frenzyDmg * alphaRatio, 0, frenzyDmg)*100);
			statusInfo.Text = `{percentFrenzy > 0 and "+" or ""}{percentFrenzy}%`;
			statusInfo.ColorPercent = alphaRatio;
		end
	end

end

function modifierPackage.Instancing(modifier: ItemModifierInstance, isFirstTime: boolean)
	if RunService:IsClient() then return end;

	modifier.OnEnabledChanged:Connect(function(prevVal: boolean)
		if modifier.Enabled then
			modifier:EnableTickUpdate(true);
		else
			modifier:EnableTickUpdate(false);
		end
	end)
end

return modifierPackage;