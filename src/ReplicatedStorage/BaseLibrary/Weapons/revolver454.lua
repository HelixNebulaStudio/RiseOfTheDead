local WeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local speedloaderPrefab = script:WaitForChild("Speedloader");
local speedloaderWeld = script:WaitForChild("SpeedloaderGrip");

local Configurations={
	-- Weapon Mechanics;
	BulletMode=WeaponsAttributes.BulletModes.Hitscan;
	TriggerMode=WeaponsAttributes.TriggerModes.Semi;
	ReloadMode=WeaponsAttributes.ReloadModes.Full;
	
	EquipLoadTime=0.5;
	
	AmmoType="lightammo";
	
	BaseInaccuracy=1.5;
	FocusInaccuracyReduction=0.5;
	CrouchInaccuracyReduction=0.6;
	MovingInaccuracyScale=1.3;
	
	XRecoil=0.1;
	YRecoil=0.3;
	
	BulletRange=512;

	MinBaseDamage=260;
	BaseDamage=3790;
	
	-- Weapon Properties;
	AmmoLimit=8;
	MaxAmmoLimit=(8*3);
	
	DamageDropoff={
		MinDistance=86;
		MaxDistance=128;
	};
	
	BaseHeadshotMultiplier=0.25;
	-- UI Configurations;
	UISpreadIntensity=4;
	
	-- Body
	RecoilStregth=math.rad(90);

	-- Penetration
	Penetration=WeaponProperties.PenetrationTable.Pistol;
	
	OnReloadAnimation=function(weaponModel, track)
		coroutine.wrap(function()
			local newPrefab = speedloaderPrefab:Clone();
			local newWeld = speedloaderWeld:Clone();
			game.Debris:AddItem(newPrefab, 5);
			game.Debris:AddItem(newWeld, 5);
			
			local modelBase = newPrefab:WaitForChild("Speedloader");
			newPrefab.Parent = weaponModel;
			newWeld.Parent = weaponModel.Parent:FindFirstChild("LeftHand");
			newWeld.Part0 = newWeld.Parent;
			newWeld.Part1 = modelBase;

			track.Stopped:Wait();
			game.Debris:AddItem(newPrefab, 0);
			game.Debris:AddItem(newWeld, 0);
		end)()
	end;
}

local Properties={
	Ammo=Configurations.AmmoLimit;
	MaxAmmo=Configurations.MaxAmmoLimit;
	Rpm=120;
	FireRate=(60/120);
	ReloadSpeed=4;
}

local Animations={
	Core={Id=130377150412002;};
	PrimaryFire={Id=98445409896960;};
	Reload={Id=86722699279539;};
	Load={Id=74292147267545;};
	Inspect={Id=95521544205002;};
	Sprint={Id=97133829660717};
	Unequip={Id=127466609333739};
	Empty={Id=135109263431097;};
	Idle={Id=136813651254431;};
};

local Audio={
	Load={Id=169799883; Pitch=1.5; Volume=0.4;};
	PrimaryFire={Id=1943677171; Pitch=0.6; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
	RevolverEjectBullets={Id="RevolverEjectBullets"; Preload=true;};
	RevolverBulletInsert={Id="RevolverBulletInsert"; Preload=true;};
	RevolverCloseChamber={Id="RevolverCloseChamber"; Preload=true;};
	RevolverSpinChamber={Id="RevolverSpinChamber"; Preload=true;};
}

local toolPackage = {
	ItemId="revolver454";
	Type="GunTool";
	Animations=Animations;
	Audio=Audio;

	WeaponClass="Pistol";
	Tier=2;
};

function toolPackage.NewToolLib(handler)
	local weaponModule = WeaponProperties.new(Configurations, Properties, Animations, Audio);
	return weaponModule;
end

return toolPackage;