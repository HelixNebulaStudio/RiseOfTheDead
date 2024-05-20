local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=65;
	BaseDamage=950;
	
	AmmoLimit=15;
	MaxAmmoLimit=(15*4);
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=1.5;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=300;
	FireRate=(60/300);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16790808976;};
	Load={Id=16790813904;};
	PrimaryFire={Id=16790815706;};
	Reload={Id=16790817385;};
	Inspect={Id=16790812228;};
	Empty={Id=16790810563;};
	Unequip={Id=7142108329};
	TacticalReload={Id=16790818790;};
	Idle={Id=17557221759;};
	
} or {
	Core={Id=16790808976;};
	Load={Id=16790813904;};
	PrimaryFire={Id=16790815706;};
	Reload={Id=16790817385;};
	Inspect={Id=16790812228;};
	Empty={Id=16790810563;};
	Unequip={Id=7142108329};
	TacticalReload={Id=16790818790;};
	Idle={Id=17557221759;};
	
};


local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=2757012511; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};


Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);