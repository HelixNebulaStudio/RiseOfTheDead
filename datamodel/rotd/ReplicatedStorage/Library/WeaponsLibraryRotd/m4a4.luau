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
		Core={Id=88923968392235;};
		PrimaryFire={Id=77503593542774; FocusWeight=0.05};
		Reload={Id=93218667491748;};
		TacticalReload={Id=129908758182155;};
		Load={Id=138698020933254;};
		Inspect={Id=91108936982761;};
		Sprint={Id=138493413350832};
		Empty={Id=105115278683312;};
		Unequip={Id=89539360837699};
		Idle={Id=137418388069757};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1926370239; Pitch=1; Volume=1;};
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
		Damage=30;
		PotentialDamage=612;
		
		MagazineSize=30;
		AmmoCapacity=(30*5);
	
		Rpm=666;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.1;
		EquipLoadTime=0.75;

		StandInaccuracy=2.3;
		FocusInaccuracyReduction=1.2;
		CrouchInaccuracyReduction=0.4;
		MovingInaccuracyScale=3;
		InaccDecaySpeed=1.3;

		-- Recoil
		XRecoil=0.02;
		YRecoil=0.03;
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