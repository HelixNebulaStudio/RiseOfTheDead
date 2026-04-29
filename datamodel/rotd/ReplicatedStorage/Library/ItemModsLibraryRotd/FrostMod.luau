local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modHealthComp = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local statusId = "Frostbite";
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

	function modifierPackage.Binds.WeaponShotBulletHit(modifier: ItemModifierInstance, packet: BulletHitData)
		if packet.TargetModel == nil then return end;
		
		local characterClass: CharacterClass = (modifier.WieldComp and modifier.WieldComp.CompOwner or nil) :: CharacterClass;
		if characterClass == nil then return end;
		
		local targetHealthComp: HealthComp? = modHealthComp.getByModel(packet.TargetModel);
		if targetHealthComp == nil then return end;
		if targetHealthComp.IsDead or not targetHealthComp:CanTakeDamageFrom(characterClass) then return end;
	
		local targetClass: EntityClass = targetHealthComp.CompOwner;
		local statusComp: StatusComp? = targetClass.StatusComp;
		if statusComp == nil then return end;

		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;

		
		if modifier.Properties.Charge == nil then
			modifier.Properties.Charge = 0;
		end

		local rate = (60/configurations.Rpm)/5;
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


		local frostbiteStatusClass: StatusClassInstance = statusComp:GetOrDefault(statusId);
		if frostbiteStatusClass then
			frostbiteStatusClass.Expires = workspace:GetServerTimeNow() + 5;
			return;
		end;

		statusComp:Apply(statusId, {
			Expires = workspace:GetServerTimeNow() + 5;
			Duration = 5;
			ApplyBy = characterClass;
			Values = {
				DoIceBlast = true;
				Damage = configurations.PreModDamage;
				Radius = modifier.Properties.Radius;
				Targets = modifier.Properties.Targets;
				StorageItemBy = modifier.EquipmentClass and modifier.EquipmentClass.StorageItem;
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

	function modifierPackage.Binds.WeaponShotProjectileHit(
		modifier: ItemModifierInstance, 
		projectile: ProjectileInstance, 
		arcPoint: ArcPoint
	)
		if arcPoint.Hit == nil then return end;

		local targetModel = arcPoint.Hit.Parent;
		if targetModel == nil then return end;


		local targetHealthComp: HealthComp? = modHealthComp.getByModel(targetModel);
		if targetHealthComp == nil then return end;
		targetModel = targetHealthComp:GetModel();

		modifierPackage.Binds.WeaponShotBulletHit(modifier, {
			TargetModel = targetModel;
		} :: BulletHitData);
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

	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

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