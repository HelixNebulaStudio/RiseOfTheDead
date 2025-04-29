local modWeaponAttributes = require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Sniper";
	Tier=2;

	Animations={
		Core={Id=112622547108213;};
		PrimaryFire={Id=81791535018205; FocusWeight=1};
		Reload={Id=130398168625268;};
		TacticalReload={Id=139685511777769;};
		Load={Id=126717541041189;};
		Inspect={Id=72743764822617;};
		Sprint={Id=106100474749178};
		Empty={Id=95349036734819;};
		Unequip={Id=130105436052579};
		Idle={Id=125865165336390};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=6548742606; Pitch=1.2; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		WeaponType=modWeaponAttributes.WeaponType.Sniper;
		
		AmmoType="sniperammo";

		BulletEject="SniperBullet";
		BulletEjectDelayTime=0.2;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=650;
		PotentialDamage=16575;
		
		MagazineSize=10;
		AmmoCapacity=(10*3);
	
		Rpm=60;
		ReloadTime=3.2;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.5;

		StandInaccuracy=2.4;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.5;
		MovingInaccuracyScale=8;

		-- Focus
		FocusDuration=4;
		FocusWalkSpeedReduction=0.65;
		ChargeDamagePercent=0.2;

		-- Recoil
		XRecoil=0.1;
		YRecoil=0.6;
		-- Dropoff
		DamageDropoff={
			MinDistance=256;
		};
		-- UI
		UISpreadIntensity=4;
		UseScopeGui=true;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Sniper;
		-- Physics
		KillImpulseForce=40;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;