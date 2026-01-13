local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Pistol";
	Tier=2;
	
	Welds={
		LeftToolGrip="p250";
		RightToolGrip="p250";
	};

	Animations={
		Core={Id=94657217084382;};
		Focus={Id=78879468422870; StopOnAction=true;};
		Load={Id=96980470567747;};
		PrimaryFire={Id=138523169091547;};
		Reload={Id=131674293143074;};
		TacticalReload={Id=139502247497213;};
		Inspect={Id=85691639179257;};
		Empty={Id=95287193416992;};
		Idle={Id=105318026176191;};
		Unequip={Id=81815911350146};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=2920959; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		Reload={Id=6876277137; Pitch=0.8; Volume=0.6;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		TriggerCycleDelay=0.1;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectDelayTime=0.2;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=35;
		PotentialDamage=520;
		
		MagazineSize=30;
		AmmoCapacity=(30*3);
	
		Rpm=200;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=0.5;

		StandInaccuracy=2;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Recoil
		XRecoil=0.02;
		YRecoil=0.04;
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