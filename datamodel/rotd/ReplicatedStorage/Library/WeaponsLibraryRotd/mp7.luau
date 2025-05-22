local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Submachine gun";
	Tier=1;

	Animations={
		Core={Id=128040329938959;};
		PrimaryFire={Id=104307515285726; FocusWeight=0.1};
		Reload={Id=132535088553121;};
		TacticalReload={Id=115446796819973;};
		Load={Id=140683505932826;};
		Inspect={Id=89934739147636;};
		Sprint={Id=105979725692087};
		Empty={Id=87155278662423;};
		Unequip={Id=109110694888868};
		Idle={Id=97840730780179;};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1926370458; Pitch=1.7; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		WeaponType=modWeaponAttributes.WeaponType.SMG;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=26;
		PotentialDamage=380;
		
		MagazineSize=64;
		AmmoCapacity=(64*4);
	
		Rpm=750;
		ReloadTime=2.3;
		Multishot=1;

		HeadshotMultiplier=0.05;
		EquipLoadTime=0.6;

		StandInaccuracy=6;
		FocusInaccuracyReduction=0;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=2;

		-- Recoil
		XRecoil=0.04;
		YRecoil=0.06;
		-- Dropoff
		DamageDropoff={
			MinDistance=48;
			MaxDistance=100;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(80);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable["Submachine gun"];
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;