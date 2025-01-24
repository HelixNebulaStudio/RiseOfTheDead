local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Submachine gun";
	Tier=2;

	Animations={
		Core={Id=75922628646137;};
		PrimaryFire={Id=106438666757082; FocusWeight=0.1};
		Reload={Id=73499008903463;};
		TacticalReload={Id=105982030297456;};
		Load={Id=136399982879764;};
		Inspect={Id=101597938445323;};
		Sprint={Id=78827692848623};
		Empty={Id=74479906922289;};
		Unequip={Id=109110694888868};
		Idle={Id=130458311966275};
	};

	Audio={
		Load={Id=169799883; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=4814302635; Pitch=1; Volume=1;};
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
		Damage=50;
		PotentialDamage=730;
		DamageRev=0.35;
		
		MagazineSize=32;
		AmmoCapacity=(32*2);
	
		Rpm=520;
		ReloadTime=2;
		Multishot=1;

		HeadshotMultiplier=0.05;
		EquipLoadTime=0.3;

		StandInaccuracy=4.8;
		FocusInaccuracyReduction=0;
		CrouchInaccuracyReduction=0.8;
		MovingInaccuracyScale=1.5;

		-- Recoil
		XRecoil=0.03;
		YRecoil=0.04;
		-- Dropoff
		DamageDropoff={
			MinDistance=53;
			MaxDistance=128;
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
	return modEquipmentClass.new(toolPackage.Class, toolPackage.Configurations, toolPackage.Properties);
end

return toolPackage;
