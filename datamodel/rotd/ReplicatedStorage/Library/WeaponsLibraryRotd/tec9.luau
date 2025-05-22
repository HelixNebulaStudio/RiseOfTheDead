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
		Core={Id=135133469120520;};
		Load={Id=125430962645689;};
		PrimaryFire={Id=115330496659351;};
		Reload={Id=85283806936476;};
		TacticalReload={Id=126237372621444;};
		Inspect={Id=120312329588174;};
		Empty={Id=104139692343421;};
		Sprint={Id=98761523775318};
		Idle={Id=108307845393807;};
		Unequip={Id=127466609333739};
	};

	Audio={
		Load={Id=169799883; Pitch=1.1; Volume=0.4;};
		PrimaryFire={Id=273605833; Pitch=1.5; Volume=0.6;};
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
		Damage=25;
		PotentialDamage=365;
		
		MagazineSize=24;
		AmmoCapacity=(24*4);
	
		Rpm=500;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=0.5;

		StandInaccuracy=2.6;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.6;

		-- Recoil
		XRecoil=0.1;
		YRecoil=0.15;
		-- Dropoff
		DamageDropoff={
			MinDistance=86;
			MaxDistance=128;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Pistol;
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;