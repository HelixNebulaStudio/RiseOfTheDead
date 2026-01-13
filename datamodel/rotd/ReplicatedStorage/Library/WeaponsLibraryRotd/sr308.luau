local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Rifle";
	Tier=3;

	Animations={
		Core={Id=85506703518501;};
		PrimaryFire={Id=86732742570968; FocusWeight=0.1};
		Reload={Id=104082389321241;};
		TacticalReload={Id=82291281306811;};
		Load={Id=131796814309386;};
		Inspect={Id=93210490423754;};
		Sprint={Id=88758222364714};
		Empty={Id=72960463780772;};
		Unequip={Id=89539360837699};
		Idle={Id=107692371524559};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=7105581785; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		BRSlidePull={Id="BRSlidePull"; Preload=true;};
		BRSlideRelease={Id="BRSlideRelease"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		WeaponType=modWeaponAttributes.WeaponType.Rifle;
		
		AmmoType="heavyammo";

		BulletEject="RifleBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=64;
		PotentialDamage=1090;
		
		MagazineSize=28;
		AmmoCapacity=(28*3);
	
		Rpm=360;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.05;
		EquipLoadTime=1.2;

		StandInaccuracy=3;
		FocusInaccuracyReduction=1.2;
		CrouchInaccuracyReduction=0.4;
		MovingInaccuracyScale=3;
		InaccDecaySpeed=1;

		-- Recoil
		XRecoil=0.06;
		YRecoil=0.1;
		-- Dropoff
		DamageDropoff={
			MinDistance=260;
			MaxDistance=400;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(110);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Rifle;
		-- Physics
		KillImpulseForce=20;
	};

	Properties={};
};

function toolPackage.newClass()
	local equipmentClass: EquipmentClass = modEquipmentClass.new(toolPackage);

	equipmentClass:AddBaseModifier("CriticalShot", {
		SumValues = {
			CritChance = 0.3;
			CritMulti = 0.5;
		};
		ArrayValues = {
			PassiveModifiers = "CriticalShot";
		};
	});

	return equipmentClass;
end

return toolPackage;