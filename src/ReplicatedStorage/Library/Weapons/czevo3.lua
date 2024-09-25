local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.SMG;
	
	EquipLoadTime=0.3;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=4.8;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=1.5;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.03;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=50;
	BaseDamage=730;
	
	AmmoLimit=32;
	MaxAmmoLimit=(32*2); -- 3 to 2

	DamageRev=0.35;
	
	DamageDropoff={
		MinDistance=53;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.05;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(80);
	
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable["Submachine gun"];
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=520;
	FireRate=(60/520);
	ReloadSpeed=2;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16350801744;};
	PrimaryFire={Id=16350807382; FocusWeight=0.1};
	Reload={Id=16350808884;};
	TacticalReload={Id=16350811975;};
	Load={Id=16350806271;};
	Inspect={Id=16350804129;};
	Sprint={Id=16350810554};
	Empty={Id=16350803014;};
	Unequip={Id=16838914873};
	Idle={Id=17557532685};
	
} or { -- Main
	Core={Id=16678116294;};
	PrimaryFire={Id=16678118045; FocusWeight=0.1};
	Reload={Id=16678121142;};
	TacticalReload={Id=16678124338;};
	Load={Id=16678126392;};
	Inspect={Id=16678128826;};
	Sprint={Id=16678130494};
	Empty={Id=16678133050;};
	Unequip={Id=16838914873};
	Idle={Id=17557532685};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=4814302635; Pitch=1; Volume=1;};--160217037
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
};

local toolPackage = {
	ItemId="czevo3";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Submachine gun";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;