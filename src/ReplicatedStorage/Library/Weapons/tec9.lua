local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2.6;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.6;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.15;
	
	-- Weapon Properties;
	MinBaseDamage=25;
	BaseDamage=365;
	
	AmmoLimit=24;
	MaxAmmoLimit=(24*4);
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.5;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
}

local Properties={
	Rpm=500;
	FireRate=(60/500);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16196221640;};
	Load={Id=16196226440;};
	PrimaryFire={Id=16196229474;};
	Reload={Id=16196231987;};
	TacticalReload={Id=16255679323;};
	Inspect={Id=16196224947;};
	Empty={Id=16196223820;};
	Sprint={Id=9851976016};
	Idle={Id=17557280528;};
	Unequip={Id=7142108329};
	
} or {
	Core={Id=16678327280;};
	Load={Id=16678330068;};
	PrimaryFire={Id=16678332878;};
	Reload={Id=16678335113;};
	TacticalReload={Id=16678337123;};
	Inspect={Id=16678339289;};
	Empty={Id=16678341403;};
	Sprint={Id=16678346842};
	Idle={Id=17557280528;};
	Unequip={Id=7142108329};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.1; Volume=0.4;};
	PrimaryFire={Id=273605833; Pitch=1.5; Volume=0.6;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);