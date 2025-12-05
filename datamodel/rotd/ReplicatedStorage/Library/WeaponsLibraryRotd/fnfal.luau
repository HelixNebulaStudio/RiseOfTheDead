local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Rifle";
	Tier=2;

	Animations={
		Core={Id=136087224487951;};
		PrimaryFire={Id=120589391472868; FocusWeight=0.05};
		Reload={Id=89984982837073;};
		TacticalReload={Id=131273080192457;};
		Load={Id=98946135156629;};
		Inspect={Id=130962548424509;};
		Sprint={Id=106459353295371};
		Empty={Id=93908403390031;};
		Unequip={Id=89539360837699};
		Idle={Id=125317487530511};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=1926397389; Pitch=0.6; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0.5;};
		Reload={Id=144798533; Pitch=1; Volume=0.6;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Hitscan;
		TriggerMode=modWeaponAttributes.TriggerModes.Automatic;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		WeaponType=modWeaponAttributes.WeaponType.Rifle;
		
		AmmoType="heavyammo";

		BulletEject="RifleBullet";
		BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);
		
		-- Stats
		Damage=42;
		PotentialDamage=857;
		
		MagazineSize=25;
		AmmoCapacity=(25*4);
	
		Rpm=700;
		ReloadTime=1.5;
		Multishot=1;

		HeadshotMultiplier=0.1;
		EquipLoadTime=1;

		StandInaccuracy=2.6;
		FocusInaccuracyReduction=0.7;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=2.5;
		InaccDecaySpeed=0.5;

		-- Recoil
		XRecoil=0.02;
		YRecoil=0.05;
		-- Dropoff
		DamageDropoff={
			MinDistance=200;
			MaxDistance=400;
		};
		-- UI
		UISpreadIntensity=4;
		-- Body
		RecoilStregth=math.rad(90);
		-- Penetration
		Penetration=modWeaponAttributes.PenetrationTable.Rifle;
		-- Physics
		KillImpulseForce=5;
	};

	Properties={};
};

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;