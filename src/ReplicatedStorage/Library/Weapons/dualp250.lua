local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
	--UseViewModel=false;
	--UseAimDownViewModel=true;
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=2;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	BulletEject="PistolBullet";
	BulletEjectDelayTime=0.2;
	BulletOffset=CFrame.Angles(math.rad(-90), 0, 0);

	XRecoil=0.02;
	YRecoil=0.04;
	
	-- Weapon Properties;
	MinBaseDamage=35;
	BaseDamage=510;
	
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
	
	ToolCycleDelay=0.1;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=200;
	FireRate=(60/200);
	ReloadSpeed=3;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16250100638;};
	Focus={Id=16257808436; StopOnAction=true;};
	Load={Id=16250104467;};
	PrimaryFire={Id=16250105770;};
	Reload={Id=16250106397;};
	TacticalReload={Id=16255633591;};
	Inspect={Id=16250102790;};
	Empty={Id=16250101626;};
	Idle={Id=16678565580;};
	Unequip={Id=16838967718};
	
} or {
	Core={Id=16678559167;};
	Focus={Id=16678563632; StopOnAction=true;};
	Load={Id=16678577119;};
	PrimaryFire={Id=16678579288;};
	Reload={Id=16678582404;};
	TacticalReload={Id=16678584868;};
	Inspect={Id=16678575296;};
	Empty={Id=16678562252;};
	Idle={Id=16678565580;};
	Unequip={Id=16838967718};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=2920959; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	Reload={Id=6876277137; Pitch=0.8; Volume=0.6;};
};

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);