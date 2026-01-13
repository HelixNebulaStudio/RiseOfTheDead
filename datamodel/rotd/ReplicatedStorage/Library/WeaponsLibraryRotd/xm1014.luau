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
		Core={Id=93348252047486;};
		PrimaryFire={Id=121781410672221;};
		Reload={Id=93109076287372;};
		Load={Id=116742008633662;};
		Inspect={Id=137561504669780;};
		Sprint={Id=82469941829232};
		Empty={Id=105044054803916;};
		Unequip={Id=126196627858337};
		Idle={Id=80806253952071};
	};

	Audio={
		Load={Id=169799883; Pitch=1; Volume=0.4;};
		PrimaryFire={Id=2697294; Pitch=1; Volume=0.5;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		Reload={Id=5677987779; Pitch=1.1; Volume=0.6;};
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
		Damage=30;
		PotentialDamage=260;
		
		MagazineSize=12;
		AmmoCapacity=(12*4);
	
		Rpm=171.43;
		ReloadTime=0.5;
		Multishot={Min=3; Max=4};

		HeadshotMultiplier=0.02;
		EquipLoadTime=0.55;

		StandInaccuracy=4;
		FocusInaccuracyReduction=0.6;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=2;

		Piercing=1;

		-- Recoil
		XRecoil=0.08;
		YRecoil=0.4;
		-- Dropoff
		DamageDropoff={
			MinDistance=86;
			MaxDistance=160;
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