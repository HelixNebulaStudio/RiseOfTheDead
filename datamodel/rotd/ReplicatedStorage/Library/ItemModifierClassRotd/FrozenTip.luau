local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local STATUS_ID = "Frostbite";
local STATUS_DURATION = 1;
local MOD_COOLDOWN = 2;

local modifierPackage = {
	Name = "Frozen Tip";
	
	Tags = {};
	Binds = {};
};
--==

if RunService:IsServer() then
    function modifierPackage.Binds.MeleeDamageDataNew(modifier: ItemModifierInstance, damageData: DamageData)
        local curTime = workspace:GetServerTimeNow();

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

		local frostbiteStatusClass: StatusClassInstance = statusComp:GetOrDefault(STATUS_ID);
		if frostbiteStatusClass then
			return;
		end;

        local equipmentClass = modifier.EquipmentClass;
        if equipmentClass == nil then return end;

		if modifier.Properties.CooldownTick and curTime < modifier.Properties.CooldownTick then
			return;
		end
		modifier.Properties.CooldownTick = curTime + MOD_COOLDOWN;
		modifier:Sync({"CooldownTick"});
        
        local storageItem = equipmentClass.StorageItem;
		local configurations = equipmentClass.Configurations;

		statusComp:Apply(STATUS_ID, {
			Expires = curTime + STATUS_DURATION;
			Duration = STATUS_DURATION;
			ApplyBy = characterClass;
			Values = {
				DoIceBlast = false;
				Damage = configurations.PreModDamage;
				StorageItemBy = storageItem;
				TargetPart = damageData.TargetPart;
				_ToolHandler = damageData.ToolHandler;
			};
		});
    end

elseif RunService:IsClient() then
	
	function modifierPackage.Binds.WeaponRenderStepped(modifier: ItemModifierInstance, toolStatusHud: anydict)
		if modifier.Enabled == false then return end;

		local equipmentClass: EquipmentClass? = modifier.EquipmentClass;
		assert(equipmentClass, `Missing equipment class: {modifier}`);

		local configurations = equipmentClass.Configurations;

		if toolStatusHud.FrozenTip == nil then
			toolStatusHud.FrozenTip = {
				Order = 1;
				Text = "";
				Icon = "rbxassetid://3576197517";
				Color = Color3.fromRGB(0, 183, 255):ToHex();
			};
		end

        local curTime = workspace:GetServerTimeNow();

		local modifierValues = modifier.Properties;
        local cooldownTl = (modifierValues.CooldownTick or curTime-MOD_COOLDOWN) - curTime;
        toolStatusHud.FrozenTip.ColorPercent = 1-math.clamp(cooldownTl/MOD_COOLDOWN, 0, 1);
	end

end


return modifierPackage;