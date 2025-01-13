local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Automatic;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	WeaponType=WeaponsAttributes.WeaponType.SMG;
	
	EquipLoadTime=0.3;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=4.8;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.8;
	MovingInaccuracyScale=1.5;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.03;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=50;
	BaseDamage=730;
	
	AmmoLimit=32;
	MaxAmmoLimit=(32*2);

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

local Animations={ -- Main
	Core={Id=75922628646137;};
	PrimaryFire={Id=106438666757082; FocusWeight=0.1};
	Reload={Id=73499008903463;};
	TacticalReload={Id=74479906922289;};
	Load={Id=136399982879764;};
	Inspect={Id=101597938445323;};
	Sprint={Id=78827692848623};
	Empty={Id=74479906922289;};
	Unequip={Id=109110694888868};
	Idle={Id=130458311966275};
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=4814302635; Pitch=1; Volume=1;};
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