local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Explosive";
	Tier=3;

	Animations={
		Core={Id=87795068281795;};
		Inspect={Id=97393780176378;};
		Load={Id=139798738341805;};
		PrimaryFire={Id=109792870472592; FocusWeight=0.2};
		Empty={Id=90459133505253;};
		Reload={Id=113510205572789;};
		Sprint={Id=134668962157630};
		Unequip={Id=76549187208665};
		Idle={Id=135526876095084};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1420705976; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		Reload={Id=6456497676; Pitch=1.1; Volume=0.6;};
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Projectile;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		-- Stats
		Damage=960;
		PotentialDamage=24480;
		
		MagazineSize=1;
		AmmoCapacity=(1*8);
	
		Rpm=120;
		ReloadTime=2.6;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=2;

		StandInaccuracy=5;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;
		
		-- Focus
		FocusWalkSpeedReduction=0.5;

		-- Projectile
		ProjectileId="rpgRocket";

		ExplosionRadius=20;
		ExplosionStun=2.5;

		-- Recoil
		XRecoil=0.05;
		YRecoil=0.05;
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
		-- Effects
		GeneratesBulletHoles=false;
		GenerateBloodEffect=false;
		GenerateTracers=false;
		-- Potential
		BasePotential=0.1;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;