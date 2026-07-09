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

	modifier.Properties.FrenzyDamage = fdValue;
	modifier.Properties.FrenzyRate = 0.2;
end

if RunService:IsServer() then
	function modifierPackage.BindTickUpdate(modifier: ItemModifierInstance, tickData: TickData)
		if modifier.Properties.Stacks == nil then
			modifier.Properties.Stacks = 0;
			modifier.Properties.CooldownTick = tick();
			modifier.Properties.DepleteTick = tick();
		end

		if tick() >= modifier.Properties.CooldownTick then
			if tick()-modifier.Properties.DepleteTick >= 0.5 then
				modifier.Properties.DepleteTick = tick();
				modifier.Properties.Stacks = math.clamp(modifier.Properties.Stacks -0.01, 0, 1);
			end
		end

		if modifier.Properties.LastStacks ~= modifier.Properties.Stacks then
			modifier.Properties.LastStacks = modifier.Properties.Stacks;

			modifier:Sync({"Stacks"});
		end
	end

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass;
		if characterClass == nil then return end;

		local frenzyRate = modifier.Properties.FrenzyRate;

		modifier.Properties.Stacks = math.clamp(modifier.Properties.Stacks + frenzyRate, 0, 1);
		modifier.Properties.CooldownTick = tick()+20;
	end

	function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
        if modifier.EquipmentClass == nil then return end;
		
		if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
			return;
		end
		
		local configurations = modifier.EquipmentClass.Configurations;
		local preModDmg = configurations.PreModDamage;
		local frenzyDmg = modifier.Properties.FrenzyDamage;

		local stackAlpha = modifier.Properties.Stacks;
		local additionalDmg = stackAlpha * (frenzyDmg * preModDmg);
		damageData.Damage = damageData.Damage + additionalDmg;
	end

elseif RunService:IsClient() then

	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, ...)
		if modifier.Enabled == false then return end;

		local toolHandler: ToolHandlerInstance, toolStatusHud: anydict = ...;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		if equipmentClass == nil then return end;

		local frenzyDmg = modifier.Properties.FrenzyDamage;
		if frenzyDmg == nil then return; end;

		if toolStatusHud.FrenzyDamage == nil then
			toolStatusHud.FrenzyDamage = {
				ModItemId = `frenzydamagemod`;
				Order = 1;
				Text = "0%";
			};
		end

		if modifier.Properties.Stacks then
			local statusInfo = toolStatusHud.FrenzyDamage;

			local alphaRatio = modifier.Properties.Stacks;
			local percentFrenzy = math.round(math.clamp(frenzyDmg * alphaRatio, 0, frenzyDmg)*100);
			statusInfo.Text = `{percentFrenzy > 0 and "+" or ""}{percentFrenzy}%`;
			statusInfo.ColorPercent = alphaRatio;
		end
	end

end

function modifierPackage.Instancing(modifier: ItemModifierInstance, isFirstTime: boolean)
	if RunService:IsClient() then return end;

	modifier.OnEnabledChanged:Connect(function()
		if modifier.Enabled then
			modifier:EnableTickUpdate(true);
		else
			modifier:EnableTickUpdate(false);
		end
	end)
end

return modifierPackage;