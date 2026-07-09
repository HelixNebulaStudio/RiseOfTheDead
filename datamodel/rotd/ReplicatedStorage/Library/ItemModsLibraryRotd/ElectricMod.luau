local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local statusKey = "Electrocute";

local modifierPackage = {
	Name = "Electrocute";
	
	Tags = {};
	Binds = {};
	Properties = {
		CooldownDuration = 3;
	};
};
--==
function modifierPackage.onRequire()
	templateElectricCharge = game.ReplicatedStorage.Particles:WaitForChild("ElectricCharge");
end

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local tLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "T");
	local tValue, tTweakVal = tLayerInfo.Value, tLayerInfo.TweakValue;
	if tTweakVal then
		tValue = tValue + tTweakVal;
	end

	modifier.Properties.Targets = math.ceil(tValue);
	modifier.Properties.DamagePercent = dValue;
end

if RunService:IsServer() then

	function modifierPackage.Binds.WeaponShotPreProcess(modifier: ItemModifierInstance, packet)
		if modifier.Properties.CooldownTick and workspace:GetServerTimeNow() <= modifier.Properties.CooldownTick then return end;
		modifier.Properties.CooldownTick = workspace:GetServerTimeNow() + modifier.Properties.CooldownDuration;
		modifier:Sync({"CooldownTick"});
		modifier.Properties.Active = true;
	end

	function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
		local damageTo: EntityClass? = damageData.DamageTo;
		if damageTo == nil then return end;

		if damageData.ToolHandler == nil or modifier.EquipmentClass ~= damageData.ToolHandler.EquipmentClass then
			return;
		end
		
		if not modifier.Properties.Active then return end;
		modifier.Properties.Active = false;
		modifier:Sync({"CooldownTick"});

		if modifier.WieldComp == nil or modifier.WieldComp.CompOwner == nil then return end;
		local characterClass: CharacterClass = modifier.WieldComp.CompOwner :: CharacterClass;

		local targetHealthComp: HealthComp? = damageTo.HealthComp;
		if targetHealthComp == nil then return end;

		local targetPart = damageData.TargetPart;
		if targetPart == nil then return end;
		
		local targetCharClass: EntityClass = targetHealthComp.CompOwner;
		local statusComp: StatusComp? = targetCharClass.StatusComp;
		if statusComp == nil then return end;

		local statusClass: StatusClassInstance? = statusComp:GetOrDefault(statusKey);
		if statusClass then return end;

		local maxTargets = modifier.Properties.Targets;
		local damagePercent = modifier.Properties.DamagePercent;
		local configurations = modifier.EquipmentClass and modifier.EquipmentClass.Configurations;
		local storageItemBy = modifier.EquipmentClass and modifier.EquipmentClass.StorageItem;

		local mainToolModel = modifier.WieldComp.ToolHandler and modifier.WieldComp.ToolHandler.MainToolModel or nil;
		local originAtt = mainToolModel and mainToolModel.PrimaryPart and mainToolModel.PrimaryPart:FindFirstChild("BulletOrigin");
		if originAtt == nil then return end;

		statusComp:Apply(statusKey, {
			Expires = workspace:GetServerTimeNow()+2;
			ApplyBy = characterClass;
			Values = {
				WeakRoot = 1;

				MaxTargets = maxTargets;
				StorageItemBy = storageItemBy;
				
				OriginAtt = originAtt;
				HitPart = targetPart;
				
				Damage = configurations.PreModDamage;
				DamagePercent = damagePercent;

				TargetsHit = 0;
			};
		});
	end
	
	function modifierPackage.Binds.WeaponShotProjectileNew(modifier: ItemModifierInstance, projectile: ProjectileInstance)
		if not modifier.Properties.Active then return end;
    	local projectilePart = projectile.Part;

		projectilePart.Color = Color3.fromRGB(255, 253, 139);
		projectilePart.Material = Enum.Material.Cobblestone;
		if projectilePart:IsA("MeshPart") then
			projectilePart.TextureID = "";
		end

		local bulletTracer = projectilePart:FindFirstChild("BulletTracer");
		if bulletTracer then
			bulletTracer.Color = ColorSequence.new(Color3.fromRGB(255, 253, 139));
		end

		local newElectricParticle = templateElectricCharge:Clone();
		newElectricParticle.Parent = projectilePart;
	end

else
	
	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, ...)
		if modifier.Enabled == false then return end;

		local toolHandler: ToolHandlerInstance, toolStatusHud: anydict = ...;

		if toolStatusHud.Electrocute == nil then
			toolStatusHud.Electrocute = {
				ModifierId = modifier.Id;
				ModItemId = "electricmod";
				Order = 1;
				Text = ``;
			};
		end

		local hudData = toolStatusHud.Electrocute;

		local cooldownTick = modifier.Properties.CooldownTick;
		local charge = 1;
		if cooldownTick then
			charge = 1-math.clamp((cooldownTick-workspace:GetServerTimeNow())/modifier.Properties.CooldownDuration, 0, 1);
		end
		hudData.ColorPercent = charge;
	end

end

return modifierPackage;