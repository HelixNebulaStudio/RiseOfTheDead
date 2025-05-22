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
		Core={Id=71683119599975;};
		PrimaryFire={Id=82588390483992; FocusWeight=0.1};
		Reload={Id=97853584691559;};
		TacticalReload={Id=100192705088254;};
		Load={Id=84472745138981;};
		Inspect={Id=91680229640429;};
		Sprint={Id=79812750977400};
		Empty={Id=78171015289849;};
		Unequip={Id=109110694888868};
		Idle={Id=74673251837991;};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1926370458; Pitch=1.1; Volume=1;};
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
		Damage=22;
		PotentialDamage=320;
		
		MagazineSize=64;
		AmmoCapacity=(64*4);
	
		Rpm=600;
		ReloadTime=2.3;
		Multishot=1;

		HeadshotMultiplier=0.05;
		EquipLoadTime=0.6;

		StandInaccuracy=5.2;
		FocusInaccuracyReduction=0;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.5;

		-- Recoil
		XRecoil=0.03;
		YRecoil=0.05;
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