local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Submachine gun";
	Tier=4;

	Animations={
		Core={Id=72559255441025;};
		PrimaryFire={Id=94653477013260; FocusWeight=0.1};
		Reload={Id=106331252112306;};
		TacticalReload={Id=110913881329529;};
		Load={Id=95814606021951;};
		Inspect={Id=118806824562130;};
		Sprint={Id=120436377699689};
		Empty={Id=128820027972640;};
		Unequip={Id=109110694888868};
		Idle={Id=87298881191116};
	};

	Audio={
		PrimaryFire={Id=8527857141; Pitch=1; Volume=0.5;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		LightMagUnload={Id="LightMagUnload"; Preload=true;};
		MagPrepare={Id="MagPrepare"; Preload=true;};
		LightMagLoad={Id="LightMagLoad"; Preload=true;};
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
		Damage=36;
		PotentialDamage=285;
		
		MagazineSize=32;
		AmmoCapacity=(32*3);
	
		Rpm=1000;
		ReloadTime=3.5;
		Multishot=1;

		HeadshotMultiplier=0.01;
		EquipLoadTime=0.3;

		StandInaccuracy=6;
		FocusInaccuracyReduction=0;
		CrouchInaccuracyReduction=2;
		MovingInaccuracyScale=1.5;

		-- Recoil
		XRecoil=0.04;
		YRecoil=0.1;
		-- Dropoff
		DamageDropoff={
			MinDistance=140;
			MaxDistance=200;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(80);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable["Submachine gun"];
		-- Physics
		KillImpulseForce=5;
		-- Effects
		GenerateMuzzle=false;
	};

	Properties={};
};

function toolPackage.newClass()
	local equipmentClass: EquipmentClass = modEquipmentClass.new(toolPackage);

	equipmentClass:AddBaseModifier("CriticalShot", {
		SumValues={
			CritChance=0.2;
			CritMulti=1;
		};
		ArrayValues = {
			PassiveModifiers = "CriticalShot";
		};
	});

	return equipmentClass;
end

return toolPackage;