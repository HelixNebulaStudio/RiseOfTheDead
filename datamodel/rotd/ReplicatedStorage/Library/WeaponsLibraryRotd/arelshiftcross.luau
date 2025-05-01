local modWeaponAttributes = require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
--==
local toolPackage = {
	ItemId=script.Name;
	Class="Gun";
	HandlerType="GunTool";
	WeaponClass="Bow";
	Tier=4;

	Animations={
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

	Audio={
		Load={Id=609338076; Pitch=1.2; Volume=0.4;};
		PrimaryFire={Id=13314698002; Pitch=1; Volume=1;};
		Empty={Id=154255000; Pitch=1; Volume=0;};
	};

	Configurations={
		-- Mechanics
		BulletMode=modWeaponAttributes.BulletModes.Projectile;
		TriggerMode=modWeaponAttributes.TriggerModes.Semi;
		ReloadMode=modWeaponAttributes.ReloadModes.Full;
		
		-- Stats
		Damage=120;
		PotentialDamage=16500;
		
		MagazineSize=6;
		AmmoCapacity=(6*3);
	
		Rpm=42;
		ReloadTime=5.3;
		Multishot=1;

		HeadshotMultiplier=0.5;
		EquipLoadTime=1.2;

		StandInaccuracy=1.8;
		FocusInaccuracyReduction=0.5;
		CrouchInaccuracyReduction=0.6;
		MovingInaccuracyScale=1.3;

		-- Focus
		FocusDuration=1;
		FocusWalkSpeedReduction=0.55;
		ChargeDamagePercent=1;

		-- Projectile
		ProjectileId="boltarrow";

		-- Recoil
		XRecoil=0.0;
		YRecoil=0.0;
		-- Dropoff
		DamageDropoff={
			MinDistance=100;
			MaxDistance=200;
		};
		-- UI
		UISpreadIntensity=4;
		UseScopeGui=true;
		-- Body
		RecoilStregth=math.rad(10);
		-- Physics
		KillImpulseForce=5;
		-- Effects
		GeneratesBulletHoles=true;
		GenerateBloodEffect=true;
		GenerateTracers=false;
		GenerateMuzzle=false;
	};

	Properties={};
};

function toolPackage.OnPrimaryFire(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local arrow = weaponModel:FindFirstChild("Arrow");
	if arrow then
		arrow.Transparency = 1;
		delay(0.5, function()
			toolPackage.OnAmmoUpdate(handler);
		end)
	end
end

function toolPackage.OnAmmoUpdate(handler: ToolHandlerInstance)
	local weaponModel = handler.Prefabs[1];
	local equipmentClass = handler.EquipmentClass;

	local properties = equipmentClass.Properties;
	local arrow = weaponModel:FindFirstChild("Arrow");
	
	if arrow and properties.Ammo and properties.MaxAmmo then
		arrow.Transparency = (properties.MaxAmmo <= 0 and properties.Ammo <= 0) and 1 or 0;
	end
end

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;