local Library = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local WeaponProperties = require(game.ReplicatedStorage.Library.WeaponProperties);

local speedloaderPrefab = script:WaitForChild("Speedloader");
local speedloaderWeld = script:WaitForChild("SpeedloaderGrip");
local Configurations={
	-- Weapon Mechanics;
	BulletMode=Library.BulletModes.Hitscan;
	TriggerMode=Library.TriggerModes.Semi;
	ReloadMode=Library.ReloadModes.Full;
	
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

local Animations=workspace:GetAttribute("IsDev") and {
	Core={Id=16269409429;};
	PrimaryFire={Id=16269422738;};
	Reload={Id=16633246993;};
	Load={Id=16269420459;};
	Inspect={Id=16269418159;};
	Sprint={Id=16184602077};
	Unequip={Id=16838903122};
	Empty={Id=16269413322;};
	Idle={Id=17557221759;};
	
} or {
	Core={Id=16633243999;};
	PrimaryFire={Id=16633245957;};
	Reload={Id=16633246993;};
	Load={Id=16633244902;};
	Inspect={Id=16633248424;};
	Sprint={Id=16184602077};
	Unequip={Id=16838903122};
	Empty={Id=16633249792;};
	Idle={Id=17557221759;};
	
};

local Audio={
	Load={Id=169799883; Pitch=1.5; Volume=0.4;};
	PrimaryFire={Id=1943677171; Pitch=0.6; Volume=1;};
	Empty={Id=154255000; Pitch=1; Volume=0.5;};
}

Configurations.ItemId = script.Name;
return WeaponProperties.new(Configurations, Properties, Animations, Audio);