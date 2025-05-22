local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Frenzy";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	if modifier.EquipmentClass == nil then return end;
	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	local fdLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "FD");
	local fdValue = fdLayerInfo.Value;

	local configurations = modifier.EquipmentClass.Configurations;

	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * dValue;

	if configurations.FrenzyDamage == nil then
		modifier.SetValues.FrenzyDamage = fdValue;
		modifier.SumValues.Damage = additionalDmg;
		modifier.MaxValues.FrenzyRate = 0.01;
	end
end

if RunService:IsServer() then

	function modifierPackage.OnTick(modifier: ItemModifierInstance, tickData: TickData)
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

	function modifierPackage.Binds.OnNewDamage(modifier: ItemModifierInstance, damageData: DamageData)
        if modifier.EquipmentClass == nil then return end;
		local configurations = modifier.EquipmentClass.Configurations;
		local preModDmg = configurations.PreModDamage;

		local stackAlpha = modifier.Values.Stacks;
		local additionalDmg = stackAlpha * configurations.FrenzyDamage * preModDmg;
		damageData.Damage = damageData.Damage + additionalDmg;
	end

elseif RunService:IsClient() then

	function modifierPackage.Binds.OnWeaponRender(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		if equipmentClass == nil then return end;

		local configurations = equipmentClass.Configurations;

		local frenzyDmg = configurations.FrenzyDamage;
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

	Debugger:Warn("Frenzy Instancing");
	modifier.OnEnabledChanged:Connect(function(prevVal: boolean)
		Debugger:Warn("Frenzy OnEnabledChanged", modifier.Enabled);
		if modifier.Enabled then
			modifier:SetTickCycle(true);
		else
			modifier:SetTickCycle(false);
		end
	end)

	if not isFirstTime then return end;
	shared.modEventService:OnInvoked("Players_OnDamaged", function(event: EventPacket, damageData: DamageData, damage)
		local playerClass: PlayerClass = (damageData.DamageTo :: PlayerClass);
		if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;
	
		local player: Player = playerClass:GetInstance();
		if player == nil then return end;

		local storageItem: StorageItem? = damageData.StorageItem;
		if storageItem == nil then return end;

        local itemModifierList = playerClass.WieldComp.ItemModifierList;

		for siid, modifier: ItemModifierInstance in pairs(itemModifierList) do
			if modifier.SetValues.FrenzyDamage == nil then continue end;

			if modifier.EquipmentClass == nil then continue end;
			local configurations = modifier.EquipmentClass.Configurations;
			local frenzyRate = configurations.FrenzyRate;

			modifier.Values.Stacks = math.clamp(modifier.Values.Stacks + frenzyRate, 0, 1);
			modifier.Values.CooldownTick = tick()+10;
		end
	end)

end

return modifierPackage;