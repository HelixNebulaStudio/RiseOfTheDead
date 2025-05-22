local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Pistol";
	Tier=1;

	Animations={
		Core={Id=74139870889569;};
		PrimaryFire={Id=101753791713642;};
		Reload={Id=76704583558755;};
		TacticalReload={Id=110960139338373;};
		Load={Id=71780611626513;};
		Inspect={Id=95711599651337;};
		Sprint={Id=98761523775318};
		Empty={Id=82796095029912;};
		Unequip={Id=127466609333739};
		Idle={Id=74318408349078;};
	
		SpecialReload={Id=134203123804957;};
		SpecialLoad={Id=93932634098637;};
	};

	Audio={
		Load={Id=169799883; Pitch=1.5; Volume=0.4;};
		PrimaryFire={Id=2920959; Pitch=1.4; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=20;
		PotentialDamage=290;
		DamageRev=2;
		
		MagazineSize=16;
		AmmoCapacity=(16*4);
	
		Rpm=400;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=0.4;

		StandInaccuracy=2;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Recoil
		XRecoil=0.02;
		YRecoil=0.04;
		-- Dropoff
		DamageDropoff={
			MinDistance=64;
			MaxDistance=100;
		};
		-- UI
		UISpreadIntensity=5;
		-- Body
		RecoilStregth=math.rad(60);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Pistol;
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};

function toolPackage.DoSpecialLoad(handler: ToolHandlerInstance)
	local equipmentClass = handler.EquipmentClass;
	local configurations = equipmentClass.Configurations;
	local itemValues = handler.StorageItem.Values;
	
	if itemValues.MA and itemValues.MA <= configurations.AmmoCapacity then
		return "SpecialLoad";
	end
	return "Load";
end

function toolPackage.DoSpecialReload(handler: ToolHandlerInstance)
	local equipmentClass = handler.EquipmentClass;
	local properties = equipmentClass.Properties;
	local toolModel = handler.Prefabs[1];
	
	local magazine2 = toolModel:FindFirstChild("Magazine2");
	if magazine2 and magazine2.Transparency == 1 then
		
		if properties.Ammo > 0 then
			return "TacticalReload";
		end
		return "SpecialLoad";
	end
	return "Reload";
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;
