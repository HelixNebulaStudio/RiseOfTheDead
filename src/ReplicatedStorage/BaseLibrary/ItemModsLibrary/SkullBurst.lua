local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);

local itemModifier = modItemModProperties.new(script);

function itemModifier.Activate(packet)
	local storageItemMod = packet.ModStorageItem;
	local module = packet.WeaponModule;

	local layerInfo = itemModifier.Library.GetLayer("F", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	if module.Configurations.SkullBurst == nil or value > module.Configurations.SkullBurst then
		module.Configurations.SkullBurst = value;

		module:AddModifierTrigger(storageItemMod, itemModifier);
	end
end

if RunService:IsServer() then
	function itemModifier:OnPrimaryFire(ref)
		local configurations = self.WeaponModule.Configurations;
		ref.RawRpm = ref.RawRpm + configurations.SkullBurst;
	end

elseif RunService:IsClient() then
	function itemModifier:OnWeaponRender()
		local weaponStatusDisplay = self.WeaponStatusDisplay;
		local configurations = self.WeaponModule.Configurations;

		if self.SkullBurstStacks == nil then
			self.SkullBurstStacks = 0;
			self.SkullBurstCooldownTick = tick();
			self.SkullBurstDepleteTick = tick();

			weaponStatusDisplay.SkullBurst = {
				ModItemId=`skullburstmod`;
				Order=1;
				Text="0%";
			}
		end

		if tick()-self.SkullBurstCooldownTick >= 10 then
			if tick()-self.SkullBurstDepleteTick >= 0.5 then
				self.SkullBurstDepleteTick = tick();
				self.SkullBurstStacks = math.clamp(self.SkullBurstStacks -0.04, 0, 1);
			end
		end

		local alphaRatio = math.clamp(self.SkullBurstStacks/1, 0, 1);
		local percentRpm = math.round(math.clamp(configurations.SkullBurst * alphaRatio, 0, configurations.SkullBurst)*100);
		weaponStatusDisplay.SkullBurst.Text = `{percentRpm > 0 and "+" or ""}{percentRpm}%`;
		weaponStatusDisplay.SkullBurst.ColorPercent = alphaRatio;
	end

	function itemModifier:OnBulletHit(packet)
		local isHeadshot = packet.IsHeadshot;
		if not isHeadshot then return end;

		if tick()-self.SkullBurstCooldownTick <= 0.1 then return end;

		self.SkullBurstCooldownTick = tick();
		self.SkullBurstStacks = math.clamp(self.SkullBurstStacks +0.05, 0, 1);
	end

	function itemModifier:OnPrimaryFire(ref)
		local configurations = self.WeaponModule.Configurations;
		local properties = self.WeaponModule.Properties;
		
		if self.SkullBurstStacks <= 0 then return end;
		
		local baseRpm = properties.BaseRpm;
		local skullBurstRpm = baseRpm * (configurations.SkullBurst * self.SkullBurstStacks/1);
	
		ref.RawRpm = ref.RawRpm + skullBurstRpm;
	end
	
end


return itemModifier;