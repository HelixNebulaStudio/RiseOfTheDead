local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Pistol";
	Tier=3;

	Animations={
		Core={Id=86638305514387;};
		Load={Id=71655578766028;};
		PrimaryFire={Id=130434666154513;};
		Reload={Id=105967635270888;};
		TacticalReload={Id=134104462785864;};
		Inspect={Id=79093773598307;};
		Empty={Id=104090479951422;};
		Sprint={Id=93820486544159};
		Idle={Id=128179753706471;};
		Unequip={Id=127466609333739};
	};

	Audio={
		Load={Id=169799883; Pitch=1.5; Volume=0.4;};
		PrimaryFire={Id=1943677171; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="lightammo";

		BulletEject="DeagleBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=260;
		PotentialDamage=5200;
		
		MagazineSize=8;
		AmmoCapacity=(8*4);
	
		Rpm=266;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=1;
		EquipLoadTime=0.5;

		StandInaccuracy=4;
		FocusInaccuracyReduction=0.7;
		CrouchInaccuracyReduction=0.7;
		MovingInaccuracyScale=1.6;

		-- Focus
		FocusDuration=0.5;
		FocusWalkSpeedReduction=0.65;
		ChargeDamagePercent=0.5;

		-- Recoil
		XRecoil=0.1;
		YRecoil=0.24;
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
