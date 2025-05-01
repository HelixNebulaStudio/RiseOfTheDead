local modWeaponAttributes = require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Sniper";
	Tier=1;

	Animations={
		Core={Id=107319034723073;};
		PrimaryFire={Id=76079258310936; FocusWeight=1};
		PrimaryFire2={Id=129233040725131; FocusWeight=1};
		Reload={Id=102548326261820;};
		TacticalReload={Id=129855725382622;};
		Load={Id=136249237336011;};
		Inspect={Id=85477377086473;};
		Sprint={Id=102473595783859};
		Empty={Id=97628151291748;};
		Unequip={Id=130105436052579};
		Idle={Id=120549342699367};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1953832141; Pitch=1; Volume=1;};
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
		BulletEjectDelayTime=0.1;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=420;
		PotentialDamage=10710;
		
		MagazineSize=15;
		AmmoCapacity=(15*5);
	
		Rpm=41.24;
		ReloadTime=3;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.65;

		StandInaccuracy=2;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.5;
		MovingInaccuracyScale=8;

		-- Focus
		FocusDuration=3;
		FocusWalkSpeedReduction=0.6;
		ChargeDamagePercent=0.2;

		-- Recoil
		XRecoil=0.12;
		YRecoil=0.56;
		-- Dropoff
		DamageDropoff={
			MinDistance=240;
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