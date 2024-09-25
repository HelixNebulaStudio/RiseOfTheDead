local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Rifle;
	
	EquipLoadTime=0.75;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=2.6;
	FocusInaccuracyReduction=0.7;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	InaccDecaySpeed=1.6;
	
	BulletRange=512;
	BulletEject="RifleBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);
	
	XRecoil=0.02;
	YRecoil=0.055;
	
	-- Weapon Properties;
	MinBaseDamage=36;
	BaseDamage=735;
	
	AmmoLimit=35;
	MaxAmmoLimit=(35*5);
	
	DamageDropoff={
		MinDistance=200;
		MaxDistance=400;
	};
	
	BaseHeadshotMultiplier=0.1;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(110);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Rifle;
	KillImpulseForce=10;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=3.5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16472203176;};
	PrimaryFire={Id=16472207986; FocusWeight=0.1};
	Reload={Id=16472209813;};
	Load={Id=16472206775;};
	Inspect={Id=16472205783;};
	Sprint={Id=16472211804};
	Empty={Id=16472204328;};
	Unequip={Id=16840085976};
	Idle={Id=16883931721};

} or { -- Main
	Core={Id=16678223386;};
	PrimaryFire={Id=16678232108; FocusWeight=0.1};
	Reload={Id=16678234929;};
	Load={Id=16678230045;};
	Inspect={Id=16678228009;};
	Sprint={Id=16678237271};
	Empty={Id=16678225342;};
	Unequip={Id=16840085976};
	Idle={Id=16883924242};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926397389; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="ak47";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Rifle";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;