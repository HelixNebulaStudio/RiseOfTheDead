local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Shotgun";
	Tier=1;

	Animations={
		Core={Id=123045133841238;};
		PrimaryFire={Id=94597869397556;};
		Reload={Id=83798355489956;};
		Load={Id=74756836685661;};
		Inspect={Id=133379356507494;};
		Sprint={Id=110582874169322};
		Empty={Id=102360623642476;};
		Unequip={Id=126196627858337};
		Idle={Id=92395807073947};
	};

	Audio={
		Load={Id=169799883; Pitch=1; Volume=0.4;};
		PrimaryFire={Id=168413145; Pitch=1; Volume=0.6;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		Reload={Id=5677987779; Pitch=1; Volume=0.6;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Single;
		WeaponType=modWeaponAttributes.WeaponType.Shotgun;
		
		AmmoType="shotgunammo";

		BulletEject="ShotgunBullet";
		BulletEjectDelayTime=0.1;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=60;
		PotentialDamage=624;
		
		MagazineSize=8;
		AmmoCapacity=(8*4);
	
		Rpm=80.59;
		ReloadTime=0.6;
		Multishot={Min=4, Max=6};

		HeadshotMultiplier=0.02;
		EquipLoadTime=0.55;

		StandInaccuracy=7;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.5;
		MovingInaccuracyScale=2.3;

		Piercing=2;

		-- Recoil
		XRecoil=0.1;
		YRecoil=0.6;
		-- Dropoff
		DamageDropoff={
			MinDistance=86;
			MaxDistance=128;
		};
		-- UI
		UISpreadIntensity=5;
		-- Body
		RecoilStregth=math.rad(120);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Shotgun;
		-- Physics
		KillImpulseForce=20;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;