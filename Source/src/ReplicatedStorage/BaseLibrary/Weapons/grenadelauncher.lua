local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Explosive";
	Tier=2;

	Animations={
		Core={Id=94828859106600;};
		PrimaryFire={Id=104759963599356; FocusWeight=0.2};
		Reload={Id=70499051411013;};
		Inspect={Id=122320237597281;};
		Load={Id=100129964580240;};
		Empty={Id=99515397778043;};
		Sprint={Id=107005249042028};
		Unequip={Id=105508427477788};
		Idle={Id=98099690709645};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=9140961699; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Projectile;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		AmmoType="lightammo";

		BulletEject="PistolBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=420;
		PotentialDamage=14000;
		
		MagazineSize=9;
		AmmoCapacity=(9*3);
	
		Rpm=66;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.2;

		StandInaccuracy=1.8;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Projectile
		ProjectileId="50mmGrenade";
		
		ExplosionRadius=12;
		ExplosionStun=1;

		-- Focus
		FocusWalkSpeedReduction=0.55;

		-- Recoil
		XRecoil=0.06;
		YRecoil=0.1;
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
		BasePotential=0.35;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;