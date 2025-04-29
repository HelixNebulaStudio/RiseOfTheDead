local modWeaponAttributes = require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Submachine gun";
	Tier=5;

	Welds={
		LeftToolGrip="uzi";
		RightToolGrip="uzi";
	};

	Animations={
		Core={Id=126034135725918;};
		Focus={Id=118899371239210; StopOnAction=true;};
		PrimaryFire={Id=98077776698027; FocusWeight=0.1};
		Reload={Id=130544394991587;};
		TacticalReload={Id=99637654848858;};
		Load={Id=101275692995419;};
		Inspect={Id=136197119992929;};
		Sprint={Id=79145984483423};
		Empty={Id=89330626133116;};
		Unequip={Id=81815911350146};
		Idle={Id=105622842665881};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=111641686230503; Pitch=0.8; Volume=1;};
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
		Damage=66;
		PotentialDamage=960;
		
		MagazineSize=80;
		AmmoCapacity=(80*6);
	
		Rpm=700;
		ReloadTime=3.6;
		Multishot=1;

		HeadshotMultiplier=0.05;
		EquipLoadTime=0.6;

		StandInaccuracy=3;
		FocusInaccuracyReduction=0;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=2;

		-- Recoil
		XRecoil=0.04;
		YRecoil=0.06;
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