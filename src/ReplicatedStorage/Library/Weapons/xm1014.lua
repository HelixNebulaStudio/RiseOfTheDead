local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Single;
	WeaponType=Library.WeaponType.Shotgun;
	
	EquipLoadTime=0.55;
	
	AmmoType="shotgunammo";
	
	BaseInaccuracy=4;
	FocusInaccuracyReduction=0.6;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=2;
	
	BulletRange=512;
	BulletEject="ShotgunBullet";
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.08;
	YRecoil=0.4;
	
	-- Weapon Properties;
	MinBaseDamage=30;
	BaseDamage=312;
	
	AmmoLimit=12;
	MaxAmmoLimit=(12*4);
	
	PenatrationStrength=1; -- In studs.
	PenatrationDamageReduction=0.5; -- Damage * PenatrationDamageReduction;
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=160;
	};
	
	BaseHeadshotMultiplier=0.02;
	-- UI Configurations;
	UISpreadIntensity=5;
	
	-- Body
	RecoilStregth=math.rad(120);
	
	BasePiercing=1;
	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Shotgun;
	KillImpulseForce=20;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=171.43;
	FireRate=(60/171.43);
	ReloadSpeed=0.5;
	BaseMultishot={Min=3, Max=4};
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16285889196;};
	PrimaryFire={Id=16285896879;};
	Reload={Id=16285898275;};
	Load={Id=16285895695;};
	Inspect={Id=16285894172;};
	Sprint={Id=16286219940};
	Empty={Id=16285891865;};
	Unequip={Id=16838937257};
	Idle={Id=16883924242};

} or { -- Main
	Core={Id=16678447028;};
	PrimaryFire={Id=16678454837;};
	Reload={Id=16678456896;};
	Load={Id=16678452896;};
	Inspect={Id=16678451088;};
	Sprint={Id=16678458287};
	Empty={Id=16678447028;};
	Unequip={Id=16838937257};
	Idle={Id=16883924242};
	
};

local Audio={
	Load={Id=169799883; Pitch=1; Volume=0.4;};
	PrimaryFire={Id=2697294; Pitch=1; Volume=0.5;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=5677987779; Pitch=1.1; Volume=0.6;}; --2697295
}

local toolPackage = {
	ItemId="xm1014";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Shotgun";
	Tier=1;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;