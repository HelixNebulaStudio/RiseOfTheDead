local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);

local ItemModifier = modItemModifierClass.new(script);
--==

function ItemModifier:Update()
	local dLayerInfo = ItemModifier.Library.calculateLayer(self, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	local fdLayerInfo = ItemModifier.Library.calculateLayer(self, "FD");
	local fdValue = fdLayerInfo.Value;

	local configurations = self.EquipmentClass.Configurations;

	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * dValue;

	if configurations.FrenzyDamage == nil then
		self.SetValues.FrenzyDamage = fdValue;
		self.AddValues.Damage = additionalDmg;
	end
end

if RunService:IsServer() then
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnPlayerDamaged", function(player, damageSource, damage)
		local initDmg = damageSource.InitDamage;
		
		local profile = shared.modProfile:Get(player);
		local storageItemID = profile and profile.EquippedTools and profile.EquippedTools.ID;
		if storageItemID == nil then return end;

        local itemModifierList = shared.modPlayerEquipment.getPlayerItemModifiers(player);

		for siid, itemModifier in pairs(itemModifierList) do
			if itemModifier.SetValues.FrenzyDamage == nil then continue end;

			itemModifier.Stacks = math.clamp(itemModifier.Stacks + initDmg *0.01, 0, 1);
			itemModifier.CooldownTick = tick()+10;
		end
	end)

	function ItemModifier:OnNewDamageSource(damageSource)
		local configurations = self.EquipmentClass.Configurations;
		local preModDmg = configurations.PreModDamage;

		local stackAlpha = self.Stacks;
		local additionalDmg = stackAlpha * configurations.FrenzyDamage * preModDmg;
		damageSource.Damage = damageSource.Damage + additionalDmg;
	end

	function ItemModifier:OnTick(delta)
		if self.Stacks == nil then
			self.Stacks = 0;
			self.CooldownTick = tick();
			self.DepleteTick = tick();
		end
	
		if tick() >= self.CooldownTick then
			if tick()-self.DepleteTick >= 0.5 then
				self.DepleteTick = tick();
				self.Stacks = math.clamp(self.Stacks -0.01, 0, 1);
			end
		end
	
		if self.LastStacks ~= self.Stacks then
			self.LastStacks = self.Stacks;
	
			self:Sync({"Stacks"});
		end
	end

	function ItemModifier:Attach()
		self:SetTickCycle(true);
	end

	function ItemModifier:Detach()
		self:SetTickCycle(false);
	end


elseif RunService:IsClient() then
	function ItemModifier:OnWeaponRender(weaponStatusDisplay)
		if self.Enabled == false then return end;

		local configurations = self.EquipmentClass.Configurations;

		local frenzyDmg = configurations.FrenzyDamage;
		if frenzyDmg == nil then return; end;

		if weaponStatusDisplay.FrenzyDamage == nil then
			weaponStatusDisplay.FrenzyDamage = {
				ModItemId=`frenzydamagemod`;
				Order=1;
				Text="0%";
			};
		end
		if self.Stacks then
			local statusInfo = weaponStatusDisplay.FrenzyDamage;

			local alphaRatio = self.Stacks;
			local percentFrenzy = math.round(math.clamp(frenzyDmg * alphaRatio, 0, frenzyDmg)*100);
			statusInfo.Text = `{percentFrenzy > 0 and "+" or ""}{percentFrenzy}%`;
			statusInfo.ColorPercent = alphaRatio;
		end

	end

end

return ItemModifier;
