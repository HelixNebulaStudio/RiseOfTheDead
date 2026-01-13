local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Shotgun";
	Tier=2;

	Animations={
		Core={Id=119812751979835;};
		PrimaryFire={Id=91267786732266;};
		Reload={Id=101087315049852;};
		Load={Id=112951965982569;};
		Inspect={Id=125651503210341;};
		Sprint={Id=100237466610388};
		Empty={Id=127657384790191;};
		Unequip={Id=126196627858337};
		Idle={Id=134015118232808};
	};

	Audio={
		Load={Id=169799883; Pitch=1; Volume=0.4;};
		PrimaryFire={Id=185044507; Pitch=1; Volume=2;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		Reload={Id=3299778220; Pitch=0.8; Volume=0.6;};
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
		Damage=100;
		PotentialDamage=870;
		
		MagazineSize=12;
		AmmoCapacity=(12*3);
	
		Rpm=180;
		ReloadTime=0.35;
		Multishot={Min=3, Max=4};

		HeadshotMultiplier=0.02;
		EquipLoadTime=0.5;

		StandInaccuracy=4;
		FocusInaccuracyReduction=0.8;
		CrouchInaccuracyReduction=0.8;
		MovingInaccuracyScale=2;

		Piercing=1;

		-- Recoil
		XRecoil=0.06;
		YRecoil=0.35;
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
