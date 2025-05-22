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
		Core={Id=106976440089912;};
		PrimaryFire={Id=132256512276284;};
		Reload={Id=89576125275043;};
		TacticalReload={Id=136987069567609;};
		Load={Id=70396905445589;};
		Inspect={Id=88589264816751;};
		Sprint={Id=133455721075571};
		Empty={Id=105278438776505;};
		Unequip={Id=127466609333739};
		Idle={Id=115776351566455;};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=2920959; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		LightSlidePull={Id="LightSlidePull"; Preload=true;};
		LightSlideRelease={Id="LightSlideRelease"; Preload=true;};
		LightMagLoad={Id="LightMagLoad"; Preload=true;};
		LightMagUnload={Id="LightMagUnload"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=25;
		PotentialDamage=365;
		
		MagazineSize=15;
		AmmoCapacity=(15*5);
	
		Rpm=330;
		ReloadTime=2.5;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=0.5;

		StandInaccuracy=2;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Recoil
		XRecoil=0.01;
		YRecoil=0.02;
		-- Dropoff
		DamageDropoff={
			MinDistance=100;
			MaxDistance=200;
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