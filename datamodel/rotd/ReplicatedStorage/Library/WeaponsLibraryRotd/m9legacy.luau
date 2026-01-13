local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Pistol";
	Tier=2;

	Animations={
		Core={Id=96110447359788;};
		Load={Id=94539982728281;};
		PrimaryFire={Id=80035842198542;};
		Reload={Id=127297547906446;};
		Inspect={Id=138270425682397;};
		Empty={Id=100802504065200;};
		Unequip={Id=127466609333739};
		TacticalReload={Id=86523319939547;};
		Idle={Id=73258199716672;};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=2757012511; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
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
		Damage=65;
		PotentialDamage=820;
		
		MagazineSize=15;
		AmmoCapacity=(15*4);
	
		Rpm=300;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=1.5;
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