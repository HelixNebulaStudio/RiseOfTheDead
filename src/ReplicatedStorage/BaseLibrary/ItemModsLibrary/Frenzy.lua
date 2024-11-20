local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);

local itemModifier = modItemModProperties.new(script);
itemModifier.TriggerType = itemModifier.Library.TriggerType.OnBulletHit;

function itemModifier.Activate(packet)
	local storageItemMod = packet.ModStorageItem;
	local module = packet.WeaponModule;
	
	local dLayerInfo = itemModifier.Library.GetLayer("D", packet);
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local fdLayerInfo = itemModifier.Library.GetLayer("FD", packet);
	local fdValue = fdLayerInfo.Value;

	local baseDamage = module.Configurations.PreModDamage;
	local additionalDmg = baseDamage * dValue;

	if module.Configurations.FrenzyDamage == nil then
		module.Configurations.FrenzyDamage = fdValue;
		module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	
		module:AddModifierTrigger(storageItemMod, itemModifier);
	end
end

if RunService:IsServer() then
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	modOnGameEvents:ConnectEvent("OnPlayerDamaged", function(player, damageSource, damage)
		local classPlayer = shared.modPlayers.Get(player);

		local initDmg = damageSource.InitDamage;
		local hpDmgRatio = initDmg/classPlayer.MaxHealth;

		print("Frenzy OnPlayerDamaged", initDmg, hpDmgRatio);
		
		local profile = shared.modProfile:Get(player);
		local storageItemID = profile and profile.EquippedTools and profile.EquippedTools.ID;
		if storageItemID == nil then return end;

		local weaponModule = profile:GetItemClass(storageItemID);
		if weaponModule == nil or weaponModule.Configurations == nil or weaponModule.Configurations.FrenzyDamage == nil then return end;

		local itemModifier = weaponModule.ModifierTriggers[script.Name];
		if itemModifier == nil then return end;

		print("Charge frenzy", itemModifier);
		
		itemModifier.Stacks = math.clamp(itemModifier.Stacks + initDmg *0.01, 0, 1);
		itemModifier.CooldownTick = tick()+10;
	end)

	function itemModifier:OnUpdate()
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

		if self.StorageItem and self.LastStacks ~= self.Stacks then
			self.LastStacks = self.Stacks;

			self:Sync({"Stacks"});
		end
	end

	function itemModifier:OnDeactivate()
		Debugger:StudioLog("Deactivate");
		self.Stacks = 0;
		self.CooldownTick = tick();
		self.DepleteTick = tick();
	end

elseif RunService:IsClient() then

	function itemModifier:OnWeaponRender()
		local weaponStatusDisplay = self.WeaponStatusDisplay;
		local configurations = self.WeaponModule.Configurations;

		local frenzyDmg = configurations.FrenzyDamage;

		if self.Stacks then
			if weaponStatusDisplay.FrenzyDamage == nil then
				weaponStatusDisplay.FrenzyDamage = {
					ModItemId=`frenzydamagemod`;
					Order=1;
					Text="0%";
				};
			end
			local statusInfo = weaponStatusDisplay.FrenzyDamage;

			local alphaRatio = self.Stacks;
			local percentFrenzy = math.round(math.clamp(frenzyDmg * alphaRatio, 0, frenzyDmg)*100);
			statusInfo.Text = `{percentFrenzy > 0 and "+" or ""}{percentFrenzy}%`;
			statusInfo.ColorPercent = alphaRatio;
		end

	end

end

return itemModifier;