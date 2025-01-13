local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Projectile;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Single;
	
	EquipLoadTime=1.2;
	
	BaseInaccuracy=1.8;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	BulletRange=512;
	-- Weapon Properties;
	AmmoLimit=1;
	MaxAmmoLimit=16;
	
	XRecoil=0.0;
	YRecoil=0.0;
	
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(0);

	-- Decorations;
	ShakeCamera=false;
	GeneratesBulletHoles=true;
	GenerateBloodEffect=true;
	GenerateTracers=false;
	GenerateMuzzle=false;
	
	-- Projectile Configurations;
	ProjectileId="arrow";
	
	MinBaseDamage=200;
	BaseDamage=22200;--24200
	
	
	AdsTrajectory=true;
	
	--
	CanUnfocusFire = false;
	BaseFocusDuration=4;
	FocusDuration=4;
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
	
	CustomDpsCal = function(self)
		local dmg = self.Configurations.Damage;
		local focusTime = self.Configurations.FocusDuration;
		local reloadspeed = self.Properties.ReloadSpeed;
		
		return dmg/focusTime;--math.max(focusTime, reloadspeed);
	end;
	CustomDpmCal = function(self)
		return;
	end;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=600;
	FireRate=(60/600);
	ReloadSpeed=1;
}

local Animations={
	Core={Id=127808836086435;};
	Focus={Id=134079769374499};
	FocusCore={Id=104372864839162};
	Inspect={Id=80659276731368;};
	PrimaryFire={Id=84589890111948;};
	Reload={Id=127642469817413;};
	Load={Id=111069679794807;};
};

local Audio={
	Load={Id=609338076; Pitch=1.2; Volume=0.4;};
	PrimaryFire={Id=609348009; Pitch=1; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0;};
	Reload={Id=609338076; Pitch=1.1; Volume=0.6;};
	--ProjectileBounce={Id=5082995723; Pitch=1; Volume=1;};
};

local toolPackage = {
	ItemId="tacticalbow";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Bow";
	Tier=3;
	
	Welds={
		LeftToolGrip="tacticalbow";
	}
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;