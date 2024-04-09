local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local reloadAnimation = {
	keyFrameConnection = nil;
};

local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.SpinUp;
	ReloadMode=Library.ReloadModes.Full;
	
	EquipLoadTime=1.5;
	
	AmmoType="heavyammo";
	
	BaseInaccuracy=18.5;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.5;
	MovingInaccuracyScale=3;
	InaccDecaySpeed=3;
	
	XRecoil=0.02;
	YRecoil=0.06;
	
	BulletRange=512;
	BulletEject="ChainHeavyBullet";
	
	SpinUpTime = 4;
	SpinDownTime = 2;
	FullSpinInaccuracyChange=-14;
	SpinAndFire = true;
	
	-- Weapon Properties;
	MinBaseDamage=30;
	BaseDamage=684;
	
	AmmoLimit=128;
	MaxAmmoLimit=(128*3);
	
	DamageDropoff={
		MinDistance=192;
		MaxDistance=256;
	};
	
	BaseHeadshotMultiplier=0.05;
	-- UI Configurations;
	UISpreadIntensity=6;
	
	-- Body
	RecoilStregth=math.rad(90);
	
	FocusWalkSpeedReduction=0.5;
	RapidFire=12;
	
	-- Animation Script;
	OnReloadAnimation=function(weaponModel, track)
		delay(2,function()
			pcall(function()
				for a=1, 9 do
					weaponModel["Bullet0"..a].Transparency = 0;
				end
			end)
		end)
	end;
	
	OnAmmoUpdate = function(weaponModel, modWeaponModule, ammo)
		local properties = modWeaponModule.Properties;
		
		if ammo and ammo <= 10 then
			pcall(function()
				for a=1, 9 do
					weaponModel["Bullet0"..a].Transparency = (ammo >= 10-a) and 0 or 1;
				end
			end)
		end
	end;

	Penetration=WeaponProperties.PenetrationTable["Heavy machine gun"];
}
Configurations.OnPrimaryFire = Configurations.OnAmmoUpdate;

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=400;
	FireRate=(60/400);
	ReloadSpeed=5;
}

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16535430894;};
	PrimaryFire={Id=16535436701; FocusWeight=0.1};
	Reload={Id=16535438330;};
	TacticalReload={Id=16535441920;};
	Load={Id=16535435344;};
	Inspect={Id=16535433771;};
	Sprint={Id=16535440088};
	Empty={Id=16535432151;};
	Unequip={Id=16840085976};
	
} or { -- Main
	Core={Id=16535430894;};
	PrimaryFire={Id=16535436701; FocusWeight=0.1};
	Reload={Id=16535438330;};
	TacticalReload={Id=16535441920;};
	Load={Id=16535435344;};
	Inspect={Id=16535433771;};
	Sprint={Id=16535440088};
	Empty={Id=16535432151;};
	Unequip={Id=16840085976};
	
};


local Audio={
	Load={Id=169799883; Pitch=0.4; Volume=0.4;};
	PrimaryFire={Id=6245184912; Pitch=1.3; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	--Reload={Id=6286536754; Pitch=1; Volume=0.6;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);