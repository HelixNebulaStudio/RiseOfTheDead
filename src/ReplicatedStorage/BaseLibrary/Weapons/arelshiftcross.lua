local WeaponAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponAttributes.BulletModes.Projectile;
	TriggerMode=WeaponAttributes.TriggerModes.Semi;
	ReloadMode=WeaponAttributes.ReloadModes.Full;
	
	EquipLoadTime=1.2;
	
	BaseInaccuracy=1.8;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	-- Weapon Properties;
	AmmoLimit=6;
	MaxAmmoLimit=(6*3);
	
	XRecoil=0.0;
	YRecoil=0.0;
	
	-- UI Configurations;
	UISpreadIntensity=4;

	UseScopeGui=true;
	-- Body
	RecoilStregth=math.rad(10);
	
	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=true;
	GenerateBloodEffect=true;
	GenerateTracers=false;
	GenerateMuzzle=false;
	
	-- Projectile Configurations;
	ProjectileId="boltarrow";
	
	MinBaseDamage=120;
	BaseDamage=16500;
	
	AdsTrajectory=true;
	
	--
	BaseFocusDuration=1;
	FocusDuration=1;
	FocusWalkSpeedReduction=0.55;
	ChargeDamagePercent=1;
	
	
	OnPrimaryFire = function(weaponModel, modWeaponModule)
		local arrow = weaponModel:FindFirstChild("Arrow");
		if arrow then
			arrow.Transparency = 1;
			delay(0.5, function()
				modWeaponModule.Configurations.OnAmmoUpdate(weaponModel, modWeaponModule);
			end)
		end
	end;
	
	OnAmmoUpdate = function(weaponModel, modWeaponModule)
		local properties = modWeaponModule.Properties;
		local arrow = weaponModel:FindFirstChild("Arrow");
		
		if arrow and properties.Ammo and properties.MaxAmmo then
			arrow.Transparency = (properties.MaxAmmo <= 0 and properties.Ammo <= 0) and 1 or 0;
		end
	end;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=42;
	FireRate=(60/42);
	ReloadSpeed=5.3;
};

local Animations = {
	Core={Id=96334859748247;};
	Inspect={Id=124030973914189;};
	Inspect2={Id=91609579890122;};
	Load={Id=103025219980217;};
	PrimaryFire={Id=98044167445946; FocusWeight=0.2};
	Empty={Id=109772883428993;};
	Reload={Id=115180345468515;};
	TacticalReload={Id=93263729381107;};
	Unequip={Id=89539360837699};
	Sprint={Id=124800258245100};
	LastFire={Id=100636797469944;};
	Idle={Id=83661616667273};
};

local Audio={
	Load={Id=609338076; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=13314698002; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0;};
};

local toolPackage = {
	ItemId="arelshiftcross";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Bow";
	Tier=4;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;