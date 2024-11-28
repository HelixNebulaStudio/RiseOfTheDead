local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Automatic;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.SMG;
	
	EquipLoadTime=0.6;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=3;
	FocusInaccuracyReduction=0;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.04;
	YRecoil=0.06;
	
	-- Weapon Properties;
	MinBaseDamage=66;
	BaseDamage=960;
	
	AmmoLimit=32;
	MaxAmmoLimit=(32*6);
	
	DamageDropoff={
		MinDistance=48;
		MaxDistance=100;
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
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=2.3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=81052681585798;};
	PrimaryFire={Id=113445169479302; FocusWeight=0.1};
	Reload={Id=113101142371503;};
	TacticalReload={Id=94780225166213;};
	Load={Id=129324275336201;};
	Inspect={Id=133473762767233;};
	Sprint={Id=74155200790246};
	Empty={Id=94131442451868;};
	Unequip={Id=16838914873};
	Idle={Id=17557594451};

} or { -- Main
	Core={Id=81052681585798;};
	PrimaryFire={Id=113445169479302; FocusWeight=0.1};
	Reload={Id=113101142371503;};
	TacticalReload={Id=94780225166213;};
	Load={Id=129324275336201;};
	Inspect={Id=133473762767233;};
	Sprint={Id=74155200790246};
	Empty={Id=94131442451868;};
	Unequip={Id=16838914873};
	Idle={Id=17557594451};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=1926370458; Pitch=1.7; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Submachine gun";
	Tier=5;

	Welds={
		LeftToolGrip="uzi";
		RightToolGrip="uzi";
	}
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;