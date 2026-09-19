local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local STATUS_ID = "Frostbite";
local modifierPackage = {
	Name = "Frostbite";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
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

	modifier.Properties.Radius = sValue;
	modifier.Properties.Targets = tValue;
end

if RunService:IsServer() then

	function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
		local damageTo: EntityClass? = damageData.DamageTo;
		if damageTo == nil then return end;

		if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
			return;
		end

		if modifier.WieldComp == nil or modifier.WieldComp.CompOwner == nil then return end;
		local characterClass: CharacterClass = modifier.WieldComp.CompOwner :: CharacterClass;

		local targetHealthComp: HealthComp? = damageTo.HealthComp;
		if targetHealthComp == nil then return end;
		if not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;

		local targetClass: EntityClass = targetHealthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;

		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;

		
		if modifier.Properties.Charge == nil then
			modifier.Properties.Charge = 0;
		end

		local rate = (60/configurations.Rpm)/10;
		if modifier.Properties.Cooldown and workspace:GetServerTimeNow() <= modifier.Properties.Cooldown then return end;
		if modifier.Properties.Active ~= true then
			if modifier.Properties.Charge < 1 then
				modifier.Properties.Charge = math.clamp(modifier.Properties.Charge + rate, 0, 1);
				modifier:Sync({"Charge"; "Ready"; "Active"});
				return;
			else
				modifier.Properties.Ready = true;
				modifier:Sync({"Charge"; "Ready"; "Active"});
			end

			return;
		end
		modifier.Properties.Charge = math.clamp(modifier.Properties.Charge - (rate*4), 0, 1);
		if modifier.Properties.Charge <= 0 then
			modifier.Properties.Active = false;
			modifier.Properties.Ready = false;
			modifier.Properties.Cooldown = workspace:GetServerTimeNow()+1;
			modifier:Sync({"Charge"; "Ready"; "Active"});
		else
			modifier:Sync({"Charge";});
		end


		local frostbiteStatusClass: StatusClassInstance = statusComp:GetOrDefault(STATUS_ID);
		if frostbiteStatusClass then
			frostbiteStatusClass.Expires = workspace:GetServerTimeNow() + 8;
			return;
		end;

		statusComp:Apply(STATUS_ID, {
			Expires = workspace:GetServerTimeNow() + 8;
			Duration = 8;
			ApplyBy = characterClass;
			Values = {
				DoIceBlast = true;
				Damage = configurations.PreModDamage;
				Radius = modifier.Properties.Radius;
				Targets = modifier.Properties.Targets;
				StorageItemBy = modifier.EquipmentClass and modifier.EquipmentClass.StorageItem;
				TargetPart = damageData.TargetPart;
			};
		});
	end

	function modifierPackage.Binds.WeaponShotProjectileNew(
		modifier: ItemModifierInstance, 
		projectile: ProjectileInstance
	)
		if not modifier.Properties.Active then return end;
    	local projectilePart = projectile.Part;

		projectilePart.Color = Color3.fromRGB(0, 170, 255);
		projectilePart.Material = Enum.Material.Ice;

		local bulletTracer = projectilePart:FindFirstChild("BulletTracer");
		if bulletTracer then
			bulletTracer.Color = ColorSequence.new(Color3.fromRGB(0, 170, 255));
		end
	end

	function modifierPackage.Binds.WeaponTriggerSpecial(modifier: ItemModifierInstance)
		if modifier.Properties.Active then return end;
		if not modifier.Properties.Ready then return end;

		modifier.Properties.Active = true;
		modifier.Properties.Ready = false;
		modifier:Sync({"Active"; "Ready"; "Charge"});
	end

	function modifierPackage.Binds.PatPrimaryFire(modifier: ItemModifierInstance)
		if not modifier.Properties.Ready then return end;

		modifier.Properties.Active = true;
		modifier.Properties.Ready = false;
		modifier:Sync({"Active"; "Ready"; "Charge"});
	end

elseif RunService:IsClient() then

	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, ...)
		if modifier.Enabled == false then return end;

		local toolHandler: ToolHandlerInstance, toolStatusHud: anydict = ...;

		if toolStatusHud.Frostbite == nil then
			toolStatusHud.Frostbite = {
				ModifierId = modifier.Id;
				ModItemId = "frostmod";
				Order = 1;
				Text = ``;
			};
		end

		local hudData = toolStatusHud.Frostbite;
		if modifier.Properties.Active then
			hudData.Rays = true;
			hudData.Glow = true;
			hudData.KeyString = nil;
		else
			hudData.Rays = false;
			if modifier.Properties.Ready then
				hudData.KeyString = "KeyToggleSpecial";
				hudData.Glow = true;
			else
				hudData.KeyString = nil;
				hudData.Glow = nil;
			end
		end
		local chargeRatio = math.clamp(modifier.Properties.Charge or 0, 0, 1);
		hudData.Text = `{math.round(chargeRatio*100)}%`;
		hudData.ColorPercent = chargeRatio;
	end

end

function modifierPackage.Binds.ApplyWeaponShotTracerColor(modifier: ItemModifierInstance)
	if modifier.Properties.Active then
		return Color3.fromRGB(0, 213, 255);
	end
	return;
end

return modifierPackage;