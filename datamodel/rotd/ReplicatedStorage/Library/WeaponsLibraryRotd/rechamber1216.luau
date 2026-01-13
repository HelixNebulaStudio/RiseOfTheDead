local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Shotgun";
	Tier=5;

	Animations={
		Core={Id=118165259321661;};
		PrimaryFire={Id=105143866671646;};
		Rechamber={Id=104823008777529;};
		Reload={Id=78609558013599;};
		TacticalReload={Id=114901408445746;}; 
		Load={Id=123553649109228;};
		Inspect={Id=78694668343797;};
		Sprint={Id=112949620867848};
		Empty={Id=112949620867848;};
		LastFire={Id=103834737888365;};
		Unequip={Id=126196627858337};
		Idle={Id=116654596081777};
	};

	Audio={
		Load={Id=169799883; Pitch=1.3; Volume=0.4;};
		PrimaryFire={Id=72945517149917; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		ShotgunHandle={Id="ShotgunHandle"; Preload=true;};
		ShotgunPump2={Id="ShotgunPump2"; Preload=true;};
		LoadShotgunShell={Id="LoadShotgunShell"; Preload=true;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		WeaponType=modWeaponAttributes.WeaponType.Shotgun;
		
		AmmoType="shotgunammo";

		BulletEject="ShotgunBullet";
		BulletEjectDelayTime=0.1;
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=80;
		PotentialDamage=2050;
		
		MagazineSize=16;
		AmmoCapacity=(16*3);
	
		Rpm=100;
		ReloadTime=3;
		Multishot={Min=4, Max=4};

		HeadshotMultiplier=0.02;
		EquipLoadTime=1;

		StandInaccuracy=4;
		FocusInaccuracyReduction=0.8;
		CrouchInaccuracyReduction=0.8;
		MovingInaccuracyScale=4;

		Piercing=1;

		-- Recoil
		XRecoil=0.08;
		YRecoil=0.4;
		-- Dropoff
		DamageDropoff={
			MinDistance=86;
			MaxDistance=128;
		};
		-- UI
		UISpreadIntensity=6;
		-- Body
		RecoilStregth=math.rad(120);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Shotgun;
		-- Physics
		KillImpulseForce=20;
	};

	Properties={};
};

function toolPackage.newClass()
	local equipmentClass: EquipmentClass = modEquipmentClass.new(toolPackage);

    equipmentClass:AddBaseModifier("KnockoutTrigger", {
		SetValues = {
			KnockoutDistance = 8;
			KnockoutDuration = 2;
		};
		ArrayValues = {
			PassiveModifiers = "KnockoutTrigger";
		};
	});
	
	return equipmentClass;
end

return toolPackage;