local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Heavy machine gun";
	Tier=1;

	Animations={
		Core={Id=73424780154646;};
		PrimaryFire={Id=71392862284308; FocusWeight=0.1};
		Reload={Id=93610774709394;};
		Load={Id=87715740341582;};
		Inspect={Id=135062539751933;};
		Sprint={Id=79864064300858};
		Empty={Id=101408908839805;};
		SpinUp={Id=128829394122820;};
	};

	Audio={
		Load={Id=169799883; Pitch=0.4; Volume=0.4;};
		PrimaryFire={Id=1884320340; Pitch=1; Volume=1; Looped=true};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		SpinUp={Id=1896997630; Pitch=1; Volume=0.6;};
		SpinDown={Id=1896998615; Pitch=1; Volume=0.6;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.SpinUp;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="heavyammo";

		BulletEject="HeavyBullet";
		BulletEjectOffset=CFrame.Angles(0, 0, 0);
		
		-- Stats
		Damage=20;
		PotentialDamage=456;
		
		MagazineSize=128;
		AmmoCapacity=(128*4);
	
		Rpm=800;
		ReloadTime=6;
		Multishot=1;

		HeadshotMultiplier=0.1;
		EquipLoadTime=1.3;

		StandInaccuracy=5.5;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.5;
		MovingInaccuracyScale=3;
		InaccDecaySpeed=6;

		-- Spin
		SpinUpTime = 1;
		SpinDownTime = 1.1;

		-- Focus
		FocusWalkSpeedReduction=0.5;

		-- Recoil
		XRecoil=0.03;
		YRecoil=0.08;
		-- Dropoff
		DamageDropoff={
			MinDistance=222;
			MaxDistance=256;
		};
		-- UI
		UISpreadIntensity=5;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable["Heavy machine gun"];
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;