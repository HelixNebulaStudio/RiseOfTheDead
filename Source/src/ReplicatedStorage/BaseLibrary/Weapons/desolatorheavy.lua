local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.SpinUp;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
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

local Animations={
	Core={Id=133095366806990;};
	PrimaryFire={Id=99653559017440; FocusWeight=0.1};
	Reload={Id=94016212826444;};
	TacticalReload={Id=89678424382639;};
	Load={Id=135446017929473;};
	Inspect={Id=105031504368390;};
	Sprint={Id=130335336647745};
	Empty={Id=117697122462602;};
	Unequip={Id=89539360837699};
	Idle={Id=113117916370922};
};

local Audio={
	Load={Id=169799883; Pitch=0.4; Volume=0.4;};
	PrimaryFire={Id=6245184912; Pitch=1.3; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

local toolPackage = {
	ItemId="desolatorheavy";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Heavy machine gun";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;