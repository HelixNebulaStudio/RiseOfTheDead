local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Rifle";
	Tier=1;

	Animations={
		Core={Id=101306375716410;};
		PrimaryFire={Id=70943120517800; FocusWeight=0.1};
		Reload={Id=84738551600224;};
		Load={Id=83642360885833;};
		Inspect={Id=77627305926334;};
		Sprint={Id=111816464911275};
		Empty={Id=83248312199973;};
		Unequip={Id=89539360837699};
		Idle={Id=93746259969778};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1926397389; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
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
		Damage=36;
		PotentialDamage=735;
		
		MagazineSize=35;
		AmmoCapacity=(35*5);
	
		Rpm=600;
		ReloadTime=3.5;
		Multishot=1;

		HeadshotMultiplier=0.1;
		EquipLoadTime=0.75;

		StandInaccuracy=2.6;
		FocusInaccuracyReduction=0.7;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=2;
		InaccDecaySpeed=1.6;

		-- Recoil
		XRecoil=0.02;
		YRecoil=0.055;
		-- Dropoff
		DamageDropoff={
			MinDistance=200;
			MaxDistance=400;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(110);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Rifle;
		-- Physics
		KillImpulseForce=10;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;