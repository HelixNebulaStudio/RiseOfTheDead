local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	WeaponType=Library.WeaponType.Sniper;
	
	EquipLoadTime=1.5;
	
	AmmoType="sniperammo";
	
	BaseInaccuracy=2.2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=8;
	
	BulletRange=512;
	BulletEject="SniperBullet";
	BulletEjectDelayTime=0.2;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.1;
	YRecoil=0.6;
	
	-- Weapon Properties;
	MinBaseDamage=580;
	BaseDamage=24600;
	
	AmmoLimit=6;
	MaxAmmoLimit=(6*3);
	
	DamageDropoff={
		MinDistance=256;
	};
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Gimmick
	BulletRicochet="Modifier";
	BulletRicochetCount=1;
	BulletRicochetDistance=64;

	-- Body
	RecoilStregth=math.rad(90);

	UseScopeGui=true;
	
	-- Sniper
	BaseFocusDuration=3;
	FocusDuration=3;
	FocusWalkSpeedReduction=0.65;
	ChargeDamagePercent=0.2;
	
	Penetration=WeaponProperties.PenetrationTable.Sniper;
	KillImpulseForce=40;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=80;
	FireRate=(60/80);
	ReloadSpeed=2.8;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=115169929209429;};
	PrimaryFire={Id=76053596239338; FocusWeight=1};
	EmptyFire={Id=112741517737403;};
	Reload={Id=102798161524897;};
	TacticalReload={Id=72036017995391;};
	Load={Id=71050516325359;};
	Inspect={Id=88446957745555;};
	Sprint={Id=97978711950632};
	Empty={Id=133859969327903;};
	Unequip={Id=16838937257};
	Idle={Id=17557632470};
	
} or { -- Main
	Core={Id=115169929209429;};
	PrimaryFire={Id=76053596239338; FocusWeight=1};
	EmptyFire={Id=112741517737403;};
	Reload={Id=102798161524897;};
	TacticalReload={Id=72036017995391;};
	Load={Id=71050516325359;};
	Inspect={Id=88446957745555;};
	Sprint={Id=97978711950632};
	Empty={Id=133859969327903;};
	Unequip={Id=16838937257};
	Idle={Id=17557632470};
	
};
	
local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=6548742606; Pitch=1.2; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	--Reload={Id=142491708; Pitch=1.1; Volume=0.6;};
}

local toolPackage = {
	ItemId=script.Name;
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Sniper";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;