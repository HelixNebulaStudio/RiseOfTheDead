local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectDelayTime=0.2;
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=35;
	BaseDamage=600;
	
	AmmoLimit=30;
	MaxAmmoLimit=(30*3);
	
	DamageDropoff={
		MinDistance=100;
		MaxDistance=200;
	};
	
	BaseHeadshotMultiplier=0.5;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	WaistRotation=0;
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
	
	TriggerCycleDelay=0.1;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=200;
	FireRate=(60/200);
	ReloadSpeed=3;
}

local Animations={
	Core={Id=94657217084382;};
	Focus={Id=94657217084382; StopOnAction=true;};
	Load={Id=96980470567747;};
	PrimaryFire={Id=138523169091547;};
	Reload={Id=131674293143074;};
	TacticalReload={Id=139502247497213;};
	Inspect={Id=85691639179257;};
	Empty={Id=95287193416992;};
	Idle={Id=105318026176191;};
	Unequip={Id=81815911350146};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=2920959; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=6876277137; Pitch=0.8; Volume=0.6;};
};

local toolPackage = {
	ItemId="dualp250";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Pistol";
	Tier=2;
	
	Welds={
		LeftToolGrip="p250";
		RightToolGrip="p250";
	}
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;